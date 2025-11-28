# engines/settlement/Settlement_Engine.py
# Final — 28 Nov 2025

class SettlementEngine:
    @staticmethod
    def settle(gross_profit: float, category: str, current_capital: float) -> dict:
        # ZPT Fee per your categories
        fee_pct = {"NGD": 0.15, "restricted": 0.30, "semi": 0.125}.get(category, 0.30)
        platform_fee = gross_profit * fee_pct
        saffronbolt = platform_fee * 0.70
        zenithpulse = platform_fee * 0.30

        # 39% tax locked in savings (hidden in UI)
        tax_lock = gross_profit * 0.39
        net_before_rounding = gross_profit - platform_fee - tax_lock

        # Rounding — excess stays in demat
        rounded_net = round(net_before_rounding / 1000) * 1000
        rounding_buffer = net_before_rounding - rounded_net

        return {
            "gross_profit": gross_profit,
            "platform_fee": platform_fee,
            "saffronbolt_share": saffronbolt,
            "zenithpulse_share": zenithpulse,
            "tax_locked_savings": tax_lock,
            "net_to_savings": rounded_net,
            "rounding_buffer_in_demat": rounding_buffer,
            "next_capital": IncrementEngine.get_next_capital(category, current_capital)
        }