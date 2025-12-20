# AurumHarmony Dynamic Index Options Trading System  
# Implementation Guide — Ver 11 (05 December 2025 — FINAL)

## Overview
Fully automated intraday index options trading platform launched 26 January 2026 by SaffronBolt Private Limited. Targets NIFTY50, BANKNIFTY, SENSEX with 3× leverage, predictive AI, and blockchain audit.

## Core Architecture
- Eight Golden Guardrails engines
- 15-minute AI directional cycle + 5-minute HFT execution layer
- VIX-based capacity scaling (50–100%)
- Per-account capital progression with progressive index unlock
- Razorpay + IMPS UPI-safe fund flow
- Hyperledger Fabric 7-year immutable ledger
- Flutter cross-platform app + Windows/Web

## User Categories & Increment Levels (incl. 30% leverage margin)
| Category                    | Start     | Level 1    | Level 2     | Level 3     | Level 4      | Max Accounts |
|-----------------------------|-----------|------------|-------------|-------------|--------------|--------------|
| NGD                         | ₹5,000    | Cyclical (no increment)                           | 1            |
| Restricted / Semi-Restricted| ₹10,000   | → ₹50,000  | → ₹1,00,000 |             |              | 2            |
| Unrestricted Admin          | ₹10,000   | → ₹50,000  | → ₹1,00,000 | → ₹5,00,000 | → ₹15,00,000 | 6+           |

## 22-Day Trading Simulations (1 month)
| Category                     | Starting Capital | Trades/Day | Monthly Net Profit | Annual Net (12×) |
|------------------------------|------------------|------------|--------------------|------------------|
| NGD (cyclical)               | ₹5,000           | 18         | ₹58,500            | ₹7,02,000        |
| Restricted (30% fee)         | ₹10,000          | 27         | ₹2,16,000          | ₹25,92,000       |
| Semi-Restricted (12.5% fee)  | ₹10,000          | 27         | ₹2,70,000          | ₹32,40,000       |
| Admin (Level 4 — ₹5L)        | ₹5,00,000        | 180        | ₹18,00,000+        | ₹2,16,00,000+    |

## Detailed Golden Guardrails Explanation (8 Engines)
1. Predictive AI — Hybrid RandomForest + LSTM, 15-min signal, >70% confidence
2. ML Training — Weekly retrain on 30-day data
3. Compliance — Real-time SEBI checks + dynamic order splitting
4. Fund Push/Pull — 09:15/15:25 via Razorpay + IMPS
5. Trade Execution — 5-min HFT, max 4 trades per 15-min cycle
6. Settlement — EOD with 39% tax lock + rounding buffer
7. Reporting — Daily/weekly/annual with Hyperledger hash
8. Notifications — Max 5/day, tiered alerts

## VIX-Based Dynamic Scaling — DETAILED
| VIX    | Capacity | Max Trades/Account/Day | Target Return |
|--------|----------|------------------------|---------------|
| <15    | 100%     | 180                    | 10–18%        |
| 15–20  | 75%      | 135                    | 8–12%         |
| 20–30  | 50%      | 90                     | 5–8%          |
| >30    | 50%      | 90                     | ≤5%           |

## SEBI Compliance — Dynamic Order Splitting
- Max exposure: ₹50,00,000 per user
- Max lots per order: 250
- Large orders automatically split — never halt trading

## Patent Status
- Provisional filed: 202521105260
- Complete Specification filed: 28 Nov 2025

## Current Status — 05 Dec 2025
- Live beta: https://aurumharmony-v1-beta.pages.dev/
- Cloudflare Deploy Hooks active
- 5-min HFT layer implemented
- All 20 codebases clean