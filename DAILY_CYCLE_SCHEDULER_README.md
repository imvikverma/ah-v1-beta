# AurumHarmony Daily Cycle Scheduler

## Overview

The Daily Cycle Scheduler automates the complete daily trading cycle for AurumHarmony, ensuring hands-free operation from user login to system logoff. This addresses the requirement for the system to auto-log off at 4:30-5:00 PM after settlements and restart operations at 8:30 AM.

## Daily Trading Cycle

### 3:30 PM IST - Market Close
- **Square off all positions** - Close any remaining open positions
- **Process settlements** - Calculate and process end-of-day settlements
- **Generate reports** - Create performance, settlement, and risk reports
- **Prepare for logoff** - System prepares for shutdown

### 4:30 PM IST - System Auto Logoff
- **Auto logoff** - System automatically shuts down all operations
- **Data archiving** - Archive logs and system state
- **Connection cleanup** - Close all broker and data connections
- **System shutdown** - Complete system shutdown

### 8:30 AM IST - Pre-Market Preparation
- **System health checks** - Verify database, brokers, market data feeds
- **Regulatory compliance** - Check SEBI, NSE, BSE circulars for changes
- **Market intelligence** - Gather news, corporate announcements, economic data
- **Risk parameter updates** - Adjust based on market conditions and news
- **Capital verification** - Ensure sufficient capital for planned trades

### 9:15 AM IST - Final Trade Planning
- **Strategy generation** - Create optimal trading plan for the day
- **Connection validation** - Test all broker API connections
- **Risk assessment** - Final risk checks before market open

### 9:30 AM IST - Trading Session Start
- **Market open** - Activate trading operations
- **Orchestrator start** - Begin signal processing and order execution
- **Real-time monitoring** - Continuous market and risk monitoring

## System Components

### 1. Daily Cycle Scheduler (`daily_cycle_scheduler.py`)
Core scheduler that manages the daily timeline and coordinates all operations.

**Key Features:**
- Automated task scheduling using python-schedule
- IST timezone handling
- Graceful error handling and recovery
- System state management

### 2. Regulatory Monitor (`regulatory_monitor.py`)
Monitors regulatory updates from SEBI, NSE, and BSE.

**Monitored Sources:**
- SEBI circulars and notifications
- NSE corporate filings and announcements
- BSE regulatory updates and notices

**Impact Assessment:**
- High: Trading halts, circuit breakers, margin changes
- Medium: New disclosure requirements, reporting changes
- Low: Administrative updates, procedural changes

### 3. Market Intelligence Engine (`market_intelligence.py`)
Gathers and analyzes market-moving information.

**Data Sources:**
- Financial news feeds (Reuters, Bloomberg, Moneycontrol)
- Corporate announcements (NSE, BSE)
- Economic indicators and events
- Social sentiment analysis (future enhancement)

**Intelligence Processing:**
- Sentiment analysis (positive/negative/neutral)
- Impact assessment (high/medium/low)
- Symbol correlation and affected securities identification

## User Experience

### For Traders
1. **Login at 8:30 AM** - User simply logs into the app
2. **System handles everything** - No manual intervention required
3. **Real-time monitoring** - View system status and performance
4. **Automatic logoff** - System safely shuts down at 4:30 PM IST

### For Administrators
- **Pre-market verification** - Check system readiness at 8:30 AM
- **Real-time monitoring** - Track regulatory changes and market events
- **Manual overrides** - Emergency stop/start capabilities
- **Post-market review** - Comprehensive end-of-day reports

## API Endpoints

### Scheduler Management
```
POST /api/scheduler/start    - Start the daily cycle scheduler
GET  /api/scheduler/status   - Get current scheduler status
POST /api/scheduler/stop     - Stop the daily cycle scheduler
```

### System Status
```
GET /api/system/health       - Overall system health check
GET /api/system/pre-market   - Pre-market preparation status
GET /api/regulatory/updates  - Recent regulatory updates
GET /api/intelligence/events - Market intelligence events
```

## Configuration

### Environment Variables
```bash
# Scheduler Settings
DAILY_SCHEDULER_TIMEZONE=Asia/Kolkata
SCHEDULER_AUTO_START=true

# Regulatory Monitoring
REGULATORY_CHECK_INTERVAL=3600  # 1 hour
REGULATORY_CRITICAL_KEYWORDS=trading halt,circuit breaker,margin

# Market Intelligence
NEWS_FEED_UPDATE_INTERVAL=1800  # 30 minutes
INTELLIGENCE_SOURCES=reuters,bloomberg,moneycontrol
```

### Risk Adjustments Based on Intelligence

The system automatically adjusts risk parameters based on gathered intelligence:

- **High Impact Events**: Reduce position sizes by 50%, increase stop-losses
- **Negative Sentiment**: Conservative position sizing, tighter risk limits
- **Regulatory Changes**: Adjust strategies to comply with new requirements
- **Market Volatility**: Dynamic risk parameter adjustment

## Safety Features

### Auto Logoff Protection
- Position squaring with slippage protection
- Settlement verification before logoff
- Data persistence and backup
- Emergency override capabilities

### Regulatory Compliance
- Automatic strategy adjustments for regulatory changes
- Compliance reporting and documentation
- Audit trail maintenance

### System Monitoring
- Health checks every 5 minutes during trading hours
- Automatic restart on component failures
- Alert system for critical issues

## Integration Points

### With Orchestrator
- Receives trading session start/stop commands
- Provides market intelligence for signal generation
- Supplies regulatory context for risk management

### With Risk Engine
- Dynamic risk parameter updates based on intelligence
- Regulatory compliance enforcement
- Market condition-based adjustments

### With Settlement Engine
- End-of-day settlement processing
- Capital updates and transfers
- Performance calculations

## Monitoring and Alerts

### System Alerts
- Pre-market preparation completion
- Regulatory update notifications
- Critical market event warnings
- System health issues

### Administrative Alerts
- Daily performance summaries
- Regulatory compliance reports
- System maintenance notifications
- Emergency situation alerts

## Future Enhancements

### Advanced Features
- **Predictive Analytics**: ML-based market event prediction
- **Multi-Timezone Support**: Global market operations
- **Advanced NLP**: Enhanced news analysis and sentiment
- **Blockchain Integration**: Immutable audit trails

### Additional Intelligence Sources
- **Social Media Monitoring**: Twitter, Reddit sentiment analysis
- **Options Flow Analysis**: Institutional positioning insights
- **Global Market Correlation**: International market impact assessment
- **Weather & Geopolitical Events**: Broader market influence factors

## Testing

Run the test suite to verify scheduler functionality:

```bash
python test_daily_scheduler.py
```

This tests:
- Scheduler initialization and configuration
- Regulatory monitor functionality
- Market intelligence gathering
- Orchestrator integration methods
- System status reporting

## Troubleshooting

### Common Issues

**Scheduler Not Starting**
- Check system timezone settings
- Verify python-schedule package installation
- Check file permissions for log archiving

**Regulatory Updates Not Loading**
- Verify internet connectivity
- Check if regulatory websites have changed structure
- Review error logs for scraping issues

**Market Intelligence Empty**
- Confirm RSS feed URLs are accessible
- Check news source API keys if required
- Verify network connectivity to news sources

### Emergency Procedures

**Manual System Stop**
```bash
POST /api/scheduler/stop
```

**Force Position Close**
```bash
POST /api/trading/square-all-positions
```

**System Reset**
```bash
POST /api/system/reset-daily-state
```

## Conclusion

The Daily Cycle Scheduler transforms AurumHarmony from a manual trading system into a fully automated, intelligent trading platform. By handling the complete daily cycle automatically, it ensures:

- **Reliability**: Consistent, error-free daily operations
- **Compliance**: Automatic regulatory monitoring and adaptation
- **Intelligence**: Real-time market awareness and strategy adjustment
- **Safety**: Automated risk management and position protection
- **Efficiency**: Hands-free operation with minimal user intervention

This creates a truly autonomous trading system that operates 24/7 while maintaining the highest standards of safety, compliance, and performance.
