import datetime

class ComplianceEngine:
    def __init__(self):
        self.expiry_rules = {'nifty50': datetime.date(2025, 6, 26), 'banknifty': datetime.date(2025, 6, 26)}

    def check_compliance(self, trade):
        if trade['capital'] > 1500000:
            return False, "Exceeds SEBI exposure limit"
        if trade['expiry'] > self.expiry_rules[trade['index']]:
            return False, "Expiry date violation"
        return True, "Compliant"

# Example usage
trade = {'index': 'nifty50', 'capital': 1000000, 'expiry': datetime.date(2025, 6, 25)}
is_compliant, message = ComplianceEngine().check_compliance(trade)
print(f"Compliance: {is_compliant}, Message: {message}")