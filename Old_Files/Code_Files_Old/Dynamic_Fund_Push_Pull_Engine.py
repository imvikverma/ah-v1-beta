import upi

class FundPushPull:
    def __init__(self):
        self.upi_client = upi.UPIClient("api_key")

    def push_funds(self, account_id, amount):
        return self.upi_client.push(account_id, amount, "2025-06-23 09:15:00")

    def pull_funds(self, account_id, amount):
        return self.upi_client.pull(account_id, amount, "2025-06-23 15:25:00")

# Example usage
fund_engine = FundPushPull()
print(fund_engine.push_funds("user1", 10000))
print(fund_engine.pull_funds("user1", 5000))