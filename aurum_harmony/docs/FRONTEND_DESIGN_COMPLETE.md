# AurumHarmony Frontend - Complete Design Documentation
**Version:** 1.0 Beta  
**Date:** December 11, 2025  
**Platform:** Flutter (Web, Android, iOS, Windows)

---

## 🎨 Design Overview

AurumHarmony features a modern, professional trading interface built with Flutter for cross-platform compatibility. The design emphasizes:

- **Clean UI/UX** - Minimal clutter, focus on key metrics
- **Real-time Updates** - Live market data and position tracking
- **Automated Trading** - Paper trading with one-click execution
- **Mobile-First** - Responsive design for all screen sizes

---

## 📱 Screen Architecture

### **1. Onboarding Screen** (`onboarding_screen.dart`)
**Purpose:** Welcome new users and explain AurumHarmony features

**Elements:**
- App logo and branding
- Feature highlights carousel
- "Get Started" CTA button
- Skip option

**Navigation:** → Login or Signup Screen

---

### **2. Login Screen** (`login_screen.dart`)
**Purpose:** User authentication

**Elements:**
- Email/Phone input field
- Password input field (secure)
- "Login" button
- "Forgot Password?" link
- "Don't have an account? Sign up" link

**API Endpoint:** `POST /api/auth/login`

**Success Flow:** → Dashboard Screen

---

### **3. Signup Screen** (`signup_screen.dart`)
**Purpose:** New user registration

**Elements:**
- Email input field
- Phone input field
- Username input field
- Password input field (secure, min 6 chars)
- Profile picture upload (optional)
- Terms & Conditions checkbox (required)
- "Create Account" button
- "Already have an account? Login" link

**API Endpoint:** `POST /api/auth/register`

**Success Flow:** → Login Screen

**Validation:**
- Email format check
- Password strength (min 6 characters)
- Terms acceptance required

---

### **4. Dashboard Screen** (`dashboard_screen.dart`)
**Purpose:** Main overview with key metrics

**Elements:**

#### **Top Section:**
- User greeting ("Welcome back, [Username]!")
- Account balance card (₹10,000 initial capital)
- Today's P&L (profit/loss)

#### **Middle Section - Cards:**
1. **Portfolio Value** - Current total value
2. **Active Positions** - Number of open positions
3. **Today's Trades** - Trades executed today

#### **Bottom Section:**
- Recent activity feed
- Quick action buttons

**API Endpoints:**
- `GET /api/auth/me` - User info
- `GET /api/positions` - Current positions (if available)

**Updates Removed:**
- ❌ "Next Increment Countdown" (removed per user request)

---

### **5. Trade Screen** (`trade_screen.dart`)
**Purpose:** Execute trades and view predictions

**Elements:**

#### **Top Section:**
- "Run Prediction" button (primary action)
  - **Functionality:** Triggers `/api/orchestrator/run`
  - **Result:** Automatically executes paper trades
  - **Display:** Shows signals processed, orders executed, orders rejected

#### **Middle Section:**
- **Paper Trading (Automatic)** card
  - Informational: "Paper trading runs automatically"
  - Shows current mode status
  - No manual order dialogs

#### **Bottom Section:**
- Current positions list
  - Symbol
  - Side (BUY/SELL)
  - Quantity
  - P&L

**API Endpoints:**
- `POST /api/orchestrator/run` - Execute predictions
- `GET /api/positions` - View positions

**Features Removed:**
- ❌ Manual "Place Order" dialog (automated only)
- ❌ User-interactive trading dialogs

---

### **6. Notifications Screen** (`notifications_screen.dart`)
**Purpose:** Display alerts and system messages

**Elements:**
- Notification list with:
  - Title
  - Message
  - Timestamp
  - Read/Unread indicator

**Interactions:**
- **Tap notification** → Mark as read + Show details in SnackBar
- Auto-refresh on screen load

**API Endpoint:** `GET /api/notifications` (if implemented)

**Recent Updates:**
- ✅ Added tap-to-read functionality
- ✅ Mark as read on tap

---

### **7. Reports Screen** (`reports_screen.dart`)
**Purpose:** View trading performance and analytics

**Elements:**
- Date range selector
- Performance charts:
  - P&L over time
  - Win rate
  - Average trade return
- Trade history table
- Export options (PDF, CSV)

**API Endpoints:**
- `GET /api/reports` - Performance data
- `GET /api/trades` - Trade history

**Token Expiration Handling:**
- ✅ Inline error message (no popup)
- ✅ Auto-logout on 401

---

### **8. Broker Settings Screen** (`broker_settings_screen.dart`)
**Purpose:** Manage broker API credentials

**Elements:**
- Broker selection dropdown:
  - Kotak Neo
  - HDFC Sky
- API credentials form:
  - API Key
  - API Secret
  - Access Token (auto-generated)
- "Connect Broker" button
- Active broker status indicator

**API Endpoints:**
- `POST /api/brokers/kotak/connect`
- `POST /api/brokers/hdfc/connect`
- `GET /api/brokers/status`

---

### **9. Admin Screen** (`admin_screen.dart`)
**Purpose:** Admin panel for user management (admin users only)

**Elements:**
- User list with:
  - Email
  - User Code
  - Status (Active/Inactive)
  - Admin flag
- User actions:
  - View details
  - Edit user
  - Deactivate/Activate
- Database admin functions (if admin_db enabled)

**API Endpoints:**
- `GET /api/admin/users` - List all users
- `POST /api/admin/users/{id}` - Update user
- `GET /api/admin/db/*` - Database queries

**Token Expiration Handling:**
- ✅ Inline error display
- ✅ Auto-logout on expiration

---

## 🎨 Design System

### **Colors**
```dart
Primary Color: #FFD700 (Gold) - AurumHarmony branding
Accent Color: #4A90E2 (Blue) - Interactive elements
Success: #4CAF50 (Green) - Positive P&L, completed actions
Error: #F44336 (Red) - Negative P&L, errors
Warning: #FF9800 (Orange) - Alerts
Background: #FFFFFF (White) - Main background
Surface: #F5F5F5 (Light Gray) - Cards, sections
Text Primary: #212121 (Dark Gray)
Text Secondary: #757575 (Medium Gray)
```

### **Typography**
- **Headers:** Roboto Bold, 24-32px
- **Body:** Roboto Regular, 14-16px
- **Captions:** Roboto Light, 12px
- **Numbers (P&L):** Roboto Mono, 18-24px

### **Components**
- **Cards:** Elevated, rounded corners (8px), shadow
- **Buttons:** 
  - Primary: Filled, gold (#FFD700)
  - Secondary: Outlined, blue (#4A90E2)
  - Height: 48px
- **Input Fields:** Outlined, rounded (4px), gray border
- **Navigation:** Bottom navigation bar (5 tabs)

---

## 🔄 Navigation Structure

```
Onboarding → Login/Signup → Dashboard (Main)
                                 ├── Dashboard Tab
                                 ├── Trade Tab
                                 ├── Notifications Tab
                                 ├── Reports Tab
                                 └── Settings Tab
                                       ├── Broker Settings
                                       ├── Profile
                                       └── Admin (if admin user)
```

### **Bottom Navigation Bar:**
1. 🏠 Dashboard
2. 📈 Trade
3. 🔔 Notifications
4. 📊 Reports
5. ⚙️ Settings

---

## 🔐 Authentication Flow

1. **App Launch** → Check stored token
2. **Token Valid** → Dashboard
3. **Token Invalid/Expired** → Login Screen
4. **Login Success** → Store token → Dashboard
5. **Token Expires (24h)** → Auto-logout → Login Screen (no popup)

**Token Storage:** `shared_preferences` (Flutter)

**Token Format:** JWT Bearer Token

**Expiration Handling:**
- ✅ Silent logout
- ✅ Inline error message: "Session expired. Please refresh the page and login again."
- ❌ No SnackBar popup

---

## 📡 API Integration

### **Base URLs:**
- **Backend API:** `http://localhost:5000` (dev) / `https://api.ah.saffronbolt.in` (prod)
- **Admin API:** `http://localhost:5001` (dev)
- **Cloudflare Worker:** `https://api.ah.saffronbolt.in` (prod)

### **Authentication:**
All authenticated requests include:
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

### **Error Handling:**
- **401 Unauthorized:** Auto-logout, show "Session expired"
- **404 Not Found:** Show "Endpoint not available"
- **500 Server Error:** Show "Backend error, please try again"
- **Network Error:** Show "Cannot connect to backend. Please check connection."

---

## 🚀 Key Features Implemented

### ✅ **Automated Paper Trading**
- One-click prediction execution
- No manual order dialogs
- Automatic trade execution via orchestrator
- Real-time order status updates

### ✅ **Token Expiration Management**
- 24-hour JWT token validity
- Automatic logout on expiration
- Inline error messages (no popups)

### ✅ **Responsive Design**
- Works on Web, Android, iOS, Windows
- Mobile-first approach
- Adaptive layouts for all screen sizes

### ✅ **Real-time Updates**
- Live P&L tracking (when positions exist)
- Notification updates
- Position refresh after trades

---

## 🎯 User Experience Improvements

### **Recent Enhancements:**
1. ✅ Removed "Next Increment Countdown" from dashboard
2. ✅ Removed manual "Place Order" dialog (automated only)
3. ✅ Added tap-to-read for notifications
4. ✅ Improved token expiration handling (no popups)
5. ✅ Added functional "Run Prediction" button
6. ✅ Auto-reload positions after orchestrator execution

---

## 📱 Platform-Specific Notes

### **Web:**
- Runs on `http://localhost:58643` (dev)
- Deployed to Cloudflare Pages (prod)
- Hot reload enabled in dev mode

### **Android:**
- Min SDK: 21 (Android 5.0)
- Target SDK: 33 (Android 13)
- Package: `in.saffronbolt.aurumharmony`

### **iOS:**
- Min iOS: 11.0
- Swift 5
- Bundle ID: `in.saffronbolt.aurumharmony`

### **Windows:**
- Win32 desktop app
- Min Windows 10

---

## 🔧 Development Setup

### **Run Flutter App:**
```bash
cd aurum_harmony/frontend/flutter_app
flutter pub get
flutter run -d chrome  # Web
flutter run -d windows  # Windows
flutter run  # Auto-detect device
```

### **Build for Production:**
```bash
flutter build web  # Web (Cloudflare Pages)
flutter build apk  # Android
flutter build ipa  # iOS
flutter build windows  # Windows
```

---

## 📊 Future Enhancements

### **Planned Features:**
- [ ] Real-time charts (candlestick, line)
- [ ] Push notifications
- [ ] Biometric authentication
- [ ] Dark mode toggle
- [ ] Multi-language support
- [ ] Advanced order types (limit, stop-loss)
- [ ] Portfolio analytics dashboard
- [ ] Social trading features

---

## 📞 Support & Feedback

For design feedback or feature requests:
- **Email:** support@saffronbolt.in
- **Twitter:** @SaffronBolt
- **Waitlist:** 47+ traders signed up

---

**Last Updated:** December 11, 2025  
**Version:** 1.0 Beta  
**Status:** Production-Ready (90% complete)

