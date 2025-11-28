# engines/increment/Increment.py
# Final — 28 Nov 2025

class IncrementEngine:
    LEVELS = {
        "NGD": [5000],  # cyclical — no increment
        "restricted": [10000, 50000, 100000],
        "admin": [10000, 50000, 100000, 500000, 1500000]
    }

    @staticmethod
    def get_next_capital(category: str, current_capital: float) -> float:
        levels = IncrementEngine.LEVELS.get(category, IncrementEngine.LEVELS["restricted"])
        if current_capital in levels:
            idx = levels.index(current_capital)
            if idx + 1 < len(levels):
                return levels[idx + 1]
        return current_capital  # no increment or max reached