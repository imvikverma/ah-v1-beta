"""
Trading Calendar for AurumHarmony

Manages trading days, holidays, weekends, and non-trading periods for Indian markets.
Provides functionality to calculate working days and determine market status.
"""

import logging
from datetime import datetime, date, timedelta
from typing import List, Set, Dict, Any, Optional
from dataclasses import dataclass
import calendar
import json
import os

logger = logging.getLogger(__name__)

@dataclass
class TradingDayInfo:
    """Information about a trading day."""
    date: date
    is_trading_day: bool
    reason: str  # Why it's not a trading day
    market_open_time: Optional[str] = None  # Usually 09:15 IST
    market_close_time: Optional[str] = None  # Usually 15:30 IST

class TradingCalendar:
    """
    Comprehensive trading calendar for Indian markets (NSE, BSE).

    Handles:
    - Weekends (Saturday, Sunday)
    - National holidays
    - Market-specific closures
    - Special trading sessions
    - Muhurat trading
    - Settlement holidays
    """

    def __init__(self):
        # Standard market hours (IST)
        self.market_open_time = "09:15"
        self.market_close_time = "15:30"

        # Load holiday data
        self.holidays = self._load_holidays()
        self.special_sessions = self._load_special_sessions()

        logger.info("Trading Calendar initialized")

    def _load_holidays(self) -> Dict[int, Set[date]]:
        """Load holiday data for multiple years."""
        holidays = {}

        # Current year and next year
        current_year = datetime.now().year
        for year in [current_year, current_year + 1]:
            holidays[year] = self._get_holidays_for_year(year)

        return holidays

    def _get_holidays_for_year(self, year: int) -> Set[date]:
        """Get all holidays for a specific year."""
        holidays = set()

        # National Holidays
        national_holidays = [
            (1, 26, "Republic Day"),
            (8, 15, "Independence Day"),
            (10, 2, "Gandhi Jayanti"),
            (12, 25, "Christmas"),
        ]

        for month, day, name in national_holidays:
            try:
                holiday_date = date(year, month, day)
                holidays.add(holiday_date)
                logger.debug(f"Added national holiday: {holiday_date} - {name}")
            except ValueError:
                # Handle invalid dates (e.g., Feb 29 on non-leap years)
                pass

        # Variable holidays (approximate dates, adjust as needed)
        variable_holidays = {
            # Holi (usually March, adjust based on lunar calendar)
            "holi": self._get_holi_date(year),
            # Diwali (usually October/November)
            "diwali": self._get_diwali_date(year),
            # Dussehra (usually September/October)
            "dussehra": self._get_dussehra_date(year),
            # Eid (variable dates)
            "eid_ul_fitr": self._get_eid_date(year),
            # Other major holidays
            "mahashivaratri": self._get_mahashivaratri_date(year),
            "ram_navami": self._get_ram_navami_date(year),
        }

        for holiday_name, holiday_date in variable_holidays.items():
            if holiday_date:
                holidays.add(holiday_date)
                logger.debug(f"Added variable holiday: {holiday_date} - {holiday_name}")

        # Additional market-specific closures
        market_holidays = self._get_market_specific_holidays(year)
        holidays.update(market_holidays)

        return holidays

    def _get_holi_date(self, year: int) -> Optional[date]:
        """Approximate Holi date (adjust based on lunar calendar)."""
        # Holi is typically in March, around Phalguna Purnima
        # This is an approximation - in production, use actual lunar calendar
        try:
            return date(year, 3, 14)  # Approximate
        except:
            return None

    def _get_diwali_date(self, year: int) -> Optional[date]:
        """Approximate Diwali date."""
        try:
            return date(year, 10, 31)  # Approximate
        except:
            return None

    def _get_dussehra_date(self, year: int) -> Optional[date]:
        """Approximate Dussehra date."""
        try:
            return date(year, 10, 24)  # Approximate
        except:
            return None

    def _get_eid_date(self, year: int) -> Optional[date]:
        """Approximate Eid date."""
        try:
            return date(year, 4, 21)  # Approximate
        except:
            return None

    def _get_mahashivaratri_date(self, year: int) -> Optional[date]:
        """Approximate Mahashivaratri date."""
        try:
            return date(year, 3, 8)  # Approximate
        except:
            return None

    def _get_ram_navami_date(self, year: int) -> Optional[date]:
        """Approximate Ram Navami date."""
        try:
            return date(year, 4, 17)  # Approximate
        except:
            return None

    def _get_market_specific_holidays(self, year: int) -> Set[date]:
        """Market-specific holidays and closures."""
        market_holidays = set()

        # Good Friday (varies by year)
        try:
            good_friday = self._calculate_good_friday(year)
            if good_friday:
                market_holidays.add(good_friday)
        except:
            pass

        # Additional closures (banking holidays, etc.)
        additional_closures = [
            # Add more market-specific dates as needed
        ]

        for closure_date in additional_closures:
            try:
                market_holidays.add(closure_date)
            except:
                pass

        return market_holidays

    def _calculate_good_friday(self, year: int) -> Optional[date]:
        """Calculate Good Friday for given year."""
        # Simplified calculation - in production, use proper Easter calculation
        try:
            return date(year, 4, 7)  # Approximate
        except:
            return None

    def _load_special_sessions(self) -> Dict[date, Dict[str, Any]]:
        """Load special trading sessions."""
        # Special sessions like Muhurat trading, early closures, etc.
        return {
            # Example: Muhurat trading on Diwali
            # date(2024, 10, 31): {
            #     "type": "muhurat_trading",
            #     "open_time": "18:00",
            #     "close_time": "19:00",
            #     "description": "Muhurat Trading Session"
            # }
        }

    def is_trading_day(self, check_date: date) -> bool:
        """
        Check if a given date is a trading day.

        Args:
            check_date: Date to check

        Returns:
            True if it's a trading day, False otherwise
        """
        # Check if it's a weekend
        if check_date.weekday() >= 5:  # Saturday = 5, Sunday = 6
            return False

        # Check if it's a holiday
        year_holidays = self.holidays.get(check_date.year, set())
        if check_date in year_holidays:
            return False

        # Check if it's a special closure
        if check_date in self.special_sessions:
            session_info = self.special_sessions[check_date]
            if session_info.get("type") == "market_closed":
                return False

        return True

    def get_day_info(self, check_date: date) -> TradingDayInfo:
        """
        Get detailed information about a specific date.

        Args:
            check_date: Date to get info for

        Returns:
            TradingDayInfo object with details
        """
        if not self.is_trading_day(check_date):
            reason = "Weekend"
            if check_date.weekday() >= 5:
                if check_date.weekday() == 5:
                    reason = "Saturday - Market Closed"
                else:
                    reason = "Sunday - Market Closed"
            else:
                # Check if it's a holiday
                year_holidays = self.holidays.get(check_date.year, set())
                if check_date in year_holidays:
                    reason = "Holiday - Market Closed"
                elif check_date in self.special_sessions:
                    session_info = self.special_sessions[check_date]
                    reason = f"Special Session: {session_info.get('description', 'Market Closed')}"

            return TradingDayInfo(
                date=check_date,
                is_trading_day=False,
                reason=reason
            )

        # It's a trading day
        open_time = self.market_open_time
        close_time = self.market_close_time

        # Check for special sessions
        if check_date in self.special_sessions:
            session_info = self.special_sessions[check_date]
            if "open_time" in session_info:
                open_time = session_info["open_time"]
            if "close_time" in session_info:
                close_time = session_info["close_time"]

        return TradingDayInfo(
            date=check_date,
            is_trading_day=True,
            reason="Regular Trading Day",
            market_open_time=open_time,
            market_close_time=close_time
        )

    def get_next_trading_day(self, from_date: date) -> Optional[date]:
        """
        Get the next trading day from a given date.

        Args:
            from_date: Starting date

        Returns:
            Next trading day date, or None if not found within 30 days
        """
        current_date = from_date + timedelta(days=1)
        max_days = 30  # Don't search more than 30 days ahead

        for i in range(max_days):
            if self.is_trading_day(current_date):
                return current_date
            current_date += timedelta(days=1)

        return None

    def get_previous_trading_day(self, from_date: date) -> Optional[date]:
        """
        Get the previous trading day from a given date.

        Args:
            from_date: Starting date

        Returns:
            Previous trading day date, or None if not found within 30 days
        """
        current_date = from_date - timedelta(days=1)
        max_days = 30  # Don't search more than 30 days back

        for i in range(max_days):
            if self.is_trading_day(current_date):
                return current_date
            current_date -= timedelta(days=1)

        return None

    def get_trading_days_in_range(self, start_date: date, end_date: date) -> List[date]:
        """
        Get all trading days within a date range.

        Args:
            start_date: Start of range (inclusive)
            end_date: End of range (inclusive)

        Returns:
            List of trading day dates
        """
        trading_days = []
        current_date = start_date

        while current_date <= end_date:
            if self.is_trading_day(current_date):
                trading_days.append(current_date)
            current_date += timedelta(days=1)

        return trading_days

    def count_trading_days_in_range(self, start_date: date, end_date: date) -> int:
        """
        Count trading days within a date range.

        Args:
            start_date: Start of range (inclusive)
            end_date: End of range (inclusive)

        Returns:
            Number of trading days
        """
        return len(self.get_trading_days_in_range(start_date, end_date))

    def get_upcoming_holidays(self, days_ahead: int = 30) -> List[Dict[str, Any]]:
        """
        Get upcoming holidays within specified days.

        Args:
            days_ahead: Number of days to look ahead

        Returns:
            List of upcoming holidays with details
        """
        today = date.today()
        end_date = today + timedelta(days=days_ahead)
        upcoming_holidays = []

        current_date = today
        while current_date <= end_date:
            day_info = self.get_day_info(current_date)
            if not day_info.is_trading_day and day_info.reason != "Weekend":
                upcoming_holidays.append({
                    "date": current_date.isoformat(),
                    "reason": day_info.reason,
                    "days_until": (current_date - today).days
                })
            current_date += timedelta(days=1)

        return upcoming_holidays

    def is_market_open_now(self) -> bool:
        """
        Check if market is currently open.

        Returns:
            True if market is open, False otherwise
        """
        now = datetime.now()
        today = now.date()

        # Check if it's a trading day
        if not self.is_trading_day(today):
            return False

        # Get market hours for today
        day_info = self.get_day_info(today)
        if not day_info.market_open_time or not day_info.market_close_time:
            return False

        # Parse times
        try:
            open_time = datetime.strptime(day_info.market_open_time, "%H:%M").time()
            close_time = datetime.strptime(day_info.market_close_time, "%H:%M").time()

            current_time = now.time()

            return open_time <= current_time <= close_time
        except ValueError:
            logger.error(f"Invalid market times: {day_info.market_open_time} - {day_info.market_close_time}")
            return False

    def get_market_status(self) -> Dict[str, Any]:
        """
        Get comprehensive market status.

        Returns:
            Dictionary with market status information
        """
        today = date.today()
        day_info = self.get_day_info(today)

        return {
            "is_trading_day": day_info.is_trading_day,
            "market_open_now": self.is_market_open_now(),
            "reason": day_info.reason,
            "market_open_time": day_info.market_open_time,
            "market_close_time": day_info.market_close_time,
            "next_trading_day": self.get_next_trading_day(today),
            "upcoming_holidays": self.get_upcoming_holidays(7)  # Next 7 days
        }

    def add_holiday(self, holiday_date: date, reason: str):
        """
        Add a custom holiday.

        Args:
            holiday_date: Date of the holiday
            reason: Reason for the holiday
        """
        year = holiday_date.year
        if year not in self.holidays:
            self.holidays[year] = set()

        self.holidays[year].add(holiday_date)
        logger.info(f"Added holiday: {holiday_date} - {reason}")

    def remove_holiday(self, holiday_date: date):
        """
        Remove a holiday.

        Args:
            holiday_date: Date to remove from holidays
        """
        year = holiday_date.year
        if year in self.holidays and holiday_date in self.holidays[year]:
            self.holidays[year].remove(holiday_date)
            logger.info(f"Removed holiday: {holiday_date}")
