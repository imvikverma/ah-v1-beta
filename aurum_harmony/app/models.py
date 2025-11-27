# Placeholder for AurumHarmony database models 

from typing import List, Dict

class User:
    """
    Represents a user in the AurumHarmony system.
    Stores user code, KYC data, capital, trade limits, account info, and lock states.
    """
    def __init__(self, user_code: str, kyc_data: Dict, initial_capital: float, trade_limit: int, accounts: List[str],
                 is_admin: bool = False):
        self.user_code = user_code
        self.kyc_data = kyc_data  # e.g., {'name': ..., 'pan': ..., 'aadhaar': ...}
        self.initial_capital = initial_capital
        self.initial_capital_locked = False
        self.trade_limit = trade_limit
        self.trade_limit_locked = False
        self.accounts = accounts  # List of demat/trading account IDs
        self.accounts_locked = False
        self.is_admin = is_admin

    def to_dict(self):
        return {
            'user_code': self.user_code,
            'kyc_data': self.kyc_data,
            'initial_capital': self.initial_capital,
            'initial_capital_locked': self.initial_capital_locked,
            'trade_limit': self.trade_limit,
            'trade_limit_locked': self.trade_limit_locked,
            'accounts': self.accounts,
            'accounts_locked': self.accounts_locked,
            'is_admin': self.is_admin
        } 