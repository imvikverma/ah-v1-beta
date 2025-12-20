Re-design the frontend for AurumHarmony based on the provided .md spec and sample UI image as inspiration. Use Flutter for cross-platform (Web, Android, iOS, Windows). Incorporate a more futuristic yet minimal look from the sample: Clean white cards with subtle blue/purple gradients, rounded buttons, line charts with soft fills, circular icons, and a mobile-first layout with lots of white space. Add saffron/gold gradients for premium accents: LinearGradient from saffron (#FF9933) to gold (#FFD700) on card backgrounds, buttons, charts (e.g., P&L lines), and icons for glowing effect.

Key updates from user:
- AurumHarmony logo: Centered and large on Onboarding/Landing page. On all other pages, top-left or top-right, resized to 40-60px height for visibility.
- Footer on all pages: Add link to www.saffronbolt.in at the bottom, at the end of or below the patent info line (e.g., "Patent Pending © 2025 SaffronBolt Pvt Ltd | Visit www.saffronbolt.in").

Screens from spec (implement all):
1. Onboarding: Logo, carousel highlights, "Get Started" button, skip.
2. Login: Email/phone, password, "Login" button, forgot link, signup link.
3. Signup: Email, phone, username, password, profile pic upload (optional), terms checkbox, "Create Account" button.
4. Dashboard: Greeting, balance card, P&L, portfolio/value/active positions/today's trades cards, recent activity, quick buttons. No "Next Increment Countdown". Use sample's card style for balance/history with saffron/gold gradient borders.
5. Trade: "Run Prediction" button (triggers backend, shows signals/orders), paper trading card (automatic info), current positions list. Use sample's "Optimize Resources" style for prediction card with gold glow on button.
6. Notifications: List with title/message/time/read status; tap to mark read + show details in SnackBar. Use sample's transaction history list style.
7. Reports: Date range, P&L charts (line charts like sample overview with saffron/gold gradient fills), win rate/avg return, trade history table, export (PDF/CSV).
8. Broker Settings: Dropdown (Kotak Neo/HDFC Sky), API key/secret fields, "Connect" button, status indicator.
9. Admin: User list (email/code/status/admin), actions (view/edit/deactivate), database functions if enabled.

Navigation: Bottom bar with Dashboard/Trade/Notifications/Reports/Settings.

Auth: Check token on launch, silent logout on expiration (inline error, no popup).

Use Roboto/Orbitron fonts, elevated cards (8px radius), primary buttons (gold with saffron gradient glow, 48px height), outlined secondary (blue).

Include token storage (shared_preferences), API endpoints (e.g., POST /api/auth/login), error handling (401 auto-logout).

Generate full code: lib/main.dart, screens folder with dart files for each screen, widgets for components (e.g., custom card, button, footer with link). Add dark mode toggle.

Make mobile-first responsive. No manual trading dialogs—automated only. Match sample's futuristic elements: Circular payment icons, gradient backgrounds on cards, soft shadows, with saffron/gold for branding.