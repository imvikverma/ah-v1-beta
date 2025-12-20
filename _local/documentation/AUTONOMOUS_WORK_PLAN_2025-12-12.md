# Autonomous Work Plan - Friday, December 12, 2025

**User Status:** Away (Funding meetings)  
**Laptop Status:** Powered on  
**AI Agent:** Charlie (Cursor)  
**Work Mode:** Autonomous (no user input needed)

---

## 🎯 **Objectives**

1. Register and test Database Console (30 min)
2. Implement LSTM Backtesting (4-6 hours)
3. Document all changes for review (1 hour)

---

## ✅ **Task List**

### **Phase 1: Database Console (Priority: HIGH, Risk: LOW)**

- [ ] Edit `aurum_harmony/master_codebase/Master_AurumHarmony_261125.py`
  - [ ] Add import: `from aurum_harmony.admin.db_console_routes import db_console_bp`
  - [ ] Register blueprint: `app.register_blueprint(db_console_bp)`
- [ ] Restart backend
- [ ] Test endpoint: `GET /api/admin/console/status`
- [ ] Test endpoint: `GET /api/admin/console/users/all?show_sensitive=false`
- [ ] Test endpoint: `GET /api/admin/console/users/all?show_sensitive=true`
- [ ] Document results in `_local/development/console_test_results.json`

**Expected Time:** 30 minutes  
**Risk Level:** LOW (new endpoints, won't break existing functionality)

---

### **Phase 2: LSTM Backtesting (Priority: HIGH, Risk: MEDIUM)**

#### **Step 1: Data Preparation**
- [ ] Create `aurum_harmony/engines/backtesting/data_loader.py`
- [ ] Load historical NIFTY/BANKNIFTY data (2023-2024)
- [ ] Prepare features: OHLCV, VIX, RSI, ATR, MACD
- [ ] Split into train/test sets (80/20)

#### **Step 2: LSTM Model**
- [ ] Create `aurum_harmony/engines/backtesting/lstm_volatility_model.py`
- [ ] Build LSTM architecture:
  - Input: 60-day sequences
  - LSTM layers: 128 → 64 → 32
  - Output: Volatility prediction (next day)
- [ ] Train model on historical data
- [ ] Save trained model to `_local/models/lstm_volatility.h5`

#### **Step 3: Backtesting Integration**
- [ ] Create `aurum_harmony/engines/backtesting/lstm_backtest.py`
- [ ] Integrate with existing backtrader setup
- [ ] Implement strategies:
  - VIX-adjusted position sizing
  - Dynamic entry/exit based on volatility
  - Risk limits from rules.md
- [ ] Run backtests on:
  - NIFTY50 (2023-2024)
  - BANKNIFTY (2023-2024)

#### **Step 4: Results & Analysis**
- [ ] Generate performance metrics:
  - Total return
  - Win rate
  - Sharpe ratio
  - Maximum drawdown
  - Average trade duration
- [ ] Create visualizations (if possible)
- [ ] Save results to `_local/backtesting/results/lstm_backtest_2025-12-12.json`

**Expected Time:** 4-6 hours  
**Risk Level:** MEDIUM (new code, but isolated module)

---

### **Phase 3: Documentation & Cleanup (Priority: HIGH, Risk: LOW)**

- [ ] Commit all changes with clear messages
- [ ] Update `CHANGELOG.md`
- [ ] Create `_local/WORK_SUMMARY_2025-12-12.json`
- [ ] Update EOD summary: `_local/Summaries/EOD_2025-12-12_Charlie.json`
- [ ] Check for any linter errors
- [ ] Verify backend still runs
- [ ] Create review checklist for user

**Expected Time:** 1 hour  
**Risk Level:** LOW (documentation only)

---

## 🛡️ **Safety Checklist**

Before making ANY change:
- [ ] Will this break existing functionality? → If yes, SKIP IT
- [ ] Do I need user input for this decision? → If yes, DOCUMENT & SKIP
- [ ] Can this be easily reverted? → If no, BE EXTRA CAREFUL
- [ ] Is this in a new file/module? → PREFERRED
- [ ] Does this modify critical paths (auth, payments, user data)? → If yes, DON'T DO IT

---

## 📝 **Decision Log**

| Time | Decision | Rationale |
|------|----------|-----------|
| (Will be filled during work) | | |

---

## 🚨 **If Something Goes Wrong**

1. **Backend won't start:**
   - Revert last commit
   - Check `_local/logs/backend.log`
   - Document error in work summary
   - Skip to documentation phase

2. **Import errors:**
   - Check file paths
   - Verify dependencies in requirements.txt
   - Document missing dependencies
   - Continue with what works

3. **Tests fail:**
   - Document failure
   - Mark task as "needs review"
   - Continue with other tasks

4. **Uncertain about decision:**
   - Document the question
   - Add to "Needs Review" section
   - Skip task and move to next

---

## 📊 **Expected Deliverables**

### **Files Created:**
- `aurum_harmony/engines/backtesting/data_loader.py`
- `aurum_harmony/engines/backtesting/lstm_volatility_model.py`
- `aurum_harmony/engines/backtesting/lstm_backtest.py`
- `_local/models/lstm_volatility.h5`
- `_local/backtesting/results/lstm_backtest_2025-12-12.json`
- `_local/WORK_SUMMARY_2025-12-12.json`
- `_local/Summaries/EOD_2025-12-12_Charlie.json`

### **Files Modified:**
- `aurum_harmony/master_codebase/Master_AurumHarmony_261125.py` (add console blueprint)
- `CHANGELOG.md` (document changes)

### **Files NOT Modified:**
- Any authentication files
- Any user data/database
- Any production deployment files
- Any critical API endpoints

---

## ⏰ **Timeline**

| Time | Activity |
|------|----------|
| 09:00 - 09:30 | Database Console registration & testing |
| 09:30 - 10:30 | Data preparation for backtesting |
| 10:30 - 12:30 | LSTM model development |
| 12:30 - 13:30 | Break |
| 13:30 - 15:30 | Backtesting integration & execution |
| 15:30 - 16:30 | Results analysis & documentation |
| 16:30 - 17:00 | Final cleanup & commit |

---

## 📞 **Review Checklist for User**

When you return, please review:

### **Database Console:**
- [ ] Blueprint registered correctly?
- [ ] All endpoints working?
- [ ] Security concerns?
- [ ] Ready for beta testing?

### **LSTM Backtesting:**
- [ ] Model architecture makes sense?
- [ ] Backtest results look reasonable?
- [ ] Performance metrics acceptable?
- [ ] Ready to integrate with live system?

### **Code Quality:**
- [ ] Code follows project standards?
- [ ] Proper error handling?
- [ ] Adequate documentation/comments?
- [ ] No security issues?

### **Next Steps:**
- [ ] What needs to be changed?
- [ ] What should be tested more?
- [ ] Ready to move to production?

---

**Status:** Ready to begin autonomous work  
**Last Updated:** 2025-12-11 (Before user leaves)  
**Next Update:** 2025-12-12 (During autonomous work)

