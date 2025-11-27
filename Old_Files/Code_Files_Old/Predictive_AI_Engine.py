import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

class PredictiveAI:
    def __init__(self):
        self.model = RandomForestClassifier(n_estimators=100)

    def train(self, data):
        X = data[['rsi', 'atr', 'volume', 'vix']]
        y = data['direction']
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
        self.model.fit(X_train, y_train)
        return self.model.score(X_test, y_test)

    def predict(self, features):
        return self.model.predict([features])[0]

# Example usage
data = pd.DataFrame({'rsi': [70, 30, 50], 'atr': [10, 15, 12], 'volume': [1000, 1500, 1200], 'vix': [14, 25, 18], 'direction': ['bullish', 'bearish', 'neutral']})
ai = PredictiveAI()
accuracy = ai.train(data)
print(f"Accuracy: {accuracy}")
print(f"Prediction for RSI=75, ATR=10, Volume=1100, VIX=15: {ai.predict([75, 10, 1100, 15])}")