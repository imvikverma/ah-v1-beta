# Adaptive Intelligence System Guide

**Created:** December 23, 2025  
**Purpose:** Convert hard trading rules into ML/AI-driven adaptive guidelines

## 🎯 Overview

The Adaptive Intelligence System transforms rigid trading rules into intelligent, ML-driven guidelines that can:

- **Preemptively adjust parameters** based on opportunities
- **Increase/decrease capital allocation** intelligently
- **Modify trade frequency** based on market conditions
- **Save losses to maximum** through early detection
- **Use discretion** where opportunities exist

## 🧠 Core Components

### 1. Adaptive Parameter Engine

Converts hard rules into adaptive guidelines with ML/AI intelligence.

**Key Features:**
- Parameter guidelines (not hard stops)
- AI-driven adjustments based on confidence
- Dynamic min/max bounds
- Opportunity-based scaling

**Parameters Managed:**
- Capital allocation
- Trade frequency (trades per day)
- Position sizes
- VIX-based capacity
- Daily loss limits (can be tightened, never increased)
- Leverage (can be reduced, never increased)

**Example:**
```python
# Base rule: 27 trades/day
# With high opportunity (confidence 0.85): Can increase to 40 trades/day
# With high risk (confidence 0.80): Can reduce to 15 trades/day
```

### 2. Preemptive Risk Manager

Detects and prevents losses before they occur.

**Detection Capabilities:**
- Loss pattern recognition (consecutive losses)
- Volatility spike detection
- Trend reversal early warning
- Declining performance patterns

**Prevention Actions:**
- Reduce exposure (50-70% reduction)
- Reduce trade frequency
- Tighten loss limits
- Pause trading (critical conditions)

## 📊 How It Works

### Step 1: Opportunity Assessment

```python
opportunity_assessment = adaptive_engine.assess_opportunity(
    market_data=market_data,
    signal_confidence=0.85,
    current_pnl=2000.0,
    recent_performance={"win_rate": 0.65, "recent_pnl": 2000.0},
    vix_level=12.0
)
```

**Factors Considered:**
- Signal confidence (30% weight)
- Market volatility/VIX (20% weight)
- Recent performance (20% weight)
- Market trend (15% weight)
- Current PnL status (15% weight)

**Output:**
- Opportunity score (0.0 to 1.0)
- Risk score (0.0 to 1.0)
- Recommended action (INCREASE/DECREASE/MAINTAIN/AVOID)
- Confidence level

### Step 2: Parameter Adjustment

```python
adjusted_params = adaptive_engine.get_all_adjusted_parameters(opportunity_assessment)
```

**Adjustment Logic:**
- High opportunity + Low risk → **INCREASE** parameters (up to 50% increase)
- Low opportunity + High risk → **DECREASE** parameters (up to 50% decrease)
- High risk detected → **AVOID** new positions
- Neutral conditions → **MAINTAIN** current parameters

### Step 3: Preemptive Risk Detection

```python
risk_signal = risk_manager.analyze_trade_pattern(
    recent_trades=trade_history,
    current_pnl=-1500.0,
    market_data=market_data
)
```

**Patterns Detected:**
- 3+ consecutive losses → Moderate risk
- Declining performance trend → Moderate risk
- Increasing loss magnitude → High risk
- Current PnL < -₹3000 → High risk

### Step 4: Loss Prevention Actions

```python
prevention_action = risk_manager.generate_loss_prevention_action(
    risk_signal=risk_signal,
    current_parameters=adjusted_params
)
```

**Actions Generated:**
- **CRITICAL**: Reduce position size by 70%, reduce trades by 50%, tighten loss limit by 30%
- **HIGH**: Reduce position size by 50%, reduce trades by 50%
- **MODERATE**: Reduce position size by 20%, reduce trades by 20%
- **LOW**: Monitor mode, slight reduction

## 🔄 Integration Flow

```
1. Fetch Trading Signals
   ↓
2. Assess Opportunity (Adaptive Engine)
   - Calculate opportunity score
   - Calculate risk score
   - Determine recommended action
   ↓
3. Adjust Parameters (Adaptive Engine)
   - Get adjusted parameter values
   - Apply AI-driven adjustments
   ↓
4. Detect Risk Patterns (Preemptive Risk Manager)
   - Analyze trade patterns
   - Detect volatility spikes
   - Identify loss sequences
   ↓
5. Generate Prevention Actions (Preemptive Risk Manager)
   - Create specific parameter adjustments
   - Determine urgency level
   ↓
6. Apply Final Adjustments
   - Combine opportunity-based and risk-based adjustments
   - Update trading parameters
   ↓
7. Process Signals with Adjusted Parameters
   - Use adaptive limits (not hard stops)
   - Allow AI discretion
   ↓
8. Execute Trades
   - Monitor for early warning signs
   - Adjust in real-time if needed
```

## 🛡️ Safety Limits (Never Exceeded)

Even with adaptive intelligence, these are **hard limits** for safety:

1. **Daily Loss Limit**: Can be tightened, never increased
2. **Leverage**: Can be reduced, never increased
3. **Symbol Restrictions**: Only NIFTY50, BANKNIFTY, SENSEX (never changed)
4. **KYC Compliance**: Always required (never bypassed)

## 📈 Example Scenarios

### Scenario 1: High Opportunity, Low Risk

**Conditions:**
- Signal confidence: 0.90
- VIX: 12 (low volatility)
- Recent win rate: 0.70
- Current PnL: ₹3,000 (profit)
- Market trend: BULLISH

**Result:**
- Opportunity score: 0.85
- Risk score: 0.15
- Action: **INCREASE**
- Adjustments:
  - Trades per day: 27 → 40 (+48%)
  - Position size: ₹1,000 → ₹1,400 (+40%)
  - VIX capacity: 100% → 115% (+15%)

### Scenario 2: Low Opportunity, High Risk

**Conditions:**
- Signal confidence: 0.50
- VIX: 35 (high volatility)
- Recent win rate: 0.40
- Current PnL: -₹2,500 (loss)
- Market trend: BEARISH
- 4 consecutive losses detected

**Result:**
- Opportunity score: 0.30
- Risk score: 0.75
- Action: **DECREASE**
- Adjustments:
  - Trades per day: 27 → 15 (-44%)
  - Position size: ₹1,000 → ₹500 (-50%)
  - VIX capacity: 100% → 50% (-50%)
  - Daily loss limit: ₹5,000 → ₹3,500 (-30%)

### Scenario 3: Critical Loss Prevention

**Conditions:**
- Current PnL: -₹4,500
- 5 consecutive losses
- Increasing loss magnitude
- VIX spike detected

**Result:**
- Risk signal: **CRITICAL**
- Action: **PAUSE TRADING**
- Reason: "Critical loss threshold reached: ₹-4,500"
- Trading paused until conditions improve

## 🎛️ Configuration

### Parameter Guidelines

All parameters have:
- **Base Value**: Starting/default value
- **Current Value**: Currently active value (adjusted by AI)
- **Min Value**: Minimum allowed (typically 50% of base)
- **Max Value**: Maximum allowed (typically 200-500% of base)
- **Confidence Threshold**: Minimum AI confidence to adjust

### Adjustment Factors

- **Confidence-based**: Higher confidence = larger adjustments
- **Direction-based**: INCREASE vs DECREASE
- **Safety-first**: Never increase loss limits or leverage
- **Preemptive**: Adjust before losses occur

## 📊 Monitoring & Logging

All adaptive decisions are logged with:
- Opportunity assessment details
- Parameter adjustments (old → new)
- Risk signals detected
- Prevention actions taken
- Reasoning for each decision

**Log Examples:**
```
INFO: Opportunity assessed: INCREASE (opportunity: 0.85, risk: 0.15, confidence: 0.85)
INFO: Parameter adjusted: trades_per_day 27.00 → 40.00 (+48.1%) [INCREASE, confidence: 0.85]
WARNING: Loss pattern detected: REDUCE_EXPOSURE_HIGH (severity: 0.65, confidence: 0.75)
INFO: Loss prevention action generated: REDUCE_EXPOSURE (urgency: HIGH, impact: Reduce exposure by 50% as precautionary measure)
```

## ✅ Benefits

1. **Intelligent Discretion**: System uses ML/AI to make smart decisions
2. **Preemptive Loss Prevention**: Detects and prevents losses early
3. **Opportunity Maximization**: Increases exposure when opportunities are high
4. **Risk Minimization**: Reduces exposure when risks are high
5. **Adaptive Learning**: System learns from patterns and improves
6. **Flexible Guidelines**: Not rigid rules, but intelligent guidelines

## 🔮 Future Enhancements

- **ML Model Integration**: Use trained models for opportunity assessment
- **Historical Pattern Learning**: Learn from past successful adjustments
- **Real-time Market Data**: Integrate live market feeds for better assessment
- **Multi-factor Analysis**: Add more factors (sector performance, news sentiment, etc.)
- **User-specific Adaptation**: Learn individual user patterns

---

**Status:** ✅ Implemented and Integrated  
**Last Updated:** December 23, 2025
