# engines/predictive_ai/VIX_Adjustment_Logic.py
import numpy as np
import time


class VIXAdjustment:
    def __init__(self, hyperledger_client=None):
        self.hyperledger_client = hyperledger_client

    def adjust(self, vix: float, capital: float = 10000) -> dict:
        if vix < 15:
            capacity, target_return, win_rate = 1.0, 0.10, np.random.uniform(0.60, 0.66)
        elif vix < 20:
            capacity, target_return, win_rate = 0.75, 0.08, np.random.uniform(0.55, 0.60)
        elif vix < 30:
            capacity, target_return, win_rate = 0.50, 0.07, np.random.uniform(0.50, 0.55)
        else:
            capacity, target_return, win_rate = 0.50, 0.05, np.random.uniform(0.45, 0.50)

        result = {
            "capacity": capacity,
            "target_return": target_return,
            "win_rate": win_rate,
            "adjusted_capital": capital * capacity * 3,
            "trades_per_day": int(27 + (180 - 27) * capacity),
        }
        if self.hyperledger_client:
            self.hyperledger_client.log_vix_adjustment(
                {**result, "vix": vix, "timestamp": int(time.time())}
            )
        return result



