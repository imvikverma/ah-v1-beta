# engines/predictive_ai/ML_Training_Module.py
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense, Dropout
import time

class MLTrainingModule:
    def __init__(self, hyperledger_client=None):
        self.rf_model = RandomForestClassifier(n_estimators=300, random_state=42)
        self.lstm_model = None
        self.hyperledger_client = hyperledger_client

    def prepare_lstm_data(self, df: pd.DataFrame, seq_length: int = 60) -> tuple:
        """Convert flat data into sequences for LSTM"""
        feature_cols = ['rsi', 'atr', 'vix', 'oi_change', 'volume_spike']
        data = df[feature_cols].values
        sequences, labels = [], []
        for i in range(seq_length, len(data)):
            sequences.append(data[i-seq_length:i])
            labels.append(df['direction'].iloc[i])  # 0=bearish, 1=neutral, 2=bullish
        return np.array(sequences), np.array(labels)

    def train_hybrid(self, df: pd.DataFrame):
        # Train Random Forest
        X_rf = df[['rsi', 'atr', 'vix', 'oi_change', 'volume_spike']]
        y_rf = df['direction']
        X_train, X_test, y_train, y_test = train_test_split(X_rf, y_rf, test_size=0.2, random_state=42)
        self.rf_model.fit(X_train, y_train)
        rf_acc = self.rf_model.score(X_test, y_test)

        # Train LSTM
        X_lstm, y_lstm = self.prepare_lstm_data(df)
        self.lstm_model = Sequential([
            LSTM(100, return_sequences=True, input_shape=(X_lstm.shape[1], X_lstm.shape[2])),
            Dropout(0.2),
            LSTM(50),
            Dropout(0.2),
            Dense(3, activation='softmax')
        ])
        self.lstm_model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])
        self.lstm_model.fit(X_lstm, y_lstm, epochs=15, batch_size=32, validation_split=0.2, verbose=0)

        log_entry = {
            "rf_accuracy": round(rf_acc, 4),
            "timestamp": int(time.time())
        }
        if self.hyperledger_client:
            self.hyperledger_client.log_ml_training(log_entry)

        return {"rf_accuracy": rf_acc, "status": "training_complete"}

# Global instance
ml_trainer = MLTrainingModule()