# AurumHarmony Requirements — v1.0 Beta (21 Nov 2025)

## Functional
- 27–180 trades/day per user
- 3× leverage 
- >70% AI confidence threshold
- 15-minute strategy switching (max 4/hour)
- Real-time SEBI compliance engine
- Hyperledger Fabric logging for every action
- Flutter widgets (iOS/Android/Windows)
- Weekly ML model retraining with rolling 90-day data window
- Shadow mode backtesting for all new models before promotion to live

## Non-Functional
- Latency <0.2s
- Uptime 99.9%
- Scale to 15,000 users by 2030
- All data stored in India (AWS Mumbai)

## Regulatory
- SEBI exposure ≤₹50 lakh
- Max 1,250 lots
- Daily regulatory scrape 08:30–09:00 IST
- 7-year audit trail via Hyperledger
- 18% GST + 39% notional tax reporting

## Security
- Hyperledger Fabric key-pair authentication
- AES-256 + OAuth 2.0
- No API keys in repo


