# engines/fund_push_pull/Dynamic_Fund_Push_Pull_Engine.py
import time
from datetime import datetime

class DynamicFundPushPull:
    def __init__(self, upi_client=None, hyperledger_client=None):
        self.upi_client = upi_client
        self.hyperledger_client = hyperledger_client
        self.push_time = "09:15"
        self.pull_time = "15:25"

    def should_push(self) -> bool:
        return datetime.now().strftime("%H:%M") == self.push_time

    def should_pull(self) -> bool:
        return datetime.now().strftime("%H:%M") == self.pull_time

    def push_funds(self, user_id: str, amount: float) -> dict:
        result = {"user_id": user_id, "amount": amount, "action": "push", "timestamp": int(time.time())}
        if self.upi_client:
            success = self.upi_client.send(amount, user_id)
            result["status"] = "success" if success else "failed"
        if self.hyperledger_client:
            self.hyperledger_client.log_fund_movement(result)
        return result

    def pull_funds(self, user_id: str, amount: float) -> dict:
        result = {"user_id": user_id, "amount": amount, "action": "pull", "timestamp": int(time.time())}
        if self.upi_client:
            success = self.upi_client.receive(amount, user_id)
            result["status"] = "success" if success else "failed"
        if self.hyperledger_client:
            self.hyperledger_client.log_fund_movement(result)
        return result

# Global instance
fund_engine = DynamicFundPushPull()