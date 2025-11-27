import backtrader as bt

class BacktestStrategy(bt.Strategy):
    def __init__(self):
        self.rsi = bt.indicators.RSI()

    def next(self):
        if self.rsi > 70:
            self.buy()
        elif self.rsi < 30:
            self.sell()

cerebro = bt.Cerebro()
cerebro.addstrategy(BacktestStrategy)
data = bt.feeds.PandasData(dataname=pd.DataFrame({'close': [100, 105, 98, 102]}))
cerebro.adddata(data)
cerebro.run()
print(cerebro.broker.getvalue())