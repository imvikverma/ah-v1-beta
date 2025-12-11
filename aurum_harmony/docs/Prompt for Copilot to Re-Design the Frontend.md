Re-design the frontend for AurumHarmony based on the provided .md spec and sample UI image as inspiration. AurumHarmony is a complete handsfree trading system—NO user input related to trades (e.g., no manual order dialogs, selections, or decisions; all automated via backend "Run Prediction"). User interactions limited to non-trading: Viewing dashboards/reports, configuring settings (brokers/subscriptions), receiving notifications, exporting data.

Use Flutter for cross-platform (Web, Android, iOS, Windows). Overall futuristic minimal look: Clean white cards with subtle blue/purple gradients, rounded buttons, line charts with soft fills, circular icons, lots of white space. Add saffron/gold gradients (#FF9933 to #FFD700) for accents on cards/buttons/charts/icons. Add gradient animation effects (e.g., slow pulsing on "Run Prediction" button). Add Dark/Light mode with saffron variants (light: white bg; dark: #121212 bg, darker saffron #CC7A00/gold #CCAC00).

Key updates:
- AurumHarmony logo: Centered/large on Onboarding. Top-left/right resized (40-60px) on other pages for visibility.
- Footer on all pages: "Patent Pending © 2025 SaffronBolt Pvt Ltd | Visit www.saffronbolt.in".

Screens (implement all, handsfree focus):
1. Onboarding: Logo, carousel, "Get Started", skip.
2. Login: Email/phone, password, "Login", forgot, signup link.
3. Signup: Email, phone, username, password, profile pic (optional), terms checkbox, "Create Account".
4. Dashboard: Greeting, balance, P&L, portfolio/value/active positions/today's trades cards, recent activity, quick buttons (non-trading only). No "Next Increment Countdown".
5. Trade: "Run Prediction" button (backend trigger, shows signals/orders/results automatically), paper trading card (info only), positions list (view-only).
6. Notifications: List (title/message/time/read); tap to mark read + SnackBar details.
7. Reports: Date range, P&L charts (saffron/gold gradients), win rate/avg return, trade history table, export (PDF/CSV).
8. Broker Settings: Dropdown (Kotak Neo/HDFC Sky), API key/secret, "Connect", status.
9. Admin: User list, actions (view/edit/deactivate), database functions if enabled.

Navigation: Bottom bar: Dashboard/Trade/Notifications/Reports/Settings.

Auth: Token check on launch, silent logout on expiration (inline error, no popup).

Use Roboto/Orbitron fonts, elevated cards (8px radius), primary buttons (gold/saffron gradient glow/animation, 48px height), outlined secondary (blue).

Include token storage (shared_preferences), API endpoints (e.g., POST /api/auth/login), error handling (401 auto-logout).

Generate full code: lib/main.dart, screens folder with dart files, widgets (custom card, button, footer). Dark mode toggle.

Mobile-first responsive. Automated only—no manual trading.