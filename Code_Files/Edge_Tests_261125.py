# engines/backtesting/Edge_Tests.py
import numpy as np
from engines.predictive_ai.VIX_Adjustment_Logic import VIXAdjustment

def run_edge_tests(capital: float = 10000, vix: float = 35, days: int = 20) -> dict:
    """
    Stress-test under worst-case VIX (>30) — 50% capacity, 5% target return
    """
    adj = VIXAdjustment().adjust(vix, capital)
    trades_per_day = adj["trades_per_day"]
    win_rate = adj["win_rate"]
    total_trades = trades_per_day * days

    # Extreme loss scenario: 3% loss per losing trade, 7% win per winning trade
    avg_win = capital * 0.07 * 3
    avg_loss = capital * 0.03 * 3

    worst_profit = total_trades * win_rate * avg_win
    worst_loss = total_trades * (1 - win_rate) * avg_loss
    net = worst_profit - worst_loss

    return {
        "scenario": "Extreme VIX (>30)",
        "vix": vix,
        "capacity": adj["capacity"],
        "win_rate": round(win_rate, 3),
        "trades_per_day": trades_per_day,
        "net_20_days": round(net),
        "ending_capital": round(capital + net),
        "max_drawdown_pct": round((capital + net - capital) / capital * 100, 2)
    }

if __name__ == "__main__":
    print(run_edge_tests())