# engines/backtesting/Realistic_Tests.py
import numpy as np

def run_realistic_tests(
    capital: float = 10000,
    days: int = 20,
    vix_level: float = 18
) -> dict:
    """
    Realistic simulation per user (₹10,000 start)
    """
    from engines.predictive_ai.VIX_Adjustment_Logic import VIXAdjustment
    adj = VIXAdjustment().adjust(vix_level, capital)

    trades_per_day = adj["trades_per_day"]
    win_rate = adj["win_rate"]
    total_trades = trades_per_day * days

    avg_win = capital * 0.07 * 3   # 7% win with 3x leverage
    avg_loss = capital * 0.03 * 3  # 3% loss with 3x leverage

    gross_profit = total_trades * win_rate * avg_win
    gross_loss = total_trades * (1 - win_rate) * avg_loss
    net_profit = gross_profit - gross_loss

    return {
        "starting_capital": capital,
        "vix": vix_level,
        "trades_per_day": trades_per_day,
        "total_trades": total_trades,
        "win_rate": round(win_rate, 3),
        "gross_profit": round(gross_profit),
        "gross_loss": round(gross_loss),
        "net_profit": round(net_profit),
        "ending_capital": round(capital + net_profit)
    }

if __name__ == "__main__":
    print(run_realistic_tests())