import pandas as pd

def adjust_strategy_capacity(vix_value):
    if vix_value < 15:
        return 1.0, 0.10, 0.66  # 100% capacity, 10% return, 66% win rate
    elif 15 <= vix_value < 20:
        return 0.75, 0.08, 0.60  # 75% capacity, 8% return, 60% win rate
    elif 20 <= vix_value < 30:
        return 0.50, 0.07, 0.55  # 50% capacity, 7% return, 55% win rate
    else:
        return 0.50, 0.05, 0.50  # 50% capacity, 5% return, 50% win rate

# Example usage
vix_data = pd.Series([10, 18, 25, 35])
for vix in vix_data:
    capacity, return_rate, win_rate = adjust_strategy_capacity(vix)
    print(f"VIX: {vix}, Capacity: {capacity}, Return: {return_rate}, Win Rate: {win_rate}")