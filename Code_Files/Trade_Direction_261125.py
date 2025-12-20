# engines/predictive_ai/Trade_Direction.py
import numpy as np

def get_direction(rsi: float, confidence: float = 0.7) -> str:
    if rsi > 70 and np.random.random() > (1 - confidence):
        return "bullish"
    if rsi < 30 and np.random.random() > (1 - confidence):
        return "bearish"
    return "neutral"