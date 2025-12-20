# Signup Process Improvements - Implementation Guide

## ✅ Completed Features

### Frontend (Flutter)
1. **Password Strength Indicator**
   - Real-time strength calculation (weak/fair/good/strong)
   - Visual progress bar with color coding
   - Located in: `lib/utils/password_strength.dart`

2. **Terms & Conditions Checkbox**
   - Required checkbox with validation
   - Links to Terms & Conditions and Privacy Policy
   - Styled with primary color

3. **Phone Number Formatting**
   - Auto-formats Indian phone numbers (+91 format)
   - Real-time formatting as user types
   - Located in: `lib/utils/phone_formatter.dart`

4. **Username/Display Name Field**
   - Optional field for user display name
   - Validation: 3+ characters, alphanumeric + underscores only

5. **Profile Picture Upload**
   - Tap to add/edit profile picture
   - Options: Gallery or Camera
   - Image compression (512x512, 85% quality)
   - Uses `image_picker` package

6. **Welcome Onboarding Flow**
   - 4-page onboarding experience
   - Skip option available
   - Smooth page transitions
   - Located in: `lib/screens/onboarding_screen.dart`

7. **Enhanced UI/UX**
   - Better form layout
   - Improved spacing and typography
   - Profile picture circle avatar
   - Better error handling

### Backend Updates

#### Worker API (`worker/src/index.ts`)
- Updated `/api/auth/register` endpoint to accept:
  - `username` (optional)
  - `profile_picture_url` (optional)
  - `terms_accepted` (required)
- Added email verification token generation
- Enhanced user creation with new fields

#### Flask API (`aurum_harmony/auth/routes.py`)
- Updated `/api/auth/register` endpoint to accept new fields
- Added validation for `terms_accepted`

#### Auth Service (`aurum_harmony/frontend/flutter_app/lib/services/auth_service.dart`)
- Updated `register()` method with new parameters:
  - `username` (optional)
  - `profile_picture_url` (optional)
  - `termsAccepted` (required)

## 📋 Database Migration Required

### D1 Database (Cloudflare)
Run the migration script:
```powershell
wrangler d1 execute aurum-harmony-db --remote --file=worker/schema_migration_signup_improvements.sql
```

This adds:
- `username` TEXT
- `profile_picture_url` TEXT
- `email_verified` INTEGER DEFAULT 0
- `email_verification_token` TEXT
- `terms_accepted` INTEGER DEFAULT 0
- `terms_accepted_at` TEXT

### SQLite Database (Flask)
Update the User model in `aurum_harmony/database/models.py`:
```python
username = Column(String(100), nullable=True, index=True)
profile_picture_url = Column(String(500), nullable=True)
email_verified = Column(Boolean, default=False, nullable=False)
email_verification_token = Column(String(255), nullable=True)
terms_accepted = Column(Boolean, default=False, nullable=False)
terms_accepted_at = Column(DateTime, nullable=True)
```

Then run a migration or manually add columns:
```python
# In Python shell or migration script
from aurum_harmony.database.db import db
db.session.execute(db.text('ALTER TABLE users ADD COLUMN username TEXT'))
db.session.execute(db.text('ALTER TABLE users ADD COLUMN profile_picture_url TEXT'))
# ... (add other columns)
db.session.commit()
```

## 🚀 Next Steps

1. **Install Flutter Dependencies**
   ```bash
   cd aurum_harmony/frontend/flutter_app
   flutter pub get
   ```

2. **Run Database Migrations**
   - D1: Use the migration script provided
   - SQLite: Update model and run migration

3. **Test Signup Flow**
   - Test with Worker API
   - Test with Flask API (fallback)
   - Verify all fields are saved correctly
   - Test onboarding flow

4. **Profile Picture Upload**
   - Currently saves locally
   - TODO: Implement cloud storage upload (Cloudflare R2, AWS S3, etc.)
   - Update `signup_screen.dart` `_handleSignUp()` method

5. **Email Verification**
   - Basic structure in place
   - TODO: Implement email sending service
   - TODO: Create verification endpoint

## 📝 Notes

- Profile picture upload currently saves to local file system
- Email verification token is generated but not yet used
- Terms & Conditions links are placeholders (update with actual URLs)
- Onboarding screen navigates to Dashboard after completion
- All new fields are optional except `terms_accepted`

## 🐛 Known Issues

- Profile picture URL not yet uploaded to cloud storage
- Email verification not yet implemented
- Terms & Conditions links need actual URLs

