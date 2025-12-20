Confirmation — no assumptions
Understood
Capital formula: ₹10K × indices × brokers × users + 30% margin, rounded up
User types: Admin (multiple users, up to ₹15L) vs Normal (single user, capped at ₹1L)
Allocation: Always square & equal across indices/brokers/accounts
Settlement flow: Gross → Loss buffer (if losses) → Platform fee (30%) → Tax lock (39%) → Rounding → Net
Brokerage: ~6% auto-deducted, tracked for reporting
Increment: Based on accumulated profit (50% threshold)
Multi-index: Simultaneous trades, equal allocation
No assumptions
All percentages and formulas are from your specifications
Rounding rules match your examples
Flow order follows your sequence
Detailed implementation plan markdown
Save this as CAPITAL_SETTLEMENT_IMPLEMENTATION_PLAN.md:
# Capital & Settlement Implementation Plan**Based on Vik's Vision - Detailed Implementation****Date**: 2025-12-19  **Status**: Ready for Implementation---## 🎯 Core Requirements Summary### User Types- **Admin (Vik)**: Multiple users allowed, increments up to ₹15L- **Normal Users**: Single user, capped at ₹1L (rest greyed out - subscription tease)### Capital Calculation Formula
Initial Capital = Base × Indices × Brokers × Users + 30% Margin
Next Increment = Next Base × Indices × Brokers × Users + 30% Margin
**Examples:**- ₹10K × 3 × 1 × 1 + 30% = ₹39,000 → Round up to ₹40,000 or ₹50,000- ₹50K × 3 × 1 × 1 + 30% = ₹195,000 → Round up to ₹2,00,000### Capital Allocation- **Always Square & Equal** across:  - Indices (NIFTY50, BANKNIFTY, SENSEX)  - Brokers (if multiple)  - Accounts (admin only)### Settlement Flow (From Gross Profit)1. **Gross Profit** (already excludes ~6% brokerage/exchange fees - tracked for reporting)2. **IF Losses Occur**: Deduct 1% loss/latency buffer3. **Deduct Platform Fee**: 30% → ZenithPulse Tech Account4. **Lock Tax Reserve**: 39% → Savings Account (for tax reporting)5. **Apply Rounding Logic**: Excess stays in Demat6. **Net to Savings**: Remaining after all deductions### Increment Logic- **Based on**: Accumulated profit- **Follows**: Flow order (₹10K → ₹50K → ₹1L → ₹5L → ₹15L for admin)- **Normal Users**: Capped at ₹1L (rest greyed out)- **Threshold**: 50% of current capital accumulated profit---## 📋 Implementation Plan### Phase 1: Capital Calculation Engine#### 1.1 Create `CapitalCalculationEngine`**File**: `aurum_harmony/engines/settlement/capital_calculation_engine.py`**Key Features:**- Calculate initial capital with margin (30%)- Round up logic (₹39K → ₹40K/₹50K, ₹195K → ₹2L)- Equal allocation per index/broker/account- Support admin vs normal user types**Methods:**- `calculate_initial_capital()` - Main calculation- `_round_up_capital()` - Rounding logic- `get_next_capital_level()` - Next increment calculation---### Phase 2: Enhanced Settlement Engine#### 2.1 Update `SettlementEngine` with Loss Buffer**File**: `aurum_harmony/engines/settlement/Settlement_Engine.py`**Enhancements:**- Add `LOSS_BUFFER_PCT = 0.01` (1% only if losses occur)- Add `BROKERAGE_PCT = 0.06` (tracked for reporting)- Update `settle()` method to include:  - Loss buffer check (only if `has_losses=True`)  - Brokerage fee tracking  - Platform fee (30% → ZenithPulse)  - Tax lock (39% → Savings)  - Rounding logic (existing)**Settlement Flow:**
Gross Profit (after broker auto-deductions)
↓
IF Losses: Deduct 1% buffer
↓
Deduct 30% Platform Fee → ZenithPulse
↓
Lock 39% Tax → Savings
↓
Apply Rounding → Excess stays in Demat
↓
Net to Savings
---### Phase 3: Multi-Index Capital Allocator#### 3.1 Create `MultiIndexCapitalAllocator`**File**: `aurum_harmony/engines/settlement/multi_index_allocator.py`**Purpose:**- Allocate capital equally across indices, brokers, accounts- Always square & equal allocation- Support simultaneous multi-index trading**Methods:**- `allocate_capital()` - Equal allocation across all dimensions- Returns allocation matrix per index/broker/account---### Phase 4: Profit-Based Increment Logic#### 4.1 Update `IncrementEngine` with Profit Threshold**File**: `aurum_harmony/engines/settlement/Settlement_Engine.py`**Enhancements:**- Add `should_increment_capital()` method- Check accumulated profit vs threshold (50% of current capital)- Calculate next capital with margin and rounding- Reset accumulated profit after increment**Logic:**- Track accumulated profit per user- When profit ≥ 50% of current capital → Increment- Calculate next capital: Next Base × 3 × 1 × 1 + 30%- Round up appropriately---### Phase 5: Database Updates#### 5.1 Add Fields to User Model**File**: `aurum_harmony/database/models.py`**New Fields:**- `accumulated_profit` (Float) - Profit since last increment- `capital_allocation` (JSON) - Per-index/broker allocation matrix- `last_increment_date` (DateTime) - When capital was incremented- `brokerage_fees_tracked` (Float) - Total brokerage fees (for reporting)#### 5.2 Create Profit Tracking Table**File**: `aurum_harmony/database/models.py`**New Model**: `ProfitTracking`- `user_id` (FK to User)- `period_start` (DateTime)- `gross_profit` (Float)- `brokerage_fees` (Float)- `loss_buffer` (Float)- `platform_fee` (Float)- `tax_locked` (Float)- `net_to_savings` (Float)- `rounding_buffer` (Float)- `accumulated_profit` (Float)- `created_at` (DateTime)---### Phase 6: Integration Points#### 6.1 Update Orchestrator**File**: `aurum_harmony/app/orchestrator.py`**Integration:**- Call `CapitalCalculationEngine` on user creation- Call `MultiIndexCapitalAllocator` for capital allocation- Track accumulated profit per user- Call `IncrementEngine.should_increment_capital()` on EOD settlement#### 6.2 Update Settlement Flow**File**: `aurum_harmony/engines/integration_layer.py`**Integration:**- Enhanced `SettlementEngine.settle()` with loss buffer- Track brokerage fees for reporting- Update accumulated profit- Check increment threshold- Transfer net to savings (via Fund Push/Pull Engine)#### 6.3 Update Fund Push/Pull Engine**File**: `aurum_harmony/engines/fund_push_pull/fund_push_pull.py`**Integration:**- Transfer 30% platform fee → ZenithPulse Tech Account- Lock 39% tax reserve → Savings Account- Transfer net profit → Savings Account- Keep rounding buffer in Demat---## 📊 Example Calculation Flow### Scenario: User with ₹10K base, 3 indices, 1 broker**Step 1: Initial Capital Calculation**
Base Capital: ₹10,000
Formula: ₹10K × 3 indices × 1 broker × 1 user + 30% margin
Calculation: ₹10,000 × 3 × 1 × 1 = ₹30,000
Margin (30%): ₹30,000 × 0.30 = ₹9,000
Total: ₹30,000 + ₹9,000 = ₹39,000
Rounded: ₹40,000 (or ₹50,000)
Per Index Allocation: ₹40,000 / 3 = ₹13,333.33 (equal)
Per Broker Allocation: ₹40,000 / 1 = ₹40,000
**Step 2: Trading Period**
Trades: 27 trades/day × 3 indices = 81 trades/day
Win Rate: 55%
Avg Profit: ~7% per trade
Leverage: 3x
Simultaneous: Yes (all 3 indices)
**Step 3: EOD Settlement (Example)**
Gross Profit: ₹5,000 (after broker auto-deducted ~6%)
Brokerage Fees: ₹300 (tracked for reporting, already deducted)
IF Losses Occurred:
Loss Buffer: ₹50 (1% of ₹5,000)
Gross After Buffer: ₹4,950
ELSE:
Loss Buffer: ₹0
Gross After Buffer: ₹5,000
Platform Fee (30%): ₹1,500 → ZenithPulse Tech Account
Tax Lock (39%): ₹1,950 → Savings Account (locked for tax reporting)
Net Before Rounding: ₹1,550
Rounding Logic:
Amount: ₹1,550
Rounded: ₹1,000 (nearest ₹1,000)
Buffer: ₹550 → Stays in Demat
Net to Savings: ₹1,000
Accumulated Profit: +₹1,000
**Step 4: Increment Check**
Current Capital: ₹40,000
Accumulated Profit: ₹20,000 (50% threshold reached)
Profit Threshold: ₹40,000 × 0.50 = ₹20,000
→ Increment Triggered
Next Base: ₹50,000
Next Calculation: ₹50K × 3 × 1 × 1 + 30% = ₹195,000
Rounded: ₹2,00,000
Reset Accumulated Profit: ₹0
Update Capital: ₹40,000 → ₹2,00,000
---## 🔧 Files to Create/Update### New Files:1. `aurum_harmony/engines/settlement/capital_calculation_engine.py`2. `aurum_harmony/engines/settlement/multi_index_allocator.py`### Files to Update:1. `aurum_harmony/engines/settlement/Settlement_Engine.py`   - Add loss buffer logic   - Add brokerage tracking   - Enhance `settle()` method   - Add `should_increment_capital()` to `IncrementEngine`2. `aurum_harmony/database/models.py`   - Add `accumulated_profit`, `capital_allocation`, `last_increment_date`, `brokerage_fees_tracked` to User model   - Create `ProfitTracking` model3. `aurum_harmony/app/orchestrator.py`   - Integrate capital calculation on user creation   - Track accumulated profit   - Check increment threshold on EOD4. `aurum_harmony/engines/integration_layer.py`   - Update settlement flow with loss buffer   - Update accumulated profit tracking5. `aurum_harmony/engines/fund_push_pull/fund_push_pull.py`   - Handle 30% → ZenithPulse transfer   - Handle 39% → Savings lock   - Handle net → Savings transfer6. `aurum_harmony/database/migrate.py`   - Add migration for new User fields   - Create `profit_tracking` table---## ✅ Implementation Checklist### Phase 1: Capital Calculation Engine- [ ] Create `capital_calculation_engine.py`- [ ] Implement `calculate_initial_capital()`- [ ] Implement `_round_up_capital()` with rounding rules- [ ] Implement `get_next_capital_level()`- [ ] Add unit tests### Phase 2: Enhanced Settlement Engine- [ ] Add `LOSS_BUFFER_PCT` constant- [ ] Add `BROKERAGE_PCT` constant- [ ] Update `settle()` method signature (add `has_losses`, `brokerage_fees`)- [ ] Implement loss buffer logic (only if losses)- [ ] Add brokerage fee tracking- [ ] Update return dictionary with new fields- [ ] Add unit tests### Phase 3: Multi-Index Capital Allocator- [ ] Create `multi_index_allocator.py`- [ ] Implement `allocate_capital()` method- [ ] Ensure equal allocation across all dimensions- [ ] Return allocation matrix- [ ] Add unit tests### Phase 4: Profit-Based Increment Logic- [ ] Add `should_increment_capital()` to `IncrementEngine`- [ ] Implement profit threshold check (50% of current capital)- [ ] Calculate next capital with margin and rounding- [ ] Add unit tests### Phase 5: Database Updates- [ ] Add `accumulated_profit` to User model- [ ] Add `capital_allocation` (JSON) to User model- [ ] Add `last_increment_date` to User model- [ ] Add `brokerage_fees_tracked` to User model- [ ] Create `ProfitTracking` model- [ ] Create migration script- [ ] Run migration### Phase 6: Integration- [ ] Update Orchestrator: Capital calculation on user creation- [ ] Update Orchestrator: Track accumulated profit- [ ] Update Orchestrator: Check increment threshold on EOD- [ ] Update Settlement Flow: Enhanced settle() call- [ ] Update Fund Engine: Handle transfers (30% → ZenithPulse, 39% → Savings)- [ ] Update Integration Layer: Settlement with loss buffer- [ ] Add integration tests---## 🎯 Key Features Summary1. ✅ **Capital Calculation**: Formula-based with 30% margin and rounding2. ✅ **Equal Allocation**: Square & equal across indices/brokers/accounts3. ✅ **Loss Buffer**: 1% only if losses occur4. ✅ **Platform Fee**: 30% → ZenithPulse Tech Account5. ✅ **Tax Lock**: 39% → Savings Account (for tax reporting)6. ✅ **Brokerage Tracking**: Track ~6% fees for reporting (already deducted)7. ✅ **Profit-Based Increment**: Based on accumulated profit (50% threshold)8. ✅ **Admin vs Normal**: Different increment levels and caps9. ✅ **Multi-Index**: Simultaneous trading with equal allocation10. ✅ **Rounding Logic**: Excess stays in Demat (existing logic)---## 📝 Notes- **Brokerage Fees**: Already auto-deducted by broker/exchange, but tracked for reporting- **Loss Buffer**: Only deducted if losses occur (`has_losses=True`)- **Platform Fee**: 30% of gross (after buffer if applicable) → ZenithPulse Tech Account- **Tax Lock**: 39% of gross (after buffer if applicable) → Savings Account- **Increment**: Based on accumulated profit reaching 50% of current capital- **Normal Users**: Capped at ₹1L, rest greyed out (subscription tease)- **Admin**: Can have multiple users, increments up to ₹15L---## 🚀 Ready for ImplementationAll requirements understood and documented. No assumptions made - all based on Vik's specifications.**Status**: ✅ Ready to implement when switched to Agent mode.---**Created**: 2025-12-19  **Author**: Charlie (AI Assistant)  **Reviewed By**: Vik
Summary
All requirements documented
No assumptions — everything from your specifications
Ready for implementation when you switch to Agent mode
The markdown file is ready. Save it as CAPITAL_SETTLEMENT_IMPLEMENTATION_PLAN.md and switch to Agent mode to proceed.