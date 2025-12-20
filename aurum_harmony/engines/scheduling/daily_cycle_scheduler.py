"""
Daily Cycle Scheduler for AurumHarmony

Handles the complete daily trading cycle:
- Auto logoff at 4:30-5:00 PM IST after settlements
- Pre-market preparation starting 8:30 AM IST
- Market intelligence and regulatory compliance checks
- Automated system startup and trade planning
"""

import logging
import threading
import time
from datetime import datetime, time, timedelta
from typing import Dict, Any, Optional, Callable
import pytz

try:
    import schedule
    SCHEDULE_AVAILABLE = True
except ImportError:
    SCHEDULE_AVAILABLE = False
    logging.warning("python-schedule package not available, using basic scheduler")

from aurum_harmony.engines.scheduling.trading_calendar import TradingCalendar
from ..compliance.regulatory_monitor import RegulatoryMonitor
from ..market_intelligence.market_intelligence import MarketIntelligenceEngine

logger = logging.getLogger(__name__)

class DailyCycleScheduler:
    """
    Manages the complete daily trading cycle with automated scheduling.

    Daily Cycle:
    - 4:30-5:00 PM: Auto logoff after settlements
    - 8:30 AM: System startup and pre-market preparation
    - 9:15 AM: Final trade planning before market open
    - 9:30 AM: Market open - trading begins
    """

    def __init__(self, orchestrator, timezone: str = "Asia/Kolkata"):
        """
        Initialize the daily cycle scheduler.

        Args:
            orchestrator: Trading orchestrator instance
            timezone: Timezone for scheduling (IST by default)
        """
        self.orchestrator = orchestrator
        self.timezone = pytz.timezone(timezone)
        self.scheduler_thread: Optional[threading.Thread] = None
        self.is_running = False

        # System state tracking
        self.market_open = False
        self.system_active = False
        self.pre_market_prepared = False

        # Initialize monitoring engines
        self.regulatory_monitor = RegulatoryMonitor()
        self.market_intelligence = MarketIntelligenceEngine()
        self.trading_calendar = TradingCalendar()

        # Callback functions
        self.on_market_close: Optional[Callable] = None
        self.on_pre_market_start: Optional[Callable] = None
        self.on_trading_start: Optional[Callable] = None

        logger.info("Daily Cycle Scheduler initialized with regulatory and market intelligence")

    def start_scheduler(self):
        """Start the daily cycle scheduler."""
        if self.is_running:
            logger.warning("Scheduler already running")
            return

        self.is_running = True
        self.scheduler_thread = threading.Thread(target=self._run_scheduler, daemon=True)
        self.scheduler_thread.start()

        logger.info("Daily Cycle Scheduler started")

    def stop_scheduler(self):
        """Stop the daily cycle scheduler."""
        self.is_running = False
        if self.scheduler_thread:
            self.scheduler_thread.join(timeout=5)
        logger.info("Daily Cycle Scheduler stopped")

    def _run_scheduler(self):
        """Main scheduler loop."""
        logger.info("Scheduler thread started")

        if SCHEDULE_AVAILABLE:
            # Use python-schedule if available
            self._schedule_daily_tasks()
            self._run_with_schedule()
        else:
            # Use basic time-based scheduling
            self._run_basic_scheduler()

        logger.info("Scheduler thread stopped")

    def _run_with_schedule(self):
        """Run scheduler using python-schedule package."""
        import schedule

        while self.is_running:
            try:
                schedule.run_pending()
                time.sleep(60)  # Check every minute
            except Exception as e:
                logger.error(f"Scheduler error: {e}")
                time.sleep(60)

    def _run_basic_scheduler(self):
        """Run basic scheduler without external dependencies."""
        logger.info("Using basic scheduler (no python-schedule package)")

        while self.is_running:
            try:
                now = datetime.now(self.timezone)
                current_time = now.time()

                # Check for scheduled tasks
                self._check_scheduled_tasks(current_time)

                # Sleep for 30 seconds before next check
                time.sleep(30)

            except Exception as e:
                logger.error(f"Basic scheduler error: {e}")
                time.sleep(30)

    def _schedule_daily_tasks(self):
        """Schedule all daily tasks using python-schedule."""
        if not SCHEDULE_AVAILABLE:
            return

        import schedule

        # Market close: 3:30 PM IST
        schedule.every().day.at("15:30").do(self._handle_market_close)

        # System auto-logoff: 4:30 PM IST
        schedule.every().day.at("16:30").do(self._handle_system_logoff)

        # Alternative close time: 5:00 PM IST (backup)
        schedule.every().day.at("17:00").do(self._handle_extended_close)

        # Pre-market preparation: 8:30 AM IST
        schedule.every().day.at("08:30").do(self._handle_pre_market_start)

        # Final trade planning: 9:15 AM IST
        schedule.every().day.at("09:15").do(self._handle_final_trade_planning)

        # Trading start: 9:30 AM IST
        schedule.every().day.at("09:30").do(self._handle_trading_start)

        logger.info("Daily tasks scheduled with python-schedule")

    def _check_scheduled_tasks(self, current_time):
        """Check and execute scheduled tasks using basic time comparison."""
        # Define scheduled times (IST)
        schedules = {
            time(8, 30): self._handle_pre_market_start,
            time(9, 15): self._handle_final_trade_planning,
            time(9, 30): self._handle_trading_start,
            time(15, 30): self._handle_market_close,        # Market close at 3:30 PM
            time(16, 30): self._handle_system_logoff,       # System logoff at 4:30 PM
            time(17, 0): self._handle_extended_close,
        }

        # Check if any scheduled time matches current time (within 1 minute tolerance)
        for scheduled_time, handler in schedules.items():
            if self._time_matches(current_time, scheduled_time, tolerance_minutes=1):
                try:
                    logger.info(f"Executing scheduled task for {scheduled_time}")
                    handler()
                except Exception as e:
                    logger.error(f"Error executing scheduled task: {e}")

    def _time_matches(self, current: time, scheduled: time, tolerance_minutes: int = 1) -> bool:
        """Check if current time matches scheduled time within tolerance."""
        current_minutes = current.hour * 60 + current.minute
        scheduled_minutes = scheduled.hour * 60 + scheduled.minute

        return abs(current_minutes - scheduled_minutes) <= tolerance_minutes

    def _handle_market_close(self):
        """Handle market close at 4:30 PM IST."""
        logger.info("Market close initiated - 4:30 PM IST")

        try:
            # Square off all positions
            self._square_off_all_positions()

            # Process settlements
            self._process_end_of_day_settlements()

            # Generate end-of-day reports
            self._generate_eod_reports()

            # Auto logoff system
            self._system_auto_logoff()

            # Reset for next day
            self._prepare_for_next_day()

            self.market_open = False
            logger.info("Market close completed successfully")

            if self.on_market_close:
                self.on_market_close()

        except Exception as e:
            logger.error(f"Error during market close: {e}")

    def _handle_system_logoff(self):
        """Handle system auto-logoff at 4:30 PM IST."""
        logger.info("System auto-logoff initiated - 4:30 PM IST")

        try:
            # Perform system auto-logoff
            self._system_auto_logoff()

            logger.info("System auto-logoff completed successfully")

        except Exception as e:
            logger.error(f"Error during system auto-logoff: {e}")

    def _skip_trading_day(self, reason: str):
        """Handle non-trading day operations."""
        logger.info(f"Trading operations skipped today: {reason}")

        try:
            # Still perform some basic checks even on non-trading days
            self._check_regulatory_updates()  # Regulatory updates are still important

            # Update system status
            self.system_active = False
            self.pre_market_prepared = False

            # Log the skip reason
            logger.info(f"System will remain idle today due to: {reason}")

        except Exception as e:
            logger.error(f"Error during non-trading day handling: {e}")

    def _handle_extended_close(self):
        """Handle extended close time at 5:00 PM IST."""
        if self.market_open:
            logger.warning("Market still open at 5:00 PM - forcing close")
            self._handle_market_close()

    def _handle_pre_market_start(self):
        """Handle pre-market preparation at 8:30 AM IST."""
        logger.info("Pre-market preparation started - 8:30 AM IST")

        try:
            # Check if today is a trading day
            today = datetime.now(self.timezone).date()
            today_info = self.trading_calendar.get_day_info(today)

            if not today_info.is_trading_day:
                logger.info(f"Today is not a trading day: {today_info.reason}")
                logger.info("Skipping pre-market preparation and trading operations")
                self._skip_trading_day(today_info.reason)
                return

            logger.info(f"Today is a trading day. Market opens at {today_info.market_open_time}, closes at {today_info.market_close_time}")

            # System startup checks
            self._perform_system_startup_checks()

            # Regulatory compliance checks
            self._check_regulatory_updates()

            # Market intelligence gathering
            self._gather_market_intelligence()

            # Risk parameter updates
            self._update_risk_parameters()

            # Capital availability checks
            self._check_capital_availability()

            self.pre_market_prepared = True
            logger.info("Pre-market preparation completed")

            if self.on_pre_market_start:
                self.on_pre_market_start()

        except Exception as e:
            logger.error(f"Error during pre-market preparation: {e}")

    def _handle_final_trade_planning(self):
        """Handle final trade planning at 9:15 AM IST."""
        logger.info("Final trade planning - 9:15 AM IST")

        try:
            # Generate trading plan for the day
            self._generate_daily_trading_plan()

            # Validate broker connections
            self._validate_broker_connections()

            # Final risk assessment
            self._perform_final_risk_assessment()

            logger.info("Final trade planning completed")

        except Exception as e:
            logger.error(f"Error during final trade planning: {e}")

    def _handle_trading_start(self):
        """Handle trading start at 9:30 AM IST."""
        logger.info("Trading session started - 9:30 AM IST")

        try:
            self.market_open = True
            self.system_active = True

            # Start the orchestrator
            self.orchestrator.start_trading_session()

            logger.info("Trading session fully operational")

            if self.on_trading_start:
                self.on_trading_start()

        except Exception as e:
            logger.error(f"Error starting trading session: {e}")

    def _square_off_all_positions(self):
        """Square off all open positions."""
        logger.info("Squaring off all positions")

        try:
            # Get all open positions
            open_positions = self.orchestrator.get_open_positions()

            for position in open_positions:
                try:
                    # Square off each position
                    self.orchestrator.square_off_position(position['id'])
                    logger.info(f"Squared off position: {position['symbol']}")
                except Exception as e:
                    logger.error(f"Error squaring off position {position['symbol']}: {e}")

            logger.info("All positions squared off")

        except Exception as e:
            logger.error(f"Error squaring off positions: {e}")

    def _process_end_of_day_settlements(self):
        """Process end-of-day settlements."""
        logger.info("Processing end-of-day settlements")

        try:
            # Calculate daily P&L
            daily_pnl = self.orchestrator.calculate_daily_pnl()

            # Process settlements
            settlement_result = self.orchestrator.process_daily_settlement()

            # Update user capital
            self.orchestrator.update_user_capital_after_settlement()

            logger.info(f"EOD settlements processed - Daily P&L: ₹{daily_pnl}")

        except Exception as e:
            logger.error(f"Error processing EOD settlements: {e}")

    def _generate_eod_reports(self):
        """Generate end-of-day reports."""
        logger.info("Generating end-of-day reports")

        try:
            # Generate trading performance report
            self.orchestrator.generate_performance_report()

            # Generate settlement report
            self.orchestrator.generate_settlement_report()

            # Generate risk report
            self.orchestrator.generate_risk_report()

            logger.info("EOD reports generated")

        except Exception as e:
            logger.error(f"Error generating EOD reports: {e}")

    def _system_auto_logoff(self):
        """Perform system auto-logoff."""
        logger.info("System auto-logoff initiated")

        try:
            # Stop all trading activities
            self.orchestrator.stop_trading_session()

            # Close broker connections
            self.orchestrator.close_broker_connections()

            # Save system state
            self.orchestrator.save_system_state()

            self.system_active = False
            logger.info("System auto-logoff completed")

        except Exception as e:
            logger.error(f"Error during auto-logoff: {e}")

    def _prepare_for_next_day(self):
        """Prepare system for next trading day."""
        logger.info("Preparing for next trading day")

        try:
            # Reset daily counters
            self.orchestrator.reset_daily_counters()

            # Archive daily logs
            self.orchestrator.archive_daily_logs()

            # Update system status
            self.orchestrator.update_system_status("ready_for_next_day")

            logger.info("System prepared for next trading day")

        except Exception as e:
            logger.error(f"Error preparing for next day: {e}")

    def _perform_system_startup_checks(self):
        """Perform system startup health checks."""
        logger.info("Performing system startup checks")

        checks = [
            ("database", self._check_database_connectivity),
            ("brokers", self._check_broker_connectivity),
            ("market_data", self._check_market_data_feeds),
            ("risk_engine", self._check_risk_engine),
            ("settlement_engine", self._check_settlement_engine),
        ]

        for check_name, check_func in checks:
            try:
                if check_func():
                    logger.info(f"✓ {check_name} check passed")
                else:
                    logger.error(f"✗ {check_name} check failed")
            except Exception as e:
                logger.error(f"Error during {check_name} check: {e}")

    def _check_regulatory_updates(self):
        """Check for regulatory updates from SEBI, NSE, BSE."""
        logger.info("Checking regulatory updates using RegulatoryMonitor")

        try:
            # Use the regulatory monitor to check for updates
            new_updates = self.regulatory_monitor.check_for_updates()

            # Process any critical updates
            critical_updates = self.regulatory_monitor.get_critical_updates()
            if critical_updates:
                self._process_critical_regulatory_updates(critical_updates)

            logger.info(f"Regulatory checks completed - {len(new_updates)} new updates, {len(critical_updates)} critical")

        except Exception as e:
            logger.error(f"Error checking regulatory updates: {e}")

    def _gather_market_intelligence(self):
        """Gather market intelligence from news and announcements."""
        logger.info("Gathering market intelligence using MarketIntelligenceEngine")

        try:
            # Use the market intelligence engine to gather data
            new_events = self.market_intelligence.gather_intelligence()

            # Process high-impact events
            high_impact_events = self.market_intelligence.get_high_impact_events()
            if high_impact_events:
                self._process_high_impact_events(high_impact_events)

            # Get overall market sentiment
            sentiment = self.market_intelligence.get_market_sentiment()
            logger.info(f"Market sentiment: {sentiment['overall']} (confidence: {sentiment['confidence']:.2f})")

            logger.info(f"Market intelligence gathered - {len(new_events)} new events, {len(high_impact_events)} high impact")

        except Exception as e:
            logger.error(f"Error gathering market intelligence: {e}")

    def _check_database_connectivity(self) -> bool:
        """Check database connectivity."""
        try:
            return self.orchestrator.check_database_connection()
        except:
            return False

    def _check_broker_connectivity(self) -> bool:
        """Check broker connectivity."""
        try:
            return self.orchestrator.check_broker_connections()
        except:
            return False

    def _check_market_data_feeds(self) -> bool:
        """Check market data feeds."""
        try:
            return self.orchestrator.check_market_data_feeds()
        except:
            return False

    def _check_risk_engine(self) -> bool:
        """Check risk engine status."""
        try:
            return self.orchestrator.check_risk_engine_status()
        except:
            return False

    def _check_settlement_engine(self) -> bool:
        """Check settlement engine status."""
        try:
            return self.orchestrator.check_settlement_engine_status()
        except:
            return False

    def _check_sebi_circulars(self) -> list:
        """Check SEBI circulars for updates."""
        # Placeholder - would integrate with SEBI API or web scraping
        return []

    def _check_nse_circulars(self) -> list:
        """Check NSE circulars for updates."""
        # Placeholder - would integrate with NSE API or web scraping
        return []

    def _check_bse_circulars(self) -> list:
        """Check BSE circulars for updates."""
        # Placeholder - would integrate with BSE API or web scraping
        return []

    def _check_economic_news(self) -> list:
        """Check economic news that could affect markets."""
        # Placeholder - would integrate with news APIs
        return []

    def _check_corporate_announcements(self) -> list:
        """Check corporate announcements."""
        # Placeholder - would integrate with corporate news APIs
        return []

    def _check_market_events(self) -> list:
        """Check market-moving events."""
        # Placeholder - would integrate with event calendars
        return []

    def _process_critical_regulatory_updates(self, updates: list):
        """Process critical regulatory updates."""
        for update in updates:
            logger.warning(f"Critical regulatory update: {update}")
            # Would trigger system adjustments based on regulatory changes

    def _process_market_intelligence(self, intelligence: list):
        """Process market intelligence."""
        for item in intelligence:
            logger.info(f"Market intelligence: {item}")
            # Would adjust trading strategies based on market conditions

    def _update_risk_parameters(self):
        """Update risk parameters based on market conditions."""
        logger.info("Updating risk parameters")
        # Would adjust risk limits based on volatility, news, etc.

    def _check_capital_availability(self):
        """Check capital availability for trading."""
        logger.info("Checking capital availability")
        # Would verify sufficient capital for planned trades

    def _generate_daily_trading_plan(self):
        """Generate trading plan for the day."""
        logger.info("Generating daily trading plan")
        # Would create optimal trading strategy for the day

    def _validate_broker_connections(self):
        """Validate broker connections before trading."""
        logger.info("Validating broker connections")
        # Would test all broker API connections

    def _perform_final_risk_assessment(self):
        """Perform final risk assessment before trading."""
        logger.info("Performing final risk assessment")
        # Would do final risk checks before market open

    def get_system_status(self) -> Dict[str, Any]:
        """Get current system status."""
        today = datetime.now(self.timezone).date()
        today_info = self.trading_calendar.get_day_info(today)
        market_status = self.trading_calendar.get_market_status()

        return {
            "market_open": self.market_open,
            "system_active": self.system_active,
            "pre_market_prepared": self.pre_market_prepared,
            "scheduler_running": self.is_running,
            "trading_day_today": today_info.is_trading_day,
            "trading_day_reason": today_info.reason,
            "market_open_now": market_status["market_open_now"],
            "next_market_close": "15:30 IST",
            "next_system_logoff": "16:30 IST",
            "next_trading_start": "09:30 IST",
            "next_trading_day": market_status["next_trading_day"],
            "upcoming_holidays": market_status["upcoming_holidays"],
            "timezone": str(self.timezone)
        }
