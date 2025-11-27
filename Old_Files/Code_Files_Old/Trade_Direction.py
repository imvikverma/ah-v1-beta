import numpy as np

def determine_trade_direction(rsi, atr, confidence_threshold=0.7):
    if rsi > 70 and np.random.random() > confidence_threshold:
        return "bullish"  # Buy calls
    elif rsi < 30 and np.random.random() > confidence_threshold:
        return "bearish"  # Buy puts
    else:
        return "neutral"  # Sell straddles/strangles

# Example usage
rsi_values = [75, 25, 50]
for rsi in rsi_values:
    direction = determine_trade_direction(rsi, atr=10)
    print(f"RSI: {rsi}, Direction: {direction}")