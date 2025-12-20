# engines/risk_management/Risk_Management_Engine.py
import numpy as np
import time


class RiskManagementEngine:
    def __init__(self, hyperledger_client=None):
        self.hyperledger_client = hyperledger_client
        # 2.5% max drawdown
        self.max_drawdown = 0.025
        self.var_limit = 0.02  # 2% VaR at 95%
        self.cvar_limit = 0.025  # 2.5% CVaR

    def calculate_var_cvar(self, returns: np.ndarray, confidence: float = 0.95) -> dict:
        """
        Value at Risk (VaR) and Conditional VaR (CVaR) per user.
        """
        var = np.percentile(returns, (1 - confidence) * 100)
        cvar = returns[returns <= var].mean()

        result = {
            "var_95": round(var, 5),
            "cvar_95": round(cvar, 5),
        }
        if self.hyperledger_client:
            self.hyperledger_client.log_risk_metrics(
                {**result, "timestamp": int(time.time())}
            )
        return result

    def check_drawdown(self, capital: float, peak: float) -> dict:
        """
        Checks if the drawdown from peak exceeds allowed max_drawdown.
        """
        if peak <= 0:
            return {"ok": True, "drawdown_pct": 0.0}

        drawdown = (peak - capital) / peak
        ok = drawdown <= self.max_drawdown
        result = {
            "ok": ok,
            "drawdown_pct": round(drawdown, 5),
            "max_allowed": self.max_drawdown,
        }
        if self.hyperledger_client:
            self.hyperledger_client.log_drawdown_check(
                {**result, "timestamp": int(time.time())}
            )
        return result


risk_engine = RiskManagementEngine()


