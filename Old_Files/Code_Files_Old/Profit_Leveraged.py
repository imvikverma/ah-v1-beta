def calculate_profit(capital, leverage, win_rate, trade_value):
    profit = capital * leverage * win_rate * (trade_value / 100)
    return profit - (capital * leverage * (1 - win_rate) * 0.03)  # 3% loss per losing trade

print(calculate_profit(10000, 3, 0.6, 5))  # Output: Approx. 870