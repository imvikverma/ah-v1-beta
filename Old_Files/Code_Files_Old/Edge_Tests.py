def run_edge_tests(capital, vix):
    capacity, _, _ = adjust_strategy_capacity(vix)
    max_drawdown = capital * 0.025  # 2.5% max drawdown
    return capacity * capital - max_drawdown

# Example: VIX 35
print(run_edge_tests(150000, 35))  # Output: Approx. 73625