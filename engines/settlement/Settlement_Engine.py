# engines/settlement/Settlement_Engine.py
import time


class SettlementEngine:
    def __init__(self, hyperledger_client=None):
        self.hyperledger_client = hyperledger_client
        self.beta_phase = True  # Switch to False post-beta

    def settle(self, user_id: str, gross_profit: float) -> dict:
        """
        EOD settlement per user (₹10,000 base)
        Beta: 30% platform fee
        Post-Beta: 12% platform fee
        """
        platform_fee_pct = 0.30 if self.beta_phase else 0.12
        platform_fee = gross_profit * platform_fee_pct

        # Split platform fee
        saffronbolt_share = platform_fee * 0.70
        zenithpulse_share = (
            platform_fee * 0.30 if self.beta_phase else platform_fee * 0.15
        )

        net_to_user = gross_profit - platform_fee

        result = {
            "user_id": user_id,
            "gross_profit": round(gross_profit),
            "platform_fee_pct": platform_fee_pct,
            "platform_fee": round(platform_fee),
            "saffronbolt_share": round(saffronbolt_share),
            "zenithpulse_share": round(zenithpulse_share),
            "net_to_user": round(net_to_user),
            "beta_phase": self.beta_phase,
            "timestamp": int(time.time()),
        }

        if self.hyperledger_client:
            self.hyperledger_client.log_settlement(result)

        return result


settlement_engine = SettlementEngine()


