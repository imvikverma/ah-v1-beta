"""
Trading Scheduler for AurumHarmony

Implements the 15-minute AI directional cycle + 5-minute HFT execution layer
as specified in Implementation Guide Ver 11.

Architecture:
- 15-minute cycles: Predictive AI generates signals every 15 minutes
- 5-minute HFT windows: Execute trades in 5-minute windows within each cycle
- Max 4 trades per 15-minute cycle
"""

from __future__ import annotations

import logging
import time
import threading
from typing import Dict, Any, List, Optional, Callable
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from enum import Enum

from aurum_harmony.app.orchestrator import TradingOrchestrator, TradeSignal
from aurum_harmony.engines.predictive_ai.predictive_ai import PredictiveAIEngine

# Configure logging
logger = logging.getLogger(__name__)


class CyclePhase(str, Enum):
    """Phases of a 15-minute trading cycle."""
    AI_SIGNAL_GENERATION = "AI_SIGNAL_GENERATION"  # 0-2 minutes
    HFT_EXECUTION_WINDOW_1 = "HFT_EXECUTION_WINDOW_1"  # 2-7 minutes
    HFT_EXECUTION_WINDOW_2 = "HFT_EXECUTION_WINDOW_2"  # 7-12 minutes
    HFT_EXECUTION_WINDOW_3 = "HFT_EXECUTION_WINDOW_3"  # 12-15 minutes
    CYCLE_COMPLETE = "CYCLE_COMPLETE"


@dataclass
class TradingCycle:
    """Represents a 15-minute trading cycle."""
    cycle_id: str
    start_time: datetime
    end_time: datetime
    phase: CyclePhase = CyclePhase.AI_SIGNAL_GENERATION
    signals: List[TradeSignal] = field(default_factory=list)
    executed_trades: int = 0
    max_trades_per_cycle: int = 4
    metadata: Dict[str, Any] = field(default_factory=dict)


class TradingScheduler:
    """
    Manages the 15-minute AI cycle + 5-minute HFT execution architecture.
    
    Flow:
    1. Every 15 minutes: AI generates signals (0-2 min)
    2. Three 5-minute HFT windows: Execute trades (2-15 min)
    3. Max 4 trades per 15-minute cycle (INDICATIVE - AI can intelligently adjust)
    
    NOTE: The max_trades_per_cycle is a GUIDELINE. The AI can intelligently
    exceed or reduce based on signal confidence and market conditions.
    """
    
    def __init__(
        self,
        ai_engine: Optional[PredictiveAIEngine] = None,
        orchestrator: Optional[TradingOrchestrator] = None,
        max_trades_per_cycle: int = 4,
        cycle_duration_minutes: int = 15,
        hft_window_duration_minutes: int = 5
    ):
        """
        Initialize trading scheduler.
        
        Args:
            ai_engine: Predictive AI engine for signal generation
            orchestrator: Trading orchestrator for execution
            max_trades_per_cycle: Maximum trades per 15-minute cycle (default: 4)
            cycle_duration_minutes: Duration of each cycle (default: 15)
            hft_window_duration_minutes: Duration of each HFT window (default: 5)
        """
        self.ai_engine = ai_engine or PredictiveAIEngine()
        self.orchestrator = orchestrator
        self.max_trades_per_cycle = max_trades_per_cycle
        self.cycle_duration_minutes = cycle_duration_minutes
        self.hft_window_duration_minutes = hft_window_duration_minutes
        
        self.current_cycle: Optional[TradingCycle] = None
        self.cycle_history: List[TradingCycle] = []
        self.is_running = False
        self.scheduler_thread: Optional[threading.Thread] = None
        self._lock = threading.Lock()
        
        logger.info(
            f"TradingScheduler initialized: "
            f"cycle={cycle_duration_minutes}min, "
            f"hft_window={hft_window_duration_minutes}min, "
            f"max_trades={max_trades_per_cycle}"
        )
    
    def start(self) -> None:
        """Start the trading scheduler."""
        if self.is_running:
            logger.warning("Scheduler is already running")
            return
        
        self.is_running = True
        self.scheduler_thread = threading.Thread(target=self._scheduler_loop, daemon=True)
        self.scheduler_thread.start()
        logger.info("Trading scheduler started")
    
    def stop(self) -> None:
        """Stop the trading scheduler."""
        self.is_running = False
        if self.scheduler_thread:
            self.scheduler_thread.join(timeout=5.0)
        logger.info("Trading scheduler stopped")
    
    def _scheduler_loop(self) -> None:
        """Main scheduler loop running in background thread."""
        while self.is_running:
            try:
                # Start new 15-minute cycle
                cycle_start = datetime.now()
                cycle_end = cycle_start + timedelta(minutes=self.cycle_duration_minutes)
                
                with self._lock:
                    self.current_cycle = TradingCycle(
                        cycle_id=f"cycle_{int(cycle_start.timestamp())}",
                        start_time=cycle_start,
                        end_time=cycle_end,
                        max_trades_per_cycle=self.max_trades_per_cycle
                    )
                
                logger.info(
                    f"Starting new trading cycle: {self.current_cycle.cycle_id} "
                    f"({cycle_start.strftime('%H:%M:%S')} - {cycle_end.strftime('%H:%M:%S')})"
                )
                
                # Phase 1: AI Signal Generation (0-2 minutes)
                self._phase_ai_signal_generation()
                
                # Phase 2-4: HFT Execution Windows (2-15 minutes)
                # Window 1: 2-7 minutes
                self._phase_hft_execution(CyclePhase.HFT_EXECUTION_WINDOW_1, 2, 7)
                
                # Window 2: 7-12 minutes
                self._phase_hft_execution(CyclePhase.HFT_EXECUTION_WINDOW_2, 7, 12)
                
                # Window 3: 12-15 minutes
                self._phase_hft_execution(CyclePhase.HFT_EXECUTION_WINDOW_3, 12, 15)
                
                # Complete cycle
                with self._lock:
                    if self.current_cycle:
                        self.current_cycle.phase = CyclePhase.CYCLE_COMPLETE
                        self.cycle_history.append(self.current_cycle)
                        logger.info(
                            f"Cycle {self.current_cycle.cycle_id} completed: "
                            f"{self.current_cycle.executed_trades}/{self.max_trades_per_cycle} trades executed"
                        )
                
                # Wait until next cycle start (align to 15-minute boundaries)
                now = datetime.now()
                next_cycle_start = self._get_next_cycle_start(now)
                wait_seconds = (next_cycle_start - now).total_seconds()
                
                if wait_seconds > 0:
                    logger.debug(f"Waiting {wait_seconds:.1f} seconds until next cycle")
                    time.sleep(wait_seconds)
                
            except Exception as e:
                logger.error(f"Error in scheduler loop: {e}", exc_info=True)
                time.sleep(60)  # Wait 1 minute before retrying
    
    def _phase_ai_signal_generation(self) -> None:
        """Phase 1: Generate AI signals (0-2 minutes)."""
        try:
            with self._lock:
                if self.current_cycle:
                    self.current_cycle.phase = CyclePhase.AI_SIGNAL_GENERATION
            
            logger.info("Phase 1: Generating AI signals...")
            
            # Generate signals from AI engine
            signals = self.ai_engine.get_signals()
            
            with self._lock:
                if self.current_cycle:
                    self.current_cycle.signals = signals
            
            logger.info(f"Generated {len(signals)} AI signals for this cycle")
            
            # Wait until 2 minutes into cycle
            if self.current_cycle:
                elapsed = (datetime.now() - self.current_cycle.start_time).total_seconds()
                wait_time = max(0, 120 - elapsed)  # 2 minutes = 120 seconds
                if wait_time > 0:
                    time.sleep(wait_time)
        
        except Exception as e:
            logger.error(f"Error in AI signal generation phase: {e}", exc_info=True)
    
    def _phase_hft_execution(
        self,
        phase: CyclePhase,
        window_start_minutes: int,
        window_end_minutes: int
    ) -> None:
        """Execute HFT trades in a 5-minute window."""
        try:
            if not self.current_cycle or not self.orchestrator:
                return
            
            # Check if we've reached max trades
            if self.current_cycle.executed_trades >= self.max_trades_per_cycle:
                logger.debug(f"Skipping {phase.value}: Max trades reached for this cycle")
                return
            
            with self._lock:
                if self.current_cycle:
                    self.current_cycle.phase = phase
            
            window_start_time = self.current_cycle.start_time + timedelta(minutes=window_start_minutes)
            window_end_time = self.current_cycle.start_time + timedelta(minutes=window_end_minutes)
            
            now = datetime.now()
            if now < window_start_time:
                wait_time = (window_start_time - now).total_seconds()
                time.sleep(wait_time)
            
            logger.info(f"{phase.value}: Executing trades ({window_start_minutes}-{window_end_minutes} min)")
            
            # Execute trades from available signals
            # Note: max_trades_per_cycle is a guideline - AI can intelligently adjust
            remaining_trades = self.max_trades_per_cycle - self.current_cycle.executed_trades
            
            # Get AI-driven adaptive capacity if available
            if self.ai_engine and hasattr(self.ai_engine, 'get_adaptive_trade_capacity'):
                try:
                    # Calculate average confidence of signals
                    avg_confidence = 0.7
                    if self.current_cycle.signals:
                        # Try to extract confidence from signal reasons
                        confidences = []
                        for sig in self.current_cycle.signals:
                            if "confidence:" in sig.reason:
                                try:
                                    conf_str = sig.reason.split("confidence: ")[1].split("%")[0]
                                    confidences.append(float(conf_str) / 100)
                                except:
                                    confidences.append(0.7)
                            else:
                                confidences.append(0.7)
                        avg_confidence = sum(confidences) / len(confidences) if confidences else 0.7
                    
                    # Get adaptive capacity
                    capacity_info = self.ai_engine.get_adaptive_trade_capacity(
                        current_trades=self.current_cycle.executed_trades,
                        average_confidence=avg_confidence
                    )
                    
                    # Use adaptive max if higher confidence allows exceeding
                    if capacity_info.get("should_exceed", False):
                        adaptive_max = capacity_info.get("adaptive_max", self.max_trades_per_cycle)
                        remaining_trades = adaptive_max - self.current_cycle.executed_trades
                        logger.debug(
                            f"AI decision: Exceeding cycle limit ({self.max_trades_per_cycle} → {adaptive_max}) "
                            f"due to high confidence"
                        )
                except Exception as e:
                    logger.warning(f"Error getting adaptive capacity: {e}")
            
            signals_to_execute = self.current_cycle.signals[:max(0, remaining_trades)]
            
            for signal in signals_to_execute:
                if datetime.now() >= window_end_time:
                    break
                
                if self.current_cycle.executed_trades >= self.max_trades_per_cycle:
                    break
                
                try:
                    # Execute trade through orchestrator
                    orders = self.orchestrator.run_once()
                    
                    with self._lock:
                        if self.current_cycle:
                            self.current_cycle.executed_trades += len([o for o in orders if o.status.value == "FILLED"])
                    
                    logger.debug(f"Executed trade from signal: {signal.symbol} {signal.side.value}")
                    
                except Exception as e:
                    logger.error(f"Error executing trade: {e}", exc_info=True)
            
            # Wait until window end
            now = datetime.now()
            if now < window_end_time:
                wait_time = (window_end_time - now).total_seconds()
                time.sleep(wait_time)
        
        except Exception as e:
            logger.error(f"Error in HFT execution phase: {e}", exc_info=True)
    
    def _get_next_cycle_start(self, current_time: datetime) -> datetime:
        """Get the next 15-minute boundary."""
        # Round up to next 15-minute mark
        minutes = current_time.minute
        next_15_min = ((minutes // 15) + 1) * 15
        
        if next_15_min >= 60:
            # Next hour
            next_cycle = current_time.replace(minute=0, second=0, microsecond=0) + timedelta(hours=1)
        else:
            next_cycle = current_time.replace(minute=next_15_min, second=0, microsecond=0)
        
        return next_cycle
    
    def get_current_cycle_status(self) -> Optional[Dict[str, Any]]:
        """Get status of current cycle."""
        with self._lock:
            if not self.current_cycle:
                return None
            
            return {
                "cycle_id": self.current_cycle.cycle_id,
                "phase": self.current_cycle.phase.value,
                "start_time": self.current_cycle.start_time.isoformat(),
                "end_time": self.current_cycle.end_time.isoformat(),
                "signals_generated": len(self.current_cycle.signals),
                "trades_executed": self.current_cycle.executed_trades,
                "max_trades": self.current_cycle.max_trades_per_cycle,
                "remaining_trades": self.current_cycle.max_trades_per_cycle - self.current_cycle.executed_trades,
            }
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get scheduler statistics."""
        with self._lock:
            total_cycles = len(self.cycle_history)
            total_trades = sum(c.executed_trades for c in self.cycle_history)
            avg_trades_per_cycle = total_trades / total_cycles if total_cycles > 0 else 0
            
            return {
                "is_running": self.is_running,
                "total_cycles": total_cycles,
                "total_trades_executed": total_trades,
                "avg_trades_per_cycle": avg_trades_per_cycle,
                "max_trades_per_cycle": self.max_trades_per_cycle,
                "current_cycle": self.get_current_cycle_status(),
            }


# Default instance
trading_scheduler = TradingScheduler()

__all__ = [
    "TradingScheduler",
    "TradingCycle",
    "CyclePhase",
    "trading_scheduler",
]

