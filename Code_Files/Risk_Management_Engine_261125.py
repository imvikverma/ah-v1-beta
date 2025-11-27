# engines/risk_management/Risk_Management_Engine.py
import numpy as np
import time

class RiskManagementEngine:
    def __init__(self, hyperledger_client=None):
        self.hyperledger_client = hyperledger_client
        # 2.5% max drawdown
        self.max_drawdown = 0.025
        self.var_limit = 0.02              # 2% VaR at 95%
        self.cvar_limit = 0.025            # 2.5% CVaR

    def calculate_var_cvar(self, returns: np.ndarray, confidence: float = 0.95) -> dict:
        """
        Value at Risk (VaR) and Conditional VaR (CVaR) per user
        """
        var = np.percentile(returns, (1 - confidence) * 100)
        cvar = returns[returns <= var].mean()

        result = {
            "var_95": round(var, 5),
            "cvar_95": round(cvar,