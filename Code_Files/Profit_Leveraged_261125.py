# engines/deductions_and_taxes/Profit_Leveraged.py
import time

def calculate_leveraged_profit(
    capital: float = 10000,
    leverage: float = 3.0,
    win_rate: float = 0.55,
    target_return: float = 0.07,
    loss_per_trade: float = 0.03
) -> dict:
    """
    Per-user leveraged profit calculation (₹10,000 base)
    """
    effective_capital = capital * leverage
    win_amount = effective_capital * target_return
    loss_amount = effective_capital * loss_per_trade

    gross_profit = win_amount * win_rate
    gross_loss = loss_amount * (1 - win_rate)
    net_profit = gross_profit - gross_loss

    result = {
        "base_capital": capital,
        "effective_capital": effective_capital,
        "win_rate": round(win_rate, 3),
        "net_profit": round(net_profit),
        "return_pct": round((net_profit / capital) * 100, 2),
        "timestamp": int(time.time())
    }

    return result

if __name__ == "__main__":
    print(calculate_leveraged_profit())