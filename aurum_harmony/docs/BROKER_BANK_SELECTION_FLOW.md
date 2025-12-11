# Broker & Bank Account Selection Flow

**Version:** 2.0 Beta  
**Date:** December 11, 2025

---

## 🏦 **Broker Selection During Signup**

### **Step 4a: Choose Your Broker(s)**

**Popup/Modal with Broker List:**

```
┌────────────────────────────────────────────────┐
│  Connect Your Trading Account                  │
│  Choose 1-2 brokers based on your plan        │
├────────────────────────────────────────────────┤
│                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ [Logo]   │  │ [Logo]   │  │ [Logo]   │    │
│  │ Zerodha  │  │ HDFC Sky │  │ Kotak Neo│    │
│  │ ✅ Most  │  │ ⭐ Premium│  │ 💼 Bank  │    │
│  │  Popular │  │   Choice │  │   Backed │    │
│  └──────────┘  └──────────┘  └──────────┘    │
│                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ [Logo]   │  │ [Logo]   │  │ [Logo]   │    │
│  │ Upstox   │  │ Angel One│  │ 5Paisa   │    │
│  │ 📱 Mobile│  │ 📊 Research│ │ 💰 Low   │    │
│  │   First  │  │   Tools  │  │   Fees   │    │
│  └──────────┘  └──────────┘  └──────────┘    │
│                                                │
│  ┌──────────┐  ┌──────────┐                   │
│  │ [Logo]   │  │ [Logo]   │                   │
│  │ Groww    │  │ ICICI    │                   │
│  │ 🎯 Simple│  │ 🏛️ Legacy│                   │
│  └──────────┘  └──────────┘                   │
│                                                │
│  Selected: HDFC Sky, Kotak Neo (2/2)          │
│                                                │
│  [Continue]  [Skip for Now - Paper Trading]   │
└────────────────────────────────────────────────┘
```

---

## 📋 **8-9 Broker Options**

### **1. Zerodha** 🥇
- **Status:** Most Popular
- **Features:** Low brokerage, good platform
- **API Support:** ✅ Kite Connect API
- **OAuth:** ✅ Yes
- **Manual Keys:** ✅ Yes

### **2. HDFC Sky** ⭐
- **Status:** Premium Choice
- **Features:** Research + Trading, Bank integration
- **API Support:** ✅ HDFC Sky API
- **OAuth:** ✅ Yes
- **Manual Keys:** ✅ Yes

### **3. Kotak Neo** 💼
- **Status:** Bank Backed
- **Features:** Kotak Bank integration, reliable
- **API Support:** ✅ Neo API
- **OAuth:** ✅ Yes
- **Manual Keys:** ✅ Yes

### **4. Upstox** 📱
- **Status:** Mobile First
- **Features:** Best mobile app, fast execution
- **API Support:** ✅ Upstox API
- **OAuth:** ✅ Yes
- **Manual Keys:** ✅ Yes

### **5. Angel One (formerly Angel Broking)** 📊
- **Status:** Research Leader
- **Features:** Excellent research tools, ARQ engine
- **API Support:** ✅ SmartAPI
- **OAuth:** ✅ Yes
- **Manual Keys:** ✅ Yes

### **6. 5Paisa** 💰
- **Status:** Low Cost
- **Features:** Lowest brokerage fees
- **API Support:** ✅ 5Paisa API
- **OAuth:** ❌ No
- **Manual Keys:** ✅ Yes

### **7. Groww** 🎯
- **Status:** Beginner Friendly
- **Features:** Simple UI, educational content
- **API Support:** ⚠️ Limited
- **OAuth:** ❌ No
- **Manual Keys:** ✅ Yes

### **8. ICICI Direct** 🏛️
- **Status:** Legacy/Established
- **Features:** ICICI Bank integration, trusted
- **API Support:** ✅ ICICI API
- **OAuth:** ✅ Yes
- **Manual Keys:** ✅ Yes

### **9. Paytm Money** 💳
- **Status:** Fintech
- **Features:** UPI integration, digital wallet
- **API Support:** ⚠️ Limited
- **OAuth:** ❌ No
- **Manual Keys:** ✅ Yes

---

## 🏦 **Bank Account Selection**

### **Step 4b: Link Your Bank Account(s)**

**Same popup/modal style:**

```
┌────────────────────────────────────────────────┐
│  Connect Your Savings Account                  │
│  Required for fund transfers                   │
├────────────────────────────────────────────────┤
│                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ [Logo]   │  │ [Logo]   │  │ [Logo]   │    │
│  │ HDFC Bank│  │ ICICI    │  │ SBI      │    │
│  │ 🏦 Private│ │ 🏦 Private│ │ 🏛️ Public│    │
│  └──────────┘  └──────────┘  └──────────┘    │
│                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ [Logo]   │  │ [Logo]   │  │ [Logo]   │    │
│  │ Kotak    │  │ Axis Bank│  │ IDFC First│   │
│  │ 💼 Private│ │ 💳 Digital│ │ 🚀 Modern│    │
│  └──────────┘  └──────────┘  └──────────┘    │
│                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ [Logo]   │  │ [Logo]   │  │ [Logo]   │    │
│  │ Paytm    │  │ PhonePe  │  │ Others   │    │
│  │ 💰 Wallet│  │ 📱 UPI   │  │          │    │
│  └──────────┘  └──────────┘  └──────────┘    │
│                                                │
│  Selected: HDFC Bank (1/2)                    │
│                                                │
│  [Continue]                                    │
└────────────────────────────────────────────────┘
```

---

## 🔀 **Two User Flows**

### **Flow A: Existing User** (Already have accounts)

```
┌─────────────────────────────────────────────┐
│ Do you already have a trading account?      │
├─────────────────────────────────────────────┤
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │  ✅ Yes, I have existing accounts     │ │
│  │  Link my Zerodha & HDFC accounts     │ │
│  └───────────────────────────────────────┘ │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │  ❌ No, I need to open accounts       │ │
│  │  Help me create new accounts         │ │
│  └───────────────────────────────────────┘ │
│                                             │
└─────────────────────────────────────────────┘
```

#### **If "Yes - Existing Accounts":**

**1. Select Broker(s):**
   - Show list of 8-9 brokers
   - User clicks on Zerodha + HDFC Sky
   - Max 2 selections based on tier

**2. Connection Method:**
```
┌─────────────────────────────────────────────┐
│ How would you like to connect?             │
├─────────────────────────────────────────────┤
│                                             │
│  🔐 Quick Connect (OAuth - Recommended)    │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│  • Secure & instant                        │
│  • Auto token refresh                      │
│  • No manual key management                │
│  [Connect with Zerodha OAuth]              │
│                                             │
│  🔑 Manual API Keys                        │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│  • For advanced users                      │
│  • More control                            │
│  • Requires API key from broker portal     │
│  [Enter API Keys Manually]                 │
│                                             │
└─────────────────────────────────────────────┘
```

**3a. OAuth Flow (Recommended):**
   - Redirect to broker's OAuth page
   - User logs in with broker credentials
   - Authorizes AurumHarmony
   - Auto-redirects back with token
   - ✅ Connection successful!

**3b. Manual Keys Flow:**
```
┌─────────────────────────────────────────────┐
│ Enter Your Zerodha API Credentials          │
├─────────────────────────────────────────────┤
│                                             │
│  API Key: [____________________________]    │
│                                             │
│  API Secret: [____________________________] │
│                                             │
│  ℹ️  Where to find your API keys:          │
│  1. Login to Kite Connect                  │
│  2. Go to Apps → Create New App            │
│  3. Copy API Key & Secret                  │
│  [Open Kite Connect Portal]                │
│                                             │
│  [Test Connection]  [Save & Continue]      │
└─────────────────────────────────────────────┘
```

**4. Verify Connection:**
   - Backend calls broker API
   - Fetches account details
   - Shows confirmation:
   ```
   ✅ Connected to Zerodha
   
   Account: ZE123456
   Status: Active
   Balance: ₹45,230
   ```

**5. Repeat for Bank Account:**
   - Similar flow
   - Link via bank OAuth or account number
   - Verify using penny drop (₹1 deposit + withdrawal)

---

### **Flow B: New User** (Need to create accounts)

#### **If "No - Need New Accounts":**

**1. Guided Account Opening:**

```
┌─────────────────────────────────────────────┐
│ Let's Open Your Trading Account            │
├─────────────────────────────────────────────┤
│                                             │
│  We'll help you open accounts with:        │
│                                             │
│  ✅ Zerodha (Selected)                     │
│  ✅ HDFC Bank (Selected)                   │
│                                             │
│  📋 What you'll need:                      │
│  • PAN Card (from DigiLocker)              │
│  • Aadhaar (from DigiLocker)               │
│  • Bank Account (we'll help create)        │
│  • Signature (digital)                     │
│                                             │
│  ⏱️ Estimated time: 15-20 minutes          │
│                                             │
│  [Start Account Opening]  [Change Broker]  │
└─────────────────────────────────────────────┘
```

**2. Pre-fill with DigiLocker Data:**
   - Name (from Aadhaar)
   - DOB (from Aadhaar)
   - Address (from Aadhaar)
   - PAN (from DigiLocker)

**3. Open Broker Account (via Partner API):**

**Option A: Direct Integration (if available)**
   - Zerodha Partner API
   - HDFC Sky Partner API
   - Instant account opening
   - KYC auto-approved

**Option B: Referral Link (if no API)**
   - Generate unique referral link
   - Track user progress
   - Callback when account is opened
   - Rewards for successful signup

**Example - Zerodha Partner API:**
```python
# Backend calls Zerodha Partner API
zerodha_partner_api.create_account({
    'name': user.name,
    'pan': user.pan,
    'dob': user.dob,
    'email': user.email,
    'phone': user.phone,
    'partner_id': 'AURUMHARMONY',
    'referral_code': f'AH{user.user_code}'
})

# Response:
{
    'status': 'pending',
    'application_id': 'ZE2025123456',
    'next_step': 'in_person_verification',
    'estimated_approval': '24-48 hours'
}
```

**4. Wait for Approval:**
```
┌─────────────────────────────────────────────┐
│ Account Opening In Progress...              │
├─────────────────────────────────────────────┤
│                                             │
│  ⏳ Zerodha Account                        │
│  Status: Pending Approval                  │
│  Application ID: ZE2025123456              │
│  Next Step: Video KYC scheduled            │
│  Estimated: 24-48 hours                    │
│                                             │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                             │
│  Meanwhile, you can:                       │
│  • Practice with Paper Trading             │
│  • Complete onboarding tutorials           │
│  • Set up your preferences                 │
│                                             │
│  📧 We'll email you when approved!         │
│                                             │
│  [Continue to Dashboard]                   │
└─────────────────────────────────────────────┘
```

**5. Account Approved - Link It:**
   - Email notification
   - SMS notification
   - In-app notification
   - User returns → Links new account via OAuth/API keys

---

## 🗄️ **Database Schema**

### **New Table: `broker_accounts`**

```python
class BrokerAccount(db.Model):
    __tablename__ = 'broker_accounts'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    broker_name = Column(String(50))  # ZERODHA, HDFC_SKY, KOTAK_NEO, etc.
    broker_display_name = Column(String(100))  # "Zerodha", "HDFC Sky"
    
    # Account status
    connection_status = Column(String(20))  # CONNECTED, PENDING, DISCONNECTED, EXPIRED
    account_type = Column(String(20))  # EXISTING, NEW_PENDING, NEW_APPROVED
    
    # For existing accounts
    broker_account_id = Column(String(100))  # Broker's client ID
    broker_user_id = Column(String(100))  # Broker's user ID
    
    # For new accounts (pending)
    application_id = Column(String(100))  # Broker's application reference
    application_status = Column(String(50))  # SUBMITTED, IN_REVIEW, APPROVED, REJECTED
    approval_date = Column(DateTime, nullable=True)
    
    # Connection method
    connection_method = Column(String(20))  # OAUTH, API_KEYS, PENDING
    
    # Credentials (encrypted)
    api_key = Column(Text, nullable=True)
    api_secret = Column(Text, nullable=True)
    access_token = Column(Text, nullable=True)
    refresh_token = Column(Text, nullable=True)
    token_expires_at = Column(DateTime, nullable=True)
    
    # Metadata
    is_primary = Column(Boolean, default=False)  # Primary trading account
    is_active = Column(Boolean, default=True)
    last_validated = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow)
```

### **New Table: `bank_accounts`**

```python
class BankAccount(db.Model):
    __tablename__ = 'bank_accounts'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    bank_name = Column(String(100))  # HDFC, ICICI, SBI, etc.
    bank_display_name = Column(String(100))  # "HDFC Bank"
    
    # Account details
    account_number = Column(String(100))  # Encrypted
    ifsc_code = Column(String(20))
    account_holder_name = Column(String(200))
    account_type = Column(String(20))  # SAVINGS, CURRENT
    
    # Verification
    verification_status = Column(String(20))  # PENDING, VERIFIED, FAILED
    verification_method = Column(String(20))  # PENNY_DROP, OAUTH, MANUAL
    verified_at = Column(DateTime, nullable=True)
    
    # For new accounts
    is_new_account = Column(Boolean, default=False)
    application_status = Column(String(50))  # For bank account opening
    
    # Metadata
    is_primary = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow)
```

---

## 📱 **UI Components**

### **Broker Selection Card:**

```dart
class BrokerCard extends StatelessWidget {
  final String brokerName;
  final String logo;
  final String tagline;
  final bool isSelected;
  final VoidCallback onTap;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        child: Column(
          children: [
            Image.asset(logo, height: 60),
            Text(brokerName, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(tagline, style: TextStyle(fontSize: 12, color: Colors.grey)),
            if (isSelected) Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔄 **Account Tier Limits**

| Tier | Max Brokers | Max Banks | Connection Method |
|------|-------------|-----------|-------------------|
| Aurum Starter | 1 | 1 | OAuth or API Keys |
| Aurum Trader | 2 | 2 | OAuth or API Keys |
| Aurum Elite | 5 | 3 | OAuth or API Keys |

---

## 🎯 **Implementation Checklist**

### **Phase 1: Existing Users Flow**
- [ ] Create broker selection modal with 8-9 options
- [ ] Implement max selection limit (1-2 based on tier)
- [ ] Add OAuth flow for supported brokers
- [ ] Add manual API key input form
- [ ] Test connection validation
- [ ] Store encrypted credentials
- [ ] Repeat for bank accounts

### **Phase 2: New Users Flow**
- [ ] Add "New Account" option
- [ ] Partner API integration (Zerodha, HDFC, etc.)
- [ ] OR referral link generation
- [ ] Track application status
- [ ] Email/SMS notifications on approval
- [ ] Link newly created accounts

### **Phase 3: Advanced Features**
- [ ] Multi-broker switching
- [ ] Broker fallback (if one is down)
- [ ] Token auto-refresh
- [ ] Account health monitoring
- [ ] Broker comparison tool

---

## 📞 **Broker Partner APIs**

### **1. Zerodha - Kite Connect Partner**
- Website: https://kite.trade/
- Partner Program: https://zerodha.com/partners/
- API Docs: https://kite.trade/docs/connect/v3/

### **2. HDFC Sky - Partner Program**
- Contact: HDFC Securities Partnership Team
- Partner Portal: (Requires partnership agreement)

### **3. Kotak Neo - API Partner**
- Website: https://neo.kotak.com/
- API Docs: https://neo.kotaksecurities.com/

(Continue for other brokers...)

---

## ✅ **Summary**

**User Flow:**
1. Sign up → Choose account tier
2. **Popup: Select 1-2 brokers** (from 8-9 options)
3. **Choose: Existing or New account**
4. **If Existing:** Link via OAuth or API keys
5. **If New:** Guided account opening → Wait for approval
6. **Repeat for bank accounts**
7. Continue to dashboard

---

**Ready to implement?** This will be a game-changer for onboarding! 🚀

