# engines/compliance/SEBI_Compliance_Engine.py
import datetime
import requests
import time

class SEBIComplianceEngine:
    def __init__(self, hyperledger_client=None):
        self.hyperledger_client = hyperledger_client
        self.max_exposure = 50_00_000          # ₹50 lakh
        self.max_lots = 1250
        self.min_capital = 10000               # ₹10,000 (Tier 2+)
        self.lot_sizes = {"NIFTY50": 75, "BANKNIFTY": 30, "SENSEX": 20}
        self.last_scrape = 0

    def _scrape_regulations(self):
        if time.time() - self.last_scrape > 86400:  # 24h
            for url in ["https://www.sebi.gov.in", "https://www.nseindia.com", "https://www.bseindia.com"]:
                try:
                    requests.get(url, timeout=15)
                except:
                    pass
            self.last_scrape = time.time()

    def check(self, trade: dict) -> tuple[bool, str]:
        self._scrape_regulations()

        if trade.get("capital", 0) > self.max_exposure:
            return False, "Exposure > ₹50L"
        if trade.get("lots", 0) > self.max_lots:
            return False, "Lots > 1250"
        if trade.get("capital", 0) < self.min_capital and not trade.get("is_ngd", False):
            return False, "Capital < ₹10,000"
        if trade.get("lots", 0) % self.lot_sizes.get(trade.get("index", "").upper(), 1) != 0:
            return False, "Invalid lot size"

        if self.hyperledger_client:
            self.hyperledger_client.log_compliance({
                "trade_id": trade.get("id"),
                "status": "pass" if trade else "fail",
                "timestamp": int(time.time())
            })

        return True, "Compliant"

# Singleton
compliance_engine = SEBIComplianceEngine()