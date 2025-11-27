class SettlementEngine:
    def settle_trade(self, trade_id, profit):
        if profit > 0:
            return f"Settled {trade_id} with profit ₹{profit}"
        return f"Settled {trade_id} with loss ₹{-profit}"

# Example usage
settle = SettlementEngine()
print(settle.settle_trade("TRADE2025062310", 250))