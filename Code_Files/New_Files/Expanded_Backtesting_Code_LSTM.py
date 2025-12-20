import pandas as pd
import backtrader as bt
import yfinance as yf
import requests
from datetime import datetime, timedelta
from backtrader.analyzers import SharpeRatio, DrawDown, TradeAnalyzer
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
from sklearn.preprocessing import MinMaxScaler
import numpy as np

# Step 1: Fetch Data Functions (Unchanged, for completeness)
def fetch_nse_bse_data(symbol='^NSEI', start_date, end_date): 
    data = yf.download(symbol, start=start_date, end=end_date, interval="5m") 
    data.to_csv('nse_data.csv')
    return data

def fetch_hdfc_sky_data(api_key, symbol='NIFTY', start_date, end_date, interval='5min', option_contract=None):
    url = "https://api.hdfcsec.com/historical"  
    headers = {"Authorization": f"Bearer {api_key}"}
    params = {
        "symbol": symbol if not option_contract else option_contract,
        "from_date": start_date,
        "to_date": end_date,
        "interval": interval
    }
    try:
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        data = pd.DataFrame(response.json()['data'])  
        data['datetime'] = pd.to_datetime(data['datetime'])
        data.set_index('datetime', inplace=True)
        data.to_csv('hdfc_data.csv')
        return data[['open', 'high', 'low', 'close', 'volume']]
    except requests.exceptions.RequestException as e:
        print(f"HDFC Sky API error: {e}")
        return pd.DataFrame()

def fetch_kotak_neo_data(api_key, symbol='NIFTY', start_date, end_date, interval='5min', option_contract=None):
    url = "https://api.kotaksecurities.com/historical-data"  
    headers = {"Authorization": f"Bearer {api_key}"}
    params = {
        "exchange": "NSE",
        "symbol": symbol if not option_contract else option_contract,
        "start_date": start_date,
        "end_date": end_date,
        "timeframe": interval
    }
    try:
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        data = pd.DataFrame(response.json()['data'])
        data['datetime'] = pd.to_datetime(data['datetime'])
        data.set_index('datetime', inplace=True)
        data.to_csv('kotak_data.csv')
        return data[['open', 'high', 'low', 'close', 'volume']]
    except requests.exceptions.RequestException as e:
        print(f"Kotak Neo API error: {e}")
        return pd.DataFrame()

# Step 2: LSTM Volatility Model (New Addition - Predicts Next Volatility Using Historical Closes)
class VolatilityDataset(Dataset):
    def __init__(self, data, seq_len=20):
        self.scaler = MinMaxScaler()
        scaled_data = self.scaler.fit_transform(data.values.reshape(-1, 1))
        self.X, self.y = [], []
        for i in range(len(scaled_data) - seq_len - 1):
            self.X.append(scaled_data[i:i+seq_len])
            self.y.append(scaled_data[i+seq_len])  # Predict next value (e.g., volatility proxy)
        self.X = torch.tensor(np.array(self.X), dtype=torch.float32)
        self.y = torch.tensor(np.array(self.y), dtype=torch.float32)

    def __len__(self):
        return len(self.X)

    def __getitem__(self, idx):
        return self.X[idx], self.y[idx]

class LSTMVolatility(nn.Module):
    def __init__(self, input_size=1, hidden_size=50, num_layers=1):
        super(LSTMVolatility, self).__init__()
        self.lstm = nn.LSTM(input_size, hidden_size, num_layers, batch_first=True)
        self.fc = nn.Linear(hidden_size, 1)

    def forward(self, x):
        h0 = torch.zeros(1, x.size(0), 50)  # Num layers, batch, hidden
        c0 = torch.zeros(1, x.size(0), 50)
        out, _ = self.lstm(x, (h0, c0))
        out = self.fc(out[:, -1, :])  # Last time step
        return out

def train_lstm_volatility(data, seq_len=20, epochs=50):
    # Use close prices as volatility proxy (or compute std/ATR first)
    close_prices = data['close']
    dataset = VolatilityDataset(close_prices, seq_len)
    loader = DataLoader(dataset, batch_size=32, shuffle=True)
    
    model = LSTMVolatility()
    criterion = nn.MSELoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=0.001)
    
    for epoch in range(epochs):
        for X_batch, y_batch in loader:
            optimizer.zero_grad()
            output = model(X_batch)
            loss = criterion(output, y_batch)
            loss.backward()
            optimizer.step()
        print(f"Epoch {epoch+1}/{epochs}, Loss: {loss.item()}")
    
    return model, dataset.scaler

def predict_volatility(model, scaler, last_seq):
    # Predict next volatility from last sequence (shape: (1, seq_len, 1))
    last_seq_scaled = scaler.transform(last_seq.reshape(-1, 1)).reshape(1, -1, 1)
    with torch.no_grad():
        pred = model(torch.tensor(last_seq_scaled, dtype=torch.float32))
    return scaler.inverse_transform(pred.numpy())[0][0]

# Step 3: AurumStrategy with ML Volatility Integration (Expanded)
class AurumStrategy(bt.Strategy):
    params = (
        ('short_period', 20), ('long_period', 50), ('atr_period', 14), ('atr_multiplier', 2.0),
        ('risk_per_trade', 0.01), ('vol_threshold', 1.5),  # Volatility filter (skip if predicted vol > threshold * avg)
        ('lstm_seq_len', 20)  # For LSTM input
    )

    def __init__(self):
        self.sma_short = bt.indicators.SMA(period=self.p.short_period)
        self.sma_long = bt.indicators.SMA(period=self.p.long_period)
        self.atr = bt.indicators.ATR(period=self.p.atr_period)
        self.order = None
        self.lstm_model, self.scaler = train_lstm_volatility(self.data.close.get(size=200))  # Train on first 200 bars
        self.vol_history = []  # To store recent closes for prediction

    def next(self):
        if self.order:
            return

        # Update volatility history (last seq_len closes)
        self.vol_history.append(self.data.close[0])
        if len(self.vol_history) > self.p.lstm_seq_len:
            self.vol_history.pop(0)
        
        if len(self.vol_history) == self.p.lstm_seq_len:
            predicted_vol = predict_volatility(self.lstm_model, self.scaler, np.array(self.vol_history))
            avg_vol = np.mean(self.vol_history)  # Simple avg as baseline
            if predicted_vol > self.p.vol_threshold * avg_vol:
                return  # Skip trade if high predicted volatility
        
        position_size = self.broker.getvalue() * self.p.risk_per_trade / (self.atr[0] * self.p.atr_multiplier)

        if self.sma_short > self.sma_long and not self.position and self.data.close[0] > self.sma_long[0] * 1.01:  
            self.order = self.buy(size=position_size)
            self.stop_price = self.data.close[0] - self.atr[0] * self.p.atr_multiplier
        elif self.sma_short < self.sma_long and self.position:
            self.order = self.sell(size=position_size)
            self.stop_price = self.data.close[0] + self.atr[0] * self.p.atr_multiplier

    def notify_order(self, order):
        if order.status in [order.Completed]:
            self.order = None
        elif order.status in [order.Canceled, order.Margin, order.Rejected]:
            self.order = None

# Step 4: Run Backtest Function (Unchanged, for completeness)
def run_backtest(data_source, start_date, end_date):
    cerebro = bt.Cerebro()
    data = bt.feeds.PandasData(dataname=data_source)
    cerebro.adddata(data)
    cerebro.addstrategy(AurumStrategy)
    cerebro.broker.setcash(500000)
    cerebro.addsizer(bt.sizers.PercentSizer, percents=30)
    cerebro.addanalyzer(SharpeRatio, _name='sharpe')
    cerebro.addanalyzer(DrawDown, _name='drawdown')
    cerebro.addanalyzer(TradeAnalyzer, _name='trades')
    thestrats = cerebro.run()
    strat = thestrats[0]

    sharpe = strat.analyzers.sharpe.get_analysis()['sharperatio'] if 'sharperatio' in strat.analyzers.sharpe.get_analysis() else None
    drawdown = strat.analyzers.drawdown.get_analysis()['max']['drawdown']
    trades = strat.analyzers.trades.get_analysis()
    total_trades = trades['total']['total']
    win_rate = (trades['won']['total'] / total_trades * 100) if total_trades > 0 else 0

    print(f"Sharpe Ratio: {sharpe}")
    print(f"Max Drawdown: {drawdown}%")
    print(f"Win Rate: {win_rate}%")
    print(f"Total Trades: {total_trades}")
    print(f"Final Portfolio Value: {cerebro.broker.getvalue()}")

    cerebro.plot(style='candlestick')

# Example Usage
start_date = (datetime.now() - timedelta(days=90)).strftime('%Y-%m-%d')
end_date = datetime.now().strftime('%Y-%m-%d')

# NSE/BSE Test
nse_data = fetch_nse_bse_data('^NSEI', start_date, end_date)
run_backtest(nse_data, start_date, end_date)

# HDFC Sky Test (uncomment)
# hdfc_data = fetch_hdfc_sky_data('your_hdfc_api_key', 'NIFTY', start_date, end_date)
# run_backtest(hdfc_data, start_date, end_date)

# Kotak Neo Test (uncomment)
# kotak_data = fetch_kotak_neo_data('your_kotak_api_key', 'NIFTY', start_date, end_date)
# run_backtest(kotak_data, start_date, end_date)