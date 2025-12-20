# AurumHarmony Trading Calendar

## Overview

The Trading Calendar system provides comprehensive handling of weekends, holidays, and non-trading days for Indian markets (NSE/BSE). It ensures AurumHarmony only operates on valid trading days and can calculate exact working days for trading operations.

## Features

### ✅ Weekend Detection
- Automatically detects Saturdays and Sundays
- Prevents system startup on weekends
- Logs appropriate skip messages

### ✅ Holiday Management
- Pre-configured national holidays (Republic Day, Independence Day, Gandhi Jayanti, Christmas)
- Variable holidays (Holi, Diwali, Dussehra, Eid, Mahashivaratri, Ram Navami)
- Market-specific closures and special sessions
- Custom holiday addition/removal

### ✅ Trading Day Calculations
- Determine if any date is a trading day
- Count trading days within date ranges
- Find next/previous trading days
- Calculate exact working days for capital allocation

### ✅ Market Status Monitoring
- Real-time market open/closed status
- Current trading session information
- Upcoming holidays and closures

## Holiday Calendar

### Fixed National Holidays
- **January 26**: Republic Day
- **August 15**: Independence Day
- **October 2**: Gandhi Jayanti
- **December 25**: Christmas

### Variable Religious Holidays
- **Holi**: March (lunar calendar based)
- **Mahashivaratri**: March
- **Ram Navami**: April
- **Eid**: April/May
- **Diwali**: October/November
- **Dussehra**: September/October

### Special Market Events
- **Muhurat Trading**: Diwali evening session
- **Early Closures**: Special market closures
- **Bank Holidays**: Additional banking sector closures

## API Endpoints

### Market Status
```http
GET /api/calendar/status
```
Returns current market status including:
- Is today a trading day?
- Market open/closed status
- Next trading day
- Upcoming holidays

### Trading Day Check
```http
GET /api/calendar/is-trading-day?date=2025-01-26
```
Check if a specific date is a trading day.

### Trading Days Calculation
```http
GET /api/calendar/trading-days?start_date=2025-01-01&end_date=2025-01-31
```
Calculate exact number of trading days in a date range.

### Upcoming Holidays
```http
GET /api/calendar/holidays?days_ahead=30
```
Get list of upcoming holidays and non-trading days.

## Usage Examples

### Check if Today is Trading Day
```python
from aurum_harmony.engines.scheduling.trading_calendar import TradingCalendar

calendar = TradingCalendar()
today_info = calendar.get_day_info(date.today())

if today_info.is_trading_day:
    print(f"Market opens at {today_info.market_open_time}")
else:
    print(f"No trading today: {today_info.reason}")
```

### Calculate Trading Days
```python
# Count trading days in a month
start_date = date(2025, 1, 1)
end_date = date(2025, 1, 31)

trading_days = calendar.get_trading_days_in_range(start_date, end_date)
print(f"January 2025 has {len(trading_days)} trading days")
```

### Get Next Trading Day
```python
next_day = calendar.get_next_trading_day(date.today())
if next_day:
    print(f"Next trading day: {next_day}")
```

## Integration with Daily Scheduler

The trading calendar is fully integrated with the Daily Cycle Scheduler:

### Pre-Market Checks
- **Trading Day Validation**: System checks if today is a trading day before starting preparation
- **Holiday Detection**: Skips all operations on holidays and weekends
- **Market Hours**: Uses correct market open/close times for the day

### System Behavior
- **Trading Days**: Full pre-market preparation and trading operations
- **Non-Trading Days**: Skips preparation, logs reason, remains idle
- **Holiday Awareness**: Regulatory updates still monitored even on non-trading days

## Holiday Management

### Adding Custom Holidays
```python
from datetime import date
calendar.add_holiday(date(2025, 12, 31), "New Year's Eve")
```

### Removing Holidays
```python
calendar.remove_holiday(date(2025, 1, 26))  # Would remove Republic Day
```

## Market Hours Configuration

### Standard Hours
- **Market Open**: 09:15 IST
- **Market Close**: 15:30 IST
- **System Logoff**: 16:30 IST

### Special Sessions
- **Muhurat Trading**: 18:00 - 19:00 IST (Diwali)
- **Early Closures**: Adjusted close times for special events

## Testing

Run the comprehensive test suite:

```bash
python test_trading_calendar.py
```

This tests:
- Weekend detection accuracy
- Holiday recognition
- Trading day calculations
- Scheduler integration
- API endpoint functionality

## Data Sources

### Primary Data
- Pre-configured holiday calendar for Indian markets
- Standard weekend detection (Sat-Sun)
- Market-specific closure rules

### Future Enhancements
- **Live Holiday Feed**: Integration with NSE/BSE holiday APIs
- **Real-time Updates**: Dynamic holiday announcements
- **International Markets**: Support for global market calendars
- **Corporate Actions**: Integration with corporate action calendars

## Error Handling

### Graceful Degradation
- Missing dependencies don't break core functionality
- Fallback to basic calendar if advanced features unavailable
- Comprehensive logging for troubleshooting

### Validation
- Date range validation for API calls
- Holiday date verification
- Market hours sanity checks

## Performance

### Caching
- Holiday data cached by year
- Frequent calculations optimized
- Minimal memory footprint

### Speed
- Sub-millisecond responses for status checks
- Fast range calculations for large date spans
- Efficient holiday lookups

## Compliance

### Regulatory Requirements
- Accurate holiday and trading day calculations
- Proper handling of market closures
- Audit trail for non-trading day decisions

### Risk Management
- Prevents trading on non-trading days
- Reduces operational risk from calendar errors
- Ensures compliance with exchange regulations

## Configuration

### Environment Variables
```bash
# Trading Calendar Settings
MARKET_TIMEZONE=Asia/Kolkata
HOLIDAY_UPDATE_INTERVAL=86400  # 24 hours

# Market Hours
MARKET_OPEN_TIME=09:15
MARKET_CLOSE_TIME=15:30
SYSTEM_LOGOFF_TIME=16:30
```

### Customization
- Holiday calendar can be modified for different markets
- Market hours adjustable for different exchanges
- Custom holiday rules for special requirements

## Monitoring

### System Status
The trading calendar status is included in system health checks:

```json
{
  "trading_day_today": true,
  "trading_day_reason": "Regular Trading Day",
  "market_open_now": false,
  "next_trading_day": "2025-12-22",
  "upcoming_holidays": [...]
}
```

### Alerts
- Non-trading day notifications
- Upcoming holiday warnings
- Market status changes

## Future Roadmap

### Advanced Features
- **Machine Learning**: Predict potential market closures
- **Real-time Feeds**: Live holiday announcement integration
- **Multi-Market**: Support for international market calendars
- **Corporate Calendar**: Integration with earnings and event calendars

### API Enhancements
- **Bulk Operations**: Calculate trading days for multiple ranges
- **Calendar Export**: Generate calendar files for external systems
- **Notification Webhooks**: Real-time alerts for calendar changes

## Conclusion

The Trading Calendar system transforms AurumHarmony into a truly market-aware trading platform that:

- **Respects Market Hours**: Only operates during valid trading sessions
- **Handles All Closures**: Weekends, holidays, special events
- **Calculates Accurately**: Exact working day calculations for all operations
- **Maintains Compliance**: Full regulatory and exchange compliance
- **Provides Intelligence**: Market status awareness for better decision making

This ensures AurumHarmony operates efficiently, safely, and in full compliance with Indian market regulations while maximizing trading opportunities on valid trading days.
