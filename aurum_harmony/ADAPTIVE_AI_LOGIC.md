# AurumHarmony Adaptive AI-Driven Logic

**Date:** 2025-12-08  
**Philosophy:** Intelligent, adaptive system - not rigid rules

---

## 🧠 Core Philosophy

**All formulae and limits are INDICATIVE GUIDELINES, not hard rules.**

The Predictive AI makes intelligent decisions to:
- ✅ **Exceed** recommended limits when conditions are favorable
- ✅ **Reduce** below recommended limits when conditions are risky
- ✅ **Adapt** based on signal confidence, market conditions, and risk assessment

---

## 📊 VIX-Based Guidelines (Indicative)

### Indicative Capacity Guidelines:
| VIX    | Indicative Capacity | Indicative Max Trades/Day | Target Return |
|--------|---------------------|---------------------------|---------------|
| <15    | ~100%               | ~180                      | 10–18%        |
| 15–20  | ~75%                | ~135                      | 8–12%         |
| 20–30  | ~50%                | ~90                       | 5–8%          |
| >30    | ~50%                | ~90                       | ≤5%           |

**Key Point:** These are STARTING POINTS. The AI adjusts based on:
- Signal confidence levels
- Market volatility
- Risk metrics
- Historical performance

---

## 🤖 AI Decision Logic

### When AI Can EXCEED Guidelines:
1. **High Confidence Signals (>80%)**
   - AI can exceed VIX capacity by up to 20%
   - Can exceed max trades/day by up to 20%
   - Example: VIX 20 (guideline: 90 trades) → AI allows up to 108 trades if confidence >80%

2. **Favorable Market Conditions**
   - Low volatility
   - Strong trend signals
   - High win rate in recent trades

3. **Risk Assessment**
   - Daily loss limit not approached
   - Position sizes within safety margins
   - Diversification maintained

### When AI Should REDUCE Below Guidelines:
1. **Low Confidence Signals (<50%)**
   - AI reduces capacity by 30% below guideline
   - Example: VIX 15 (guideline: 135 trades) → AI limits to ~95 trades if confidence <50%

2. **Risky Market Conditions**
   - High volatility (>30%)
   - Uncertain market direction
   - Recent losses approaching daily limit

3. **Risk Warnings**
   - Approaching daily loss limit
   - Position concentration risk
   - Market anomalies detected

---

## 🎯 Adaptive Capacity Calculation

### Method: `get_adaptive_trade_capacity()`

**Inputs:**
- VIX value
- Current trades today
- Average signal confidence
- Market conditions

**Outputs:**
- Recommended max (from VIX guideline)
- Adaptive max (AI decision)
- Capacity multiplier (how much above/below guideline)
- Per-index allocation (NIFTY50, BANKNIFTY, SENSEX)
- Decision reason

**Example Scenarios:**

**Scenario 1: High Confidence, Low VIX**
```
VIX: 12
Guideline: 180 trades/day
Current: 150 trades
Avg Confidence: 0.85

AI Decision: EXCEED
Adaptive Max: 216 trades (180 × 1.2)
Reason: "High confidence signals (85%) justify exceeding VIX guideline"
```

**Scenario 2: Low Confidence, High VIX**
```
VIX: 25
Guideline: 90 trades/day
Current: 50 trades
Avg Confidence: 0.45

AI Decision: REDUCE
Adaptive Max: 63 trades (90 × 0.7)
Reason: "Low confidence signals (45%) suggest reducing below VIX guideline"
```

**Scenario 3: Normal Conditions**
```
VIX: 18
Guideline: 135 trades/day
Current: 100 trades
Avg Confidence: 0.70

AI Decision: FOLLOW GUIDELINE
Adaptive Max: 135 trades
Reason: "Normal confidence, following VIX guideline"
```

---

## 📈 Per-Index Allocation

The AI intelligently distributes trades across indices:

**Default Allocation:**
- NIFTY50: ~40%
- BANKNIFTY: ~40%
- SENSEX: ~20%

**Adaptive Allocation:**
- AI can adjust based on:
  - Signal quality per index
  - Market conditions per index
  - Historical performance per index
  - Risk concentration

**Example:**
```
Adaptive Max: 135 trades
Index Allocation:
  - NIFTY50: 54 trades (40% - strong signals)
  - BANKNIFTY: 54 trades (40% - strong signals)
  - SENSEX: 27 trades (20% - moderate signals)
```

---

## 🔄 Integration Flow

### 1. Signal Generation (PredictiveAIEngine)
```
AI generates signals with confidence scores
↓
VIX adjustment applied (indicative guideline)
↓
AI adjusts based on confidence (can exceed/reduce)
↓
Signals passed to orchestrator
```

### 2. Capacity Decision (PredictiveAIEngine)
```
Calculate adaptive capacity:
- Get VIX guideline
- Assess signal confidence
- Evaluate market conditions
↓
Return adaptive capacity info
```

### 3. Risk Check (SimpleRiskEngine)
```
Receive signal + AI capacity info
↓
Check hard limits (daily loss - NEVER exceed)
↓
Check adaptive limits (can exceed with AI approval)
↓
Approve or defer trade
```

### 4. Execution (TradeExecutor)
```
Execute approved trades
↓
Track daily trade count
↓
Update AI capacity calculations
```

---

## 🛡️ Hard Limits (Never Exceed)

These are SAFETY limits that AI cannot override:

1. **Daily Loss Limit**
   - Hard stop at configured max daily loss
   - Never exceeded, regardless of AI confidence

2. **Position Size Limit**
   - Maximum position value per symbol
   - Safety limit for risk management

3. **Symbol Restrictions**
   - Only NIFTY50, BANKNIFTY, SENSEX allowed
   - Never trade individual stocks

---

## 📊 Monitoring & Logging

All AI decisions are logged with:
- VIX guideline value
- AI decision (exceed/reduce/follow)
- Adaptive capacity
- Decision reason
- Signal confidence
- Market conditions

This enables:
- Performance analysis
- Decision quality assessment
- System tuning
- Audit trail

---

## ✅ Benefits of Adaptive Approach

1. **Intelligent Flexibility**
   - Not locked into rigid rules
   - Responds to market conditions
   - Maximizes opportunities in favorable conditions
   - Reduces risk in unfavorable conditions

2. **AI-Driven Optimization**
   - Learns from signal quality
   - Adapts to market volatility
   - Optimizes trade allocation

3. **Safety with Intelligence**
   - Hard limits for safety
   - Adaptive limits for optimization
   - Best of both worlds

---

**The system is now truly adaptive and AI-driven!** 🚀

