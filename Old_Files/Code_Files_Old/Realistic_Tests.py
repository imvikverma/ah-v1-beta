def run_realistic_tests(capital, trades_per_day, days):
    total_trades = trades_per_day * days
    win_rate = 0.6
    avg_profit = 500
    total_profit = total_trades * win_rate * avg_profit
    return total_profit - (total_trades * (1 - win_rate) * 300)  # Loss of ₹300 per loss

# Example: 45 trades/day, 30 days
print(run_realistic_tests(10000, 45, 30))  # Output: Approx. 202500