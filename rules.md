AurumHarmony Rules — Final v1.0 Beta (28 Nov 2025)



\## User Categories \& Increment Levels (incl. 30% leverage margin)



1\. NGD — Funded \& Restricted

&nbsp;  - Initial: ₹5,000 | Increment: None (cyclical reset)

&nbsp;  - Max accounts: 1 | ZPT Fee: 15%



2–4. Funded Restricted / Semi-Restricted (Alpha-Beta + White-Label)

&nbsp;  - Initial: ₹10,000

&nbsp;  - Increment levels: → ₹50,000 → ₹1,00,000

&nbsp;  - Max accounts: 2 | ZPT Fee: 30% → 12.5%



5\. Unrestricted Admin (owner + companies — later)

&nbsp;  - Initial: ₹10,000

&nbsp;  - Increment levels: → ₹50K → ₹1L → ₹5L → ₹15L

&nbsp;  - Max accounts: 6+



\## Fund Transfer Rules (UPI-Safe Architecture)

All movements: User Savings ↔ Broker Nodal ↔ Trading ↔ Demat  

Demat accounts NEVER directly linked to UPI — 100% SEBI-compliant.



Daily Limits \& Workarounds:

Push: Split >₹1L via Razorpay + IMPS fallback  

Pull: No limit (IMPS/RTGS)  

Primary: Razorpay (₹5L+ daily)  

Fallback: PhonePe / GPay / IMPS



Core Parameters (Per User)

* Starting Capital: ₹10,000 (Tier 2+) | ₹5,000 (NGD only)
* Leverage: 3× (all tiers except NGD 1.5×)
* Trades/Day: 27–180 (scales with tier \& VIX)
* Initial Capital Progression: ₹10K → ₹1L → ₹2.5L → ₹7.5L → ₹15L
* Accounts: 1–6 (scales with tier, clubbed during progression)



VIX Adjustment Logic

* VIX <15: 100% capacity, 10% target return, 60–66% win rate
* VIX 15–20: 75% capacity, 8% target return, 55–60% win rate
* VIX 20–30: 50% capacity, 7% target return, 50–55% win rate
* VIX >30: 50% capacity, 5% target return, 45–50% win rate



\#Revenue Split

* Beta Phase: Platform 30% → SaffronBolt 70% / ZenithPulse 30% of net fee
* Post-Beta: Platform 12% → SaffronBolt 85% / ZenithPulse 15% of net fee
* NGD: 10% fee, cyclical ₹5,000 reset, no increment



Rounding Rule (by subtraction, balance stays in demat)

* ≥₹1,00,000 → nearest ₹10,000
* ≥₹10,00,000 → nearest ₹1,00,000
* ≥₹1,00,00,000 → nearest ₹10,00,000



Settlement \& Transfer

* EOD settlement
* Net profit transferred to savings
* Rounding amount + buffer stays in demat



Compliance

* Max exposure: ₹50 lakh
* Max lots: 1,250
* Daily SEBI/NSE/BSE scrape 08:30–09:00 IST
* Hyperledger Fabric 7-year immutable log



Golden Guardrails (8 Engines)

1. Predictive AI
2. ML Training
3. Compliance
4. Dynamic Fund Push/Pull
5. Trade Execution
6. Settlement
7. Reporting
8. Notifications
