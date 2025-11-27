def calculate_increment(initial_capital, win_rate, leverage):
    increment = initial_capital * win_rate * leverage * 0.01
    return max(increment, 1000)  # Minimum increment of ₹1000

# Example usage
print(calculate_increment(10000, 0.6, 3))  # Output: 1800.0