"""
System Integration Module for AurumHarmony

Wires together all engines and services into a cohesive trading system.
This is the central integration point for all components.
"""

from __future__ import annotations

import logging
from typing import Dict, Any, Optional

# Configure logging
logger = logging.getLogger(__name__)


class AurumHarmonySystem:
    """
    Central system integration class that initializes and connects all engines.
    
    This is the main entry point for the complete AurumHarmony trading system.
    """
    
    def __init__(self):
        """Initialize the complete AurumHarmony system."""
        logger.info("Initializing AurumHarmony System...")
        
        # Import all engines (using singleton instances)
        from aurum_harmony.engines.predictive_ai.predictive_ai import predictive_ai_engine
        from aurum_harmony.engines.compliance.compliance_engine import compliance_engine
        from aurum_harmony.engines.compliance.order_splitting import order_splitting_engine
        from aurum_harmony.engines.compliance.sebi_scraper import sebi_scraper
        from aurum_harmony.engines.fund_push_pull.fund_push_pull import fund_engine
        from aurum_harmony.engines.fund_push_pull.scheduled_transfers import scheduled_fund_manager
        from aurum_harmony.engines.settlement.Settlement_Engine import settlement_engine
        from aurum_harmony.engines.notifications.notifications import notifier
        from aurum_harmony.engines.reporting.reporting import reporting_engine
        from aurum_harmony.engines.backtesting.backtesting import backtesting_engine
        from aurum_harmony.engines.risk_management.leverage_engine import leverage_engine
        from aurum_harmony.engines.ml_training.ml_training_engine import ml_training_engine
        from aurum_harmony.engines.timing.trading_scheduler import trading_scheduler
        from aurum_harmony.engines.simulation.performance_simulation import performance_simulation
        from aurum_harmony.app.orchestrator import TradingOrchestrator
        from aurum_harmony.app.config import load_config
        from aurum_harmony.engines.integration_layer import trading_system
        
        # Store engine instances
        self.ai_engine = predictive_ai_engine
        self.compliance_engine = compliance_engine
        self.order_splitting_engine = order_splitting_engine
        self.sebi_scraper = sebi_scraper
        self.fund_engine = fund_engine
        self.scheduled_fund_manager = scheduled_fund_manager
        self.settlement_engine = settlement_engine
        self.notifier = notifier
        self.reporting_engine = reporting_engine
        self.backtesting_engine = backtesting_engine
        self.leverage_engine = leverage_engine
        self.ml_training_engine = ml_training_engine
        self.trading_scheduler = trading_scheduler
        self.performance_simulation = performance_simulation
        self.trading_system = trading_system
        
        # Load configuration
        self.config = load_config()
        
        # Initialize orchestrator
        self.orchestrator = TradingOrchestrator(
            signal_source=self.ai_engine,
            config=self.config
        )
        
        # Wire up scheduler
        self.trading_scheduler.ai_engine = self.ai_engine
        self.trading_scheduler.orchestrator = self.orchestrator
        
        logger.info("AurumHarmony System initialized successfully")
    
    def start_all_services(self) -> None:
        """Start all background services."""
        logger.info("Starting all background services...")
        
        try:
            # Start SEBI scraper (daily 08:30-09:00 IST)
            self.sebi_scraper.start()
            logger.info("✅ SEBI scraper started")
        except Exception as e:
            logger.error(f"Error starting SEBI scraper: {e}")
        
        try:
            # Start scheduled fund transfers (09:15 PULL, 15:25 PUSH)
            self.scheduled_fund_manager.start()
            logger.info("✅ Scheduled fund transfer manager started")
        except Exception as e:
            logger.error(f"Error starting scheduled fund manager: {e}")
        
        try:
            # Start trading scheduler (15-min cycles)
            self.trading_scheduler.start()
            logger.info("✅ Trading scheduler started")
        except Exception as e:
            logger.error(f"Error starting trading scheduler: {e}")
        
        logger.info("All background services started")
    
    def stop_all_services(self) -> None:
        """Stop all background services."""
        logger.info("Stopping all background services...")
        
        self.sebi_scraper.stop()
        self.scheduled_fund_manager.stop()
        self.trading_scheduler.stop()
        
        logger.info("All background services stopped")
    
    def get_system_status(self) -> Dict[str, Any]:
        """Get comprehensive system status."""
        return {
            "system": "AurumHarmony v1.0 Beta",
            "trading_mode": "LIVE" if self.config.is_live else "PAPER",
            "engines": {
                "predictive_ai": "active",
                "compliance": self.compliance_engine.get_compliance_report(),
                "order_splitting": "active",
                "sebi_scraper": self.sebi_scraper.get_scraper_status(),
                "fund_engine": self.fund_engine.get_statistics(),
                "scheduled_transfers": self.scheduled_fund_manager.get_status(),
                "settlement": "active",
                "notifications": self.notifier.get_statistics(),
                "reporting": "active",
                "backtesting": "active",
                "leverage": "active",
                "ml_training": self.ml_training_engine.get_training_status(),
                "trading_scheduler": self.trading_scheduler.get_statistics(),
                "performance_simulation": "active",
            },
            "services": {
                "sebi_scraper": self.sebi_scraper.is_running,
                "scheduled_transfers": self.scheduled_fund_manager.is_running,
                "trading_scheduler": self.trading_scheduler.is_running,
            },
        }


# Global system instance
aurum_system = AurumHarmonySystem()

__all__ = [
    "AurumHarmonySystem",
    "aurum_system",
]

