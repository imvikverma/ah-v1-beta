# Enhanced Signup Flow - Implementation Plan

**Version:** 2.0 Beta  
**Date:** December 11, 2025

---

## 🎯 **What We're Building**

### **Multi-Step Signup Process:**

1. **Step 1:** Personal Details (Email, Phone, Password)
2. **Step 2:** Account Type Selection (Unique Plans)
3. **Step 3:** DigiLocker KYC (Aadhaar, PAN)
4. **Step 4:** Broker Connection (HDFC/Kotak)
5. **Step 5:** Consent & Legal (Multiple checkboxes)
6. **Step 6:** Confirmation & Welcome

---

## 📋 **Step 1: Personal Details**

**Fields:**
- Email *
- Phone *
- Username (optional)
- Password *
- Confirm Password *
- Date of Birth (optional - for birthday waivers)
- Anniversary (optional - for anniversary discounts)
- Profile Picture (optional)

**Same as current signup screen.**

---

## 🏆 **Step 2: Account Type Selection**

### **Unique Account Tiers (Your Branding):**

Instead of "Basic, Premium, Pro" → Use AurumHarmony themed names:

#### **🥉 Bronze Tier** (Free)
- **Name:** "Aurum Starter"
- **Tagline:** "Begin Your Trading Journey"
- **Features:**
  - ₹10,000 initial capital
  - 1 broker account
  - 50 trades/month on NIFTY50
  - 30 trades/month on BANKNIFTY
  - Paper trading only
  - Email support

#### **🥈 Silver Tier** (₹999/month)
- **Name:** "Aurum Trader"
- **Tagline:** "For Serious Traders"
- **Features:**
  - ₹50,000 initial capital
  - 2 broker accounts
  - 200 trades/month on NIFTY50
  - 100 trades/month on BANKNIFTY
  - Live + Paper trading
  - Priority email support
  - Advanced analytics

#### **🥇 Gold Tier** (₹4,999/month)
- **Name:** "Aurum Elite"
- **Tagline:** "Professional Trading Suite"
- **Features:**
  - ₹2,00,000 initial capital
  - 5 broker accounts
  - Unlimited trades
  - All indices (NIFTY, BANKNIFTY, SENSEX, FINNIFTY)
  - Live + Paper trading
  - 24/7 Priority support
  - Advanced analytics + AI insights
  - Custom automation
  - Dedicated account manager

### **Database Fields Added:**
```python
# In User model:
account_tier = Column(String(50), default='AURUM_STARTER')  # AURUM_STARTER, AURUM_TRADER, AURUM_ELITE
subscription_status = Column(String(20), default='ACTIVE')  # ACTIVE, EXPIRED, CANCELLED
subscription_expires_at = Column(DateTime, nullable=True)
```

---

## 🪪 **Step 3: DigiLocker KYC Integration**

### **What is DigiLocker?**
Government of India's digital document storage service. Users can:
- Link Aadhaar
- Fetch PAN card
- Download documents digitally
- Verify authenticity via API

### **Implementation:**

#### **Frontend (Flutter):**
1. Show DigiLocker button
2. Redirect to DigiLocker OAuth flow
3. User authorizes access
4. Callback receives documents
5. Upload to backend

#### **Backend Integration:**

**DigiLocker API Endpoints:**
- Authorization: `https://digilocker.meity.gov.in/public/oauth2/1/authorize`
- Token: `https://digilocker.meity.gov.in/public/oauth2/1/token`
- Fetch Documents: `https://digilocker.meity.gov.in/public/oauth2/2/file/{file_uri}`

**Required:**
- DigiLocker Client ID (register at https://partners.digitallocker.gov.in/)
- DigiLocker Client Secret
- Callback URL: `https://ah.saffronbolt.in/auth/digilocker/callback`

**New Database Table:**
```python
class KYCDocument(db.Model):
    __tablename__ = 'kyc_documents'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    document_type = Column(String(50))  # AADHAAR, PAN, etc.
    document_number = Column(String(100))  # Masked: XXXX-XXXX-1234
    document_url = Column(Text)  # Encrypted storage URL
    verified = Column(Boolean, default=False)
    verification_date = Column(DateTime, nullable=True)
    digilocker_doc_uri = Column(String(255))  # DigiLocker reference
    created_at = Column(DateTime, default=datetime.utcnow)
```

**Fields to Store:**
- Aadhaar Number (last 4 digits only)
- PAN Number
- Name (from Aadhaar)
- DOB (from Aadhaar - for verification)
- Address (from Aadhaar)

---

## 🏦 **Step 4: Broker Connection** ⭐ **[THIS IS WHAT YOU WANTED!]**

### **Flow:**

1. **Show Available Brokers:**
   - HDFC Sky (with logo)
   - Kotak Neo (with logo)
   - Skip for now (trade paper only)

2. **User Selects Broker:**
   - Clicks "Connect HDFC Sky" or "Connect Kotak Neo"

3. **OAuth/API Key Flow:**

#### **Option A: OAuth (Recommended)**
   - Redirect to broker's OAuth page
   - User authorizes AurumHarmony
   - Callback receives access token
   - Store encrypted in `broker_credentials` table

#### **Option B: Manual API Keys**
   - User enters API Key
   - User enters API Secret
   - Backend validates credentials
   - Store encrypted in `broker_credentials` table

4. **Validation:**
   - Test API connection
   - Fetch account balance
   - Verify broker account is active

5. **Store:**
   ```python
   BrokerCredential(
       user_id=user.id,
       broker_name='HDFC_SKY',  # or KOTAK_NEO
       api_key=encrypted_key,
       api_secret=encrypted_secret,
       is_active=True,
       last_validated=datetime.utcnow()
   )
   ```

### **UI Components:**

```dart
// Broker Card Widget
Card(
  child: Column(
    children: [
      Image.asset('assets/brokers/hdfc_logo.png'),
      Text('HDFC Sky'),
      Text('Connect your HDFC Securities account'),
      ElevatedButton(
        onPressed: () => connectBroker('HDFC_SKY'),
        child: Text('Connect Now'),
      ),
    ],
  ),
)
```

### **Backend Endpoints:**

```python
@brokers_bp.route('/connect/hdfc', methods=['POST'])
def connect_hdfc_broker():
    # Initiate OAuth flow or validate API keys
    pass

@brokers_bp.route('/connect/kotak', methods=['POST'])
def connect_kotak_broker():
    # Initiate OAuth flow or validate API keys
    pass

@brokers_bp.route('/validate/<broker_name>', methods=['POST'])
def validate_broker_connection(broker_name):
    # Test API connection
    pass
```

---

## 📜 **Step 5: Consent & Legal**

### **Multiple Checkboxes (All Required):**

1. **Terms & Conditions** ✅ *Required*
   - Link: `/legal/terms`
   - Full legal terms

2. **Privacy Policy** ✅ *Required*
   - Link: `/legal/privacy`
   - How we use your data

3. **SEBI Risk Disclosure** ✅ *Required*
   - Link: `/legal/sebi-risk-disclosure`
   - Trading risks, potential losses

4. **Broker Terms** ✅ *Required (if broker connected)*
   - HDFC Sky Terms
   - Kotak Neo Terms

5. **Marketing Communications** ❌ *Optional*
   - Newsletters, updates
   - Can opt-out anytime

6. **Data Sharing Consent** ✅ *Required*
   - Share data with broker
   - Required for live trading

### **Database Fields:**

```python
# In User model:
terms_accepted = Column(Boolean, default=False)
terms_accepted_at = Column(DateTime, nullable=True)
privacy_accepted = Column(Boolean, default=False)
privacy_accepted_at = Column(DateTime, nullable=True)
sebi_risk_accepted = Column(Boolean, default=False)
sebi_risk_accepted_at = Column(DateTime, nullable=True)
broker_terms_accepted = Column(Boolean, default=False)
broker_terms_accepted_at = Column(DateTime, nullable=True)
marketing_consent = Column(Boolean, default=False)
marketing_consent_at = Column(DateTime, nullable=True)
data_sharing_consent = Column(Boolean, default=False)
data_sharing_consent_at = Column(DateTime, nullable=True)
```

### **UI:**

```dart
CheckboxListTile(
  title: Text('I accept the Terms & Conditions'),
  subtitle: Text('Read terms', style: TextStyle(color: Colors.blue)),
  value: _termsAccepted,
  onChanged: (value) => setState(() => _termsAccepted = value),
  onTap: () => openTermsDialog(),
)
```

---

## ✅ **Step 6: Confirmation & Welcome**

### **Summary Screen:**

```
✅ Account Created Successfully!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📧 Email: user@example.com
📱 Phone: +91 98765 43210
👤 Username: johndoe
🎂 Birthday: June 15 (Fee waivers!)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏆 Account Tier: Aurum Trader (Silver)
💰 Initial Capital: ₹50,000
📊 Max Trades: 200/month NIFTY, 100/month BANKNIFTY

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🪪 KYC Status: ✅ Verified (DigiLocker)
   - Aadhaar: XXXX-XXXX-1234
   - PAN: XXXXX1234X

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏦 Connected Brokers:
   - ✅ HDFC Sky (Account verified)
   - ⚠️  Kotak Neo (Not connected)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Continue to Dashboard]
```

---

## 🗄️ **Database Schema Updates**

### **New Tables:**

```python
class KYCDocument(db.Model):
    __tablename__ = 'kyc_documents'
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    document_type = Column(String(50))
    document_number = Column(String(100))
    document_url = Column(Text)
    verified = Column(Boolean, default=False)
    verification_date = Column(DateTime)
    digilocker_doc_uri = Column(String(255))
    created_at = Column(DateTime, default=datetime.utcnow)
```

### **User Model Updates:**

```python
# Add to User model:
account_tier = Column(String(50), default='AURUM_STARTER')
subscription_status = Column(String(20), default='ACTIVE')
subscription_expires_at = Column(DateTime, nullable=True)
kyc_verified = Column(Boolean, default=False)
kyc_verified_at = Column(DateTime, nullable=True)

# Consent fields
privacy_accepted = Column(Boolean, default=False)
privacy_accepted_at = Column(DateTime, nullable=True)
sebi_risk_accepted = Column(Boolean, default=False)
sebi_risk_accepted_at = Column(DateTime, nullable=True)
broker_terms_accepted = Column(Boolean, default=False)
broker_terms_accepted_at = Column(DateTime, nullable=True)
marketing_consent = Column(Boolean, default=False)
data_sharing_consent = Column(Boolean, default=False)
```

---

## 🎨 **UI/UX Design**

### **Progress Indicator:**

```
Step 1 of 6: Personal Details
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[●●●●●●○○○○○○○○○○○○○○○○○○]  25%
```

### **Navigation:**
- ✅ Back button (goes to previous step)
- ✅ Next button (validates & proceeds)
- ✅ Skip button (for optional steps)
- ✅ Save & Continue Later (stores progress)

---

## 📱 **Implementation Priority**

### **Phase 1: Must Have (This Week)**
1. ✅ Multi-step UI structure
2. ✅ Account tier selection
3. ✅ Broker connection flow (manual API keys)
4. ✅ Enhanced consent checkboxes

### **Phase 2: Nice to Have (Next Week)**
1. DigiLocker KYC integration
2. Broker OAuth flow
3. Save & continue later
4. Progress persistence

### **Phase 3: Future**
1. Document verification AI
2. Video KYC
3. Automated compliance checks
4. Advanced broker integrations

---

## 🔗 **Reminder for Later:**

### **⭐ EXPAND ON BROKER CONNECTION:**
- OAuth vs Manual API keys
- Which brokers support OAuth?
- How to handle token refresh?
- Multi-broker support (connect 2+ brokers)
- Broker switching during trading
- Fallback if one broker is down

**🎯 REMINDER SET:** Expand on broker connection implementation details!

---

## 📊 **Summary**

| Feature | Status | Priority |
|---------|--------|----------|
| Multi-step signup | 🔄 To implement | High |
| Account tiers (unique names) | 🔄 To implement | High |
| Broker connection | 🔄 To implement | **CRITICAL** |
| DigiLocker KYC | 📋 Planned | Medium |
| Enhanced consent | 🔄 To implement | High |
| Progress saving | 📋 Planned | Low |

---

**Next Step:** Create the multi-step signup screen structure!

**Estimated Time:** 4-6 hours for Phase 1

**Ready to start building?** 🚀

