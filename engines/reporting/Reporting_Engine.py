# engines/reporting/Reporting_Engine.py
from __future__ import annotations

from typing import Dict, Any, List
import time

from aurum_harmony.blockchain.blockchain_reporting import (
    query_trades_by_user,
    query_trade_by_id,
)


class ReportingEngine:
    """
    High-level reporting utilities over trade / settlement data.

    For v1.0 Beta this is intentionally simple and works even when the
    Fabric gateway is not configured (blockchain calls become NO-OPs).
    """

    def user_trade_summary(self, user_id: str) -> Dict[str, Any]:
        trades: List[Dict[str, Any]] = query_trades_by_user(user_id)

        total_trades = len(trades)
        gross_profit = 0.0
        gross_loss = 0.0
        wins = 0
        losses = 0

        for t in trades:
            pnl = float(t.get("pnl", 0))
            if pnl >= 0:
                wins += 1
                gross_profit += pnl
            else:
                losses += 1
                gross_loss += pnl

        net_profit = gross_profit + gross_loss
        win_rate = wins / total_trades if total_trades else 0.0

        return {
            "user_id": user_id,
            "total_trades": total_trades,
            "wins": wins,
            "losses": losses,
            "win_rate": round(win_rate, 4),
            "gross_profit": round(gross_profit, 2),
            "gross_loss": round(gross_loss, 2),
            "net_profit": round(net_profit, 2),
            "timestamp": int(time.time()),
        }

    def trade_detail(self, trade_id: str) -> Dict[str, Any]:
        trade = query_trade_by_id(trade_id)
        trade["timestamp_queried"] = int(time.time())
        return trade


reporting_engine = ReportingEngine()


