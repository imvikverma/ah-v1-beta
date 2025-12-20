# engines/backtesting/Backtesting.py
import backtrader as bt
import pandas as pd
import numpy as np
from datetime import datetime

class AurumHarmonyStrategy(bt.Strategy):
    params = (
        ('vix', 18.0),
        ('initial_capital', 10000),
    )

    def __init__(self):
        self.rsi = bt.indicators.RSI_SMA(self.data.close, period=14)
        self.atr = bt.indicators.ATR(self.data, period=14)

    def next(self):
        capital = self.broker.getvalue()
        if capital < self.p.initial_capital * 0.5:  # safety stop
            return

        if not self.position:
            if self.rsi < 30:
                size = (capital * 0.95) / self.data.close[0]
                self.buy(size=size)
            elif self.rsi > 70:
                size = (capital * 0.95) / self.data.close[0]
                self.sell(size=size)
        else:
            if self.position.size > 0 and self.rsi > 70:
                self.close()
            if self.position.size < 0 and self.rsi < 30:
                self.close()

def run_backtest(data_path: str = "nifty50_15min.csv"):
    cerebro = bt.Cerebro()
    cerebro.addstrategy(AurumHarmonyStrategy, initial_capital=10000)

    data = bt.feeds.PandasData(dataname=pd.read_csv(data_path, parse_dates=True, index_col=0))
    cerebro.adddata(data)
    cerebro.broker.setcash(10000)
    cerebro.broker.setcommission(commission=0.001)

    print(f"Starting Portfolio Value: ₹{cerebro.broker.getvalue():,.2f}")
    cerebro.run()
    print(f"Final Portfolio Value: ₹{cerebro.broker.getvalue():,.2f}")

if __name__ == "__main__":
    run_backtest()