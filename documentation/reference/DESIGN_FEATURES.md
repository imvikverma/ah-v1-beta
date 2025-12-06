# AurumHarmony v1.0 Beta - Design Features & UI Specifications

This document captures all design features, UI components, and visual specifications for the AurumHarmony Flutter frontend. Use this to track what's implemented, what's planned, and what needs to be recreated.

---

## 🎨 Current Design System

### Color Palette
- **Primary (Gold/Saffron)**: `#f9a826` - Main brand color
- **Secondary (Green)**: `#4caf50` - Success indicators
- **Background**: `#050816` - Main dark background
- **Surface**: `#11172b` - Card/surface background
- **Accent Colors**:
  - Blue: `#2196F3` - Demat account
  - Green: `#4CAF50` - Savings account
  - Red: `#F44336` - Losses/errors
  - Orange: `#FF9800` - Warnings

### Typography
- **Headings**: Bold, 18-24px
- **Body**: Regular, 14-16px
- **Labels**: 12px, grey shades
- **Monospace**: For numbers/currency

### Components
- **Cards**: Rounded corners, dark surface, padding 16px
- **Buttons**: Rounded 12px, primary color for actions
- **Icons**: Material Icons, 24px default
- **Spacing**: 8px, 16px, 24px grid

---

## ✅ Currently Implemented

### Authentication
- [x] Login screen with User ID, API Key, API Secret
- [x] Secure credential storage (SharedPreferences)
- [x] Logout functionality
- [x] API key management dialog

### Dashboard Screen
- [x] Backend status indicator
- [x] Account summary (Capital, P&L, Trades)
- [x] Demat account balance card (opening, current, closing)
- [x] Savings account balance card (opening, current, closing)
- [x] System overview placeholder
- [x] Live balance updates (simulated)

### Trade Screen
- [x] Strategy controls (Run Prediction, Pause All)
- [x] Open positions list (placeholder)
- [x] Manual override (Close All Positions)

### Reports Screen
- [x] User trade summary
- [x] Performance metrics display
- [x] Backtesting controls (Realistic Test, Edge Test)
- [x] Performance charts placeholder

### Notifications Screen
- [x] Alert feed with filtering (All, Trades, Risk, System)
- [x] Read/unread indicators
- [x] Placeholder notification data

### Admin Screen
- [x] User list with status indicators
- [x] User details (Tier, Capital, Max trades)
- [x] Error handling and retry

### Navigation
- [x] Bottom navigation bar (5 tabs)
- [x] App bar with connection status
- [x] API key management button
- [x] Logout button

---

## 🚧 Partially Implemented / Needs Enhancement

### Dashboard
- [ ] **P&L Chart**: Small chart showing recent P&L trend
- [ ] **Recent Trades List**: Last 5-10 trades with summary
- [ ] **Risk Usage Indicator**: Visual gauge showing risk vs limits
- [ ] **VIX-adjusted Capacity**: Display current VIX-adjusted trading capacity
- [ ] **Trading Mode Badge**: PAPER/LIVE indicator with toggle
- [ ] **Orchestrator Status**: Real-time status (Idle/Running/Error)

### Trade Screen
- [ ] **Strategy List**: Expandable list of available strategies
- [ ] **Strategy Toggles**: On/Off switches for each strategy
- [ ] **Strategy Parameters**: Editable fields (symbol, size, risk profile)
- [ ] **Real Positions Data**: Connect to `/positions` endpoint
- [ ] **Position Details**: Expandable position cards with full details
- [ ] **Order Book**: Pending orders display
- [ ] **Trade History**: Recent executions in this session

### Reports Screen
- [ ] **Date Range Picker**: Filter trades by date
- [ ] **Symbol Filter**: Filter by trading symbol
- [ ] **Strategy Filter**: Filter by strategy used
- [ ] **Equity Curve Chart**: Line chart showing account value over time
- [ ] **Drawdown Chart**: Visual representation of drawdown periods
- [ ] **Win/Loss Breakdown**: Pie chart or bar chart
- [ ] **Trade Table**: Sortable, filterable table of all trades
- [ ] **Export Functionality**: Download reports as CSV/PDF

### Notifications Screen
- [ ] **Real-time Updates**: WebSocket connection for live alerts
- [ ] **Notification Actions**: Mark as read, delete, archive
- [ ] **Sound/Vibration**: Optional alerts for critical notifications
- [ ] **Notification Settings**: Configure which alerts to receive
- [ ] **Search Functionality**: Search through notification history

### Admin Screen
- [ ] **User Detail View**: Full user profile on tap
- [ ] **Edit User**: Modify user parameters (capital, tier, status)
- [ ] **Add New User**: Create user form
- [ ] **User Statistics**: Charts showing user performance
- [ ] **Bulk Actions**: Select multiple users for batch operations

---

## 📋 Missing / To Be Designed

### Additional Screens
- [ ] **Settings Screen**: App preferences, theme toggle, notifications
- [ ] **Profile Screen**: User profile, account details, preferences
- [ ] **Help/Support Screen**: FAQ, contact, documentation links

### Advanced Features
- [ ] **Dark/Light Theme Toggle**: Switch between themes
- [ ] **Charts Library Integration**: Use `fl_chart` or `syncfusion_flutter_charts`
- [ ] **Real-time Data**: WebSocket connections for live updates
- [ ] **Offline Mode**: Cache data for offline viewing
- [ ] **Push Notifications**: Mobile push notifications for alerts
- [ ] **Biometric Authentication**: Fingerprint/Face ID for login
- [ ] **Multi-language Support**: i18n for multiple languages

### UI/UX Enhancements
- [ ] **Loading States**: Skeleton loaders, shimmer effects
- [ ] **Error States**: Beautiful error pages with retry options
- [ ] **Empty States**: Engaging empty state illustrations
- [ ] **Animations**: Smooth transitions, micro-interactions
- [ ] **Pull-to-Refresh**: Refresh indicators on all screens
- [ ] **Swipe Actions**: Swipe to delete/archive in lists
- [ ] **Drag & Drop**: Reorder strategies, positions

### Data Visualization
- [ ] **Candlestick Charts**: For price action visualization
- [ ] **Volume Charts**: Trading volume indicators
- [ ] **Heatmaps**: Market overview heatmaps
- [ ] **Gauges**: Risk usage, drawdown gauges
- [ ] **Sparklines**: Mini charts in lists

---

## 🎯 Design Features from Lost Chats (To Be Recreated)

**Please add any design features you remember from your work with Jeeves/Grok here:**

### Example Format:
- [ ] **Feature Name**: Brief description
  - Details: What it should look like, where it appears
  - Status: Not started / In progress / Needs refinement

---

## 📐 Design Specifications

### Screen Layouts

#### Dashboard
```
┌─────────────────────────────────┐
│ App Bar (Status, API Key, Logout)│
├─────────────────────────────────┤
│ Backend Status Card              │
│ Account Summary (3 stats)        │
│ Demat Balance Card               │
│ Savings Balance Card             │
│ System Overview                  │
│ [Future: P&L Chart]              │
│ [Future: Recent Trades]          │
└─────────────────────────────────┘
```

#### Trade Screen
```
┌─────────────────────────────────┐
│ Strategy Controls                │
│ [Run Prediction] [Pause All]     │
├─────────────────────────────────┤
│ Open Positions (0)               │
│ [Empty State or Position List]   │
├─────────────────────────────────┤
│ Manual Override                  │
│ [Close All Positions]            │
└─────────────────────────────────┘
```

### Component Specifications

#### Account Balance Card
- **Height**: ~200px
- **Padding**: 16px all sides
- **Border Radius**: 12px
- **Icon Size**: 24px
- **Current Balance**: 24px font, bold
- **Change Indicator**: Badge with arrow icon

#### Button Styles
- **Primary**: Gold background, black text, 16px padding
- **Secondary**: Outlined, grey border, white text
- **Danger**: Red accent, white text
- **Icon Buttons**: 48x48px touch target

---

## 🔄 Next Steps

1. **Review this document** and add any missing features you remember
2. **Prioritize features** - What's most important to build next?
3. **Create mockups** - Sketch or describe any specific designs
4. **Implement incrementally** - Build one feature at a time

---

## 📝 Notes

- All designs should follow Material Design 3 principles
- Ensure accessibility (contrast ratios, touch targets)
- Responsive design for different screen sizes
- Performance: Optimize for 60fps animations

---

**Last Updated**: 2025-11-27
**Version**: v1.0 Beta

