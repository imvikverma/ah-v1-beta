# AurumHarmony Design History

**Document Date:** 2025-11-28  
**Status:** Historic reference document

## Platform Priority
Windows Desktop (WinUI 3) + Web (Blazor WebAssembly) — **first launch**

## Core Design Rules (Non-Negotiable)
- **Colour:** Saffron (#FF9933) + Deep Black + Pure White
- **Font:** Segoe UI Variable (Windows) / Inter (Web)
- **Max 4 actions per screen**
- **Indian rupee format:** ₹10,000
- **Dark mode default**

## Screen Layout (Exact Historic Order)

### 1. Login
- Phone + OTP → Aadhaar eSign → Risk Quiz → Tier Assignment

### 2. Main Dashboard (The Sacred Screen)
- Top bar: Live Capital (huge saffron number)
- Today's P&L (big green/red)
- Active Indices (progressive unlock: NIFTY50 → BANKNIFTY → SENSEX)
- Trades Today / Max Trades
- VIX Mood Ring (colour circle)
- Next Increment Countdown

### 3. Live Trading View
- 15-min chart + RSI
- AI Confidence meter
- One giant "EXECUTE" button

### 4. Progression Ladder
- Visual path: ₹10K → ₹50K → ₹1L → ₹5L → ₹15L
- Unlock badges + confetti animation

### 5. Golden Guardrails
- 8 engines status grid
- Drawdown meter
- Hyperledger sync indicator

### 6. Admin Web Panel (Separate Domain)
- Full user control
- Real-time Hyperledger explorer

### 7. Widgets (Windows 11 + Web)
- Balance | Profit | Active Indices | Next Unlock

## Current Implementation Status

**Note:** This document represents the original design vision. The current Flutter implementation may differ in some aspects:

- ✅ Login screen implemented (simplified: email/phone + password)
- ✅ Dashboard screen implemented
- ✅ Theme system (Light/Dark mode)
- ✅ Logo integration
- 📋 Trading view (pending)
- 📋 Progression ladder (pending)
- 📋 Golden Guardrails (pending)
- 📋 Admin panel (partially implemented)

## Design Evolution

This document captures the original design from May–June 2025. The current Flutter web app has evolved to:
- Use Flutter instead of Blazor WebAssembly
- Simplified login flow (no OTP/Aadhaar eSign in initial version)
- Material Design 3 theming
- Responsive web-first approach

---

**Reference:** Original design document from 2025-11-28

