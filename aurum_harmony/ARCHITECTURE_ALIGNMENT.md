# AurumHarmony Architecture Alignment Document

**Based on:**
1. Implementation Guide Ver 11 (05 Dec 2025)
2. rules.md (Final v1.0 Beta - 28 Nov 2025)
3. requirements.md (to be located/added)

**Purpose:** Ensure all implementations align with the complete vision across all three documents.

---

## ✅ Fund Push/Pull Direction (CORRECTED)

### Definition (Per User Clarification)
- **PUSH**: Demat → Savings (withdraw from trading account, move to savings)
- **PULL**: Savings → Demat (deposit to trading account, move from savings)

### Typical Schedule (Implementation Guide Ver 11)
- **09:15**: PULL (Savings → Demat) - Fund trading account for the day
- **15:25**: PUSH (Demat → Savings) - Move profits back to savings

### Implementation Status
- ✅ `FundPushPullEngine.push_funds()` - Correctly implements Demat → Savings
- ✅ `FundPushPullEngine.pull_funds()` - Correctly implements Savings → Demat
- ✅ `increment_capital()` - Uses PULL (Savings → Demat) for capital increments
- ✅ Settlement integration - Uses PUSH (Demat → Savings) for net profit

---

## 📋 User Categories & Increment Levels

### From rules.md:
1. **NGD** (Funded & Restricted)
   - Initial: ₹5,000
   - Increment: None (cyclical reset)
   - Max accounts: 1
   - ZPT Fee: 15%

2. **Restricted / Semi-Restricted** (Alpha-Beta + White-Label)
   - Initial: ₹10,000
   - Increment levels: → ₹50,000 → ₹1,00,000
   - Max accounts: 2
   - ZPT Fee: 30% → 12.5%

3. **Unrestricted Admin** (owner + companies)
   - Initial: ₹10,000
   - Increment levels: → ₹50K → ₹1L → ₹5L → ₹15L
   - Max accounts: 6+

### Implementation Status
- ✅ `IncrementEngine.LEVELS` matches rules.md exactly
- ✅ NGD has no increment (cyclical only)
- ✅ Admin has 5 levels (₹10K → ₹50K → ₹1L → ₹5L → ₹15L)

---

## 🎯 VIX-Based Dynamic Scaling

### From Implementation Guide Ver 11:
| VIX    | Capacity | Max Trades/Account/Day | Target Return |
|--------|----------|------------------------|---------------|
| <15    | 100%     | 180                    | 10–18%        |
| 15–20  | 75%      | 135                    | 8–12%         |
| 20–30  | 50%      | 90                     | 5–8%          |
| >30    | 50%      | 90                     | ≤5%           |

### From rules.md:
- VIX <15: 100% capacity, 10% target return, 60–66% win rate
- VIX 15–20: 75% capacity, 8% target return, 55–60% win rate
- VIX 20–30: 50% capacity, 7% target return, 50–55% win rate
- VIX >30: 50% capacity, 5% target return, 45–50% win rate

### Implementation Status
- ✅ `PredictiveAIEngine._apply_vix_adjustment()` - Basic VIX adjustment implemented
- ⚠️ **TODO**: Add max trades per day cap based on VIX
- ⚠️ **TODO**: Add target return adjustment based on VIX
- ⚠️ **TODO**: Add win rate expectations based on VIX

---

## 🔒 SEBI Compliance

### From Implementation Guide Ver 11:
- Max exposure: ₹50,00,000 per user
- Max lots per order: 250
- Large orders automatically split — never halt trading

### From rules.md:
- Max exposure: ₹50 lakh
- Max lots: 1,250
- Daily SEBI/NSE/BSE scrape 08:30–09:00 IST

### Implementation Status
- ✅ `ComplianceEngine.check_trade_compliance()` - Basic compliance checks
- ✅ Position limit validation
- ⚠️ **TODO**: Dynamic order splitting (>250 lots)
- ⚠️ **TODO**: Daily SEBI/NSE/BSE scraping (08:30–09:00 IST)

---

## 💰 Settlement & Revenue Split

### From rules.md:
**Beta Phase:**
- Platform: 30%
- SaffronBolt: 70% of net fee
- ZenithPulse: 30% of net fee
- NGD: 10% fee, cyclical ₹5,000 reset, no increment

**Post-Beta:**
- Platform: 12%
- SaffronBolt: 85% of net fee
- ZenithPulse: 15% of net fee

**Settlement & Transfer:**
- EOD settlement
- Net profit transferred to savings (PUSH: Demat → Savings)
- Rounding amount + buffer stays in demat
- 39% tax lock into savings

**Rounding Rule (by subtraction, balance stays in demat):**
- ≥₹1,00,000 → nearest ₹10,000
- ≥₹10,00,000 → nearest ₹1,00,000
- ≥₹1,00,00,000 → nearest ₹10,00,000

### Implementation Status
- ✅ `SettlementEngine.settle()` - Implements fee split correctly
- ✅ `SettlementEngine._round_down_per_rules()` - Implements rounding rules
- ✅ Tax lock (39%) implemented
- ✅ Buffer stays in demat (correctly handled)

---

## 🚀 Eight Golden Guardrails

### From Implementation Guide Ver 11:
1. **Predictive AI** — Hybrid RandomForest + LSTM, 15-min signal, >70% confidence
2. **ML Training** — Weekly retrain on 30-day data
3. **Compliance** — Real-time SEBI checks + dynamic order splitting
4. **Fund Push/Pull** — 09:15/15:25 via Razorpay + IMPS
5. **Trade Execution** — 5-min HFT, max 4 trades per 15-min cycle
6. **Settlement** — EOD with 39% tax lock + rounding buffer
7. **Reporting** — Daily/weekly/annual with Hyperledger hash
8. **Notifications** — Max 5/day, tiered alerts

### Implementation Status

1. ✅ **Predictive AI** - Framework implemented, ML models pending
2. ⚠️ **ML Training** - Not yet implemented (weekly retrain on 30-day data)
3. ✅ **Compliance** - Basic checks implemented, order splitting pending
4. ✅ **Fund Push/Pull** - Engine implemented, scheduled timing pending
5. ✅ **Trade Execution** - Full implementation with HFT support
6. ✅ **Settlement** - Complete implementation
7. ✅ **Reporting** - Framework implemented
8. ✅ **Notifications** - Multi-channel implementation, max 5/day pending

---

## ⏰ Timing Architecture

### From Implementation Guide Ver 11:
- **15-minute AI directional cycle** - Predictive AI generates signals every 15 minutes
- **5-minute HFT execution layer** - Executes trades in 5-minute windows
- **Max 4 trades per 15-min cycle** - Trade limit per cycle

### Implementation Status
- ⚠️ **TODO**: Implement 15-minute scheduler for AI signals
- ⚠️ **TODO**: Implement 5-minute HFT execution windows
- ⚠️ **TODO**: Enforce max 4 trades per 15-minute cycle

---

## 📊 Trading Simulations (22-Day)

### From Implementation Guide Ver 11:
| Category                     | Starting Capital | Trades/Day | Monthly Net Profit | Annual Net (12×) |
|------------------------------|------------------|------------|--------------------|------------------|
| NGD (cyclical)               | ₹5,000           | 18         | ₹58,500            | ₹7,02,000        |
| Restricted (30% fee)         | ₹10,000          | 27         | ₹2,16,000          | ₹25,92,000       |
| Semi-Restricted (12.5% fee)  | ₹10,000          | 27         | ₹2,70,000          | ₹32,40,000       |
| Admin (Level 4 — ₹5L)        | ₹5,00,000        | 180        | ₹18,00,000+        | ₹2,16,00,000+    |

### Implementation Status
- ✅ Capital levels match
- ✅ Fee percentages match
- ⚠️ **TODO**: Validate trades/day limits per category
- ⚠️ **TODO**: Validate expected returns match simulations

---

## 🔐 Fund Transfer Rules (UPI-Safe Architecture)

### From rules.md:
**Flow:** User Savings ↔ Broker Nodal ↔ Trading ↔ Demat

**Key Rule:** Demat accounts NEVER directly linked to UPI — 100% SEBI-compliant.

**Daily Limits & Workarounds:**
- Push: Split >₹1L via Razorpay + IMPS fallback
- Pull: No limit (IMPS/RTGS)
- Primary: Razorpay (₹5L+ daily)
- Fallback: PhonePe / GPay / IMPS

### Implementation Status
- ✅ Fund engine supports push/pull operations
- ⚠️ **TODO**: Integrate Razorpay API
- ⚠️ **TODO**: Implement >₹1L splitting logic
- ⚠️ **TODO**: Add IMPS/RTGS fallback

---

## 🏗️ Core Parameters (Per User)

### From rules.md:
- Starting Capital: ₹10,000 (Tier 2+) | ₹5,000 (NGD only)
- Leverage: 3× (all tiers except NGD 1.5×)
- Trades/Day: 27–180 (scales with tier & VIX)
- Initial Capital Progression: ₹10K → ₹1L → ₹2.5L → ₹7.5L → ₹15L
- Accounts: 1–6 (scales with tier, clubbed during progression)

### Implementation Status
- ✅ Starting capital matches
- ⚠️ **TODO**: Implement leverage multiplier (3× for most, 1.5× for NGD)
- ✅ Trades/day scaling framework exists
- ✅ Capital progression matches
- ✅ Account limits per category

---

## 📝 Next Steps (Priority Order)

### High Priority (Core Functionality)
1. ✅ **Fund Push/Pull Direction** - FIXED
2. ⚠️ **15-minute/5-minute Timing** - Implement scheduler
3. ⚠️ **Dynamic Order Splitting** - Add >250 lots splitting
4. ⚠️ **VIX Max Trades Cap** - Enforce daily limits based on VIX

### Medium Priority (Enhanced Features)
5. ⚠️ **ML Training Engine** - Weekly retrain on 30-day data
6. ⚠️ **Razorpay Integration** - Fund transfer API
7. ⚠️ **SEBI/NSE/BSE Scraping** - Daily compliance updates
8. ⚠️ **Notification Limits** - Max 5/day enforcement

### Low Priority (Optimization)
9. ⚠️ **Target Return Adjustment** - VIX-based return targets
10. ⚠️ **Win Rate Tracking** - VIX-based win rate expectations

---

## 🎯 System Scope (CRITICAL)

### From User Clarification:
**STRICTLY an Intraday Options Trading System:**
- **Exchanges**: NSE & BSE only
- **Symbols**: NIFTY50, BANKNIFTY, SENSEX (to start with)
- **Focus**: Low premium options
- **NO individual stocks** - All retail individual stock trades are REJECTED

### Implementation Status
- ✅ `ComplianceEngine._is_symbol_restricted()` - Enforces allowed symbols only
- ✅ `ComplianceEngine.check_trade_compliance()` - Validates symbols before trade
- ✅ `PredictiveAIEngine` - Documented to only generate signals for allowed symbols
- ✅ `TradeExecutor.execute_order()` - Documented symbol restrictions
- ✅ All engines updated with intraday options scope

### Allowed Symbols
- **NIFTY50** (NSE) - Index options
- **BANKNIFTY** (NSE) - Index options
- **SENSEX** (BSE) - Index options

### Rejected Symbols
- ❌ All individual stocks (RELIANCE, TCS, INFY, etc.)
- ❌ Other indices not in allowed list
- ❌ Futures (options only)
- ❌ Delivery trades (intraday only)

---

## ✅ Verification Checklist

- [x] Fund Push/Pull direction corrected
- [x] User categories match rules.md
- [x] Increment levels match rules.md
- [x] Settlement fee split matches rules.md
- [x] Rounding rules match rules.md
- [x] Tax lock (39%) implemented
- [x] **Symbol restrictions enforced (NIFTY50, BANKNIFTY, SENSEX only)**
- [x] **Individual stocks rejection implemented**
- [ ] 15-minute/5-minute timing architecture
- [ ] Dynamic order splitting
- [ ] VIX-based max trades cap
- [ ] ML Training engine
- [ ] Razorpay integration
- [ ] SEBI/NSE/BSE scraping

---

**Last Updated:** 2025-12-08  
**Status:** Core alignment verified, timing and advanced features pending

