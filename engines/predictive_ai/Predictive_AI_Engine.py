# engines/predictive_ai/Predictive_AI_Engine.py
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense
import time
from typing import List


class PredictiveAIEngine:
    def __init__(self, hyperledger_client=None):
        self.rf_model = RandomForestClassifier(n_estimators=200, random_state=42)
        self.lstm_model = None
        self.hyperledger_client = hyperledger_client
        self.confidence_threshold = 0.70

    def train_rf(self, data: pd.DataFrame) -> float:
        X = data[["rsi", "atr", "vix", "oi_change", "volume_spike"]]
        y = data["direction"]
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )
        self.rf_model.fit(X_train, y_train)
        accuracy = self.rf_model.score(X_test, y_test)
        if self.hyperledger_client:
            self.hyperledger_client.log_training(
                {"model": "RF", "accuracy": accuracy, "timestamp": int(time.time())}
            )
        return accuracy

    def train_lstm(self, sequences: np.ndarray, labels: np.ndarray):
        self.lstm_model = Sequential(
            [
                LSTM(
                    100,
                    return_sequences=True,
                    input_shape=(sequences.shape[1], sequences.shape[2]),
                ),
                LSTM(50),
                Dense(3, activation="softmax"),
            ]
        )
        self.lstm_model.compile(
            optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"]
        )
        history = self.lstm_model.fit(
            sequences, labels, epochs=20, validation_split=0.2, verbose=0
        )
        accuracy = max(history.history["val_accuracy"])
        if self.hyperledger_client:
            self.hyperledger_client.log_training(
                {"model": "LSTM", "accuracy": accuracy, "timestamp": int(time.time())}
            )
        return accuracy

    def predict(self, features: dict) -> dict:
        rf_pred = self.rf_model.predict_proba([list(features.values())])[0]
        rf_confidence = max(rf_pred)
        direction = ["bearish", "neutral", "bullish"][np.argmax(rf_pred)]

        if rf_confidence < self.confidence_threshold:
            direction = "neutral"  # Force neutral if confidence low

        result = {
            "direction": direction,
            "confidence": round(rf_confidence, 4),
            "timestamp": int(time.time()),
        }
        if self.hyperledger_client:
            self.hyperledger_client.log_prediction(result)
        return result

    def get_signals(self) -> List:
        """
        Generate trade signals for the orchestrator.
        This is a demo implementation for paper trading.
        In production, this would analyze real market data and use the trained ML model.
        """
        # Import TradeSignal from orchestrator
        try:
            from aurum_harmony.app.orchestrator import TradeSignal, OrderSide
        except ImportError:
            # Fallback if orchestrator not available
            return []
        
        signals = []
        
        # For demo/paper trading, generate a simple buy signal
        # In production, this would analyze real market data
        signals.append(TradeSignal(
            symbol="NIFTY50",
            side=OrderSide.BUY,
            quantity=1.0,
            reason="Demo paper trading signal - Bullish market conditions detected"
        ))
        
        # Optionally add more signals for different symbols
        signals.append(TradeSignal(
            symbol="BANKNIFTY",
            side=OrderSide.BUY,
            quantity=1.0,
            reason="Demo paper trading signal - Banking sector strength"
        ))
        
        return signals



