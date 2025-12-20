# Session Expired After Login - Investigation

**Date:** December 13, 2025  
**Issue:** "Session expired" snackbar appears immediately after successful login

---

## Symptoms

- ✅ Login succeeds (token received)
- ✅ Frontend loads
- ✅ Localhost works
- ✅ Git/Cloudflare Quick deploys work
- ❌ "Session expired" snackbar appears after login

---

## Root Cause Analysis

### Possible Causes:

1. **Race Condition:**
   - Token validation (`getValidToken()`) called immediately after login
   - Session not fully committed to database yet
   - Token validation fails before session is ready

2. **JWT Secret Mismatch:**
   - Login uses one JWT secret
   - Token validation uses different secret
   - Token appears invalid even though it's valid

3. **Session Database Issue:**
   - Session record not created properly
   - `Session.is_expired()` returns True immediately
   - Database transaction not committed

4. **Time Sync Issue:**
   - System time incorrect
   - Token expiration calculated incorrectly
   - Token appears expired immediately

5. **Token Validation Too Aggressive:**
   - `getValidToken()` called on every screen load
   - Network timeout during validation
   - Returns 401 even though token is valid

---

## Code Flow Analysis

### Login Flow:
1. User submits login form
2. `AuthService.login()` called
3. Token received and stored in SharedPreferences
4. `onLoginSuccess()` callback triggers
5. `_isLoggedIn = true` set
6. DashboardScreen loads

### Token Validation Flow:
1. Screen loads (DashboardScreen, AdminScreen, etc.)
2. Calls `AuthService.getValidToken()`
3. `getValidToken()` calls `/api/auth/me` to validate
4. If 401 returned → token cleared → "Session expired" shown

### The Problem:
- Token validation happens **immediately** after login
- If `/api/auth/me` fails (network, timing, etc.), token is cleared
- User sees "session expired" even though they just logged in

---

## Current Token Validation Logic

From `auth_service.dart`:
```dart
static Future<String?> getValidToken() async {
  final token = await getToken();
  if (token == null) return null;
  
  // Try to validate token by calling /api/auth/me
  try {
    final response = await http.get(
      Uri.parse('$kBackendBaseUrl/api/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 5));
    
    if (response.statusCode == 200) {
      return token; // Token is valid
    } else if (response.statusCode == 401) {
      // Token expired, clear it
      await logout();
      return null;
    }
  } catch (e) {
    // Network error, return token anyway (might work)
    return token;
  }
  
  return token;
}
```

**Issue:** If `/api/auth/me` returns 401, token is immediately cleared, even if it's a false positive.

---

## Backend Session Creation

From `auth_service.py`:
```python
# Generate session token
token = generate_session_token(user.id)

# Create session record
expires_at = datetime.utcnow() + timedelta(hours=24)
session = Session(
    user_id=user.id,
    session_token=token,
    expires_at=expires_at
)
db.session.add(session)
db.session.commit()
```

**Potential Issue:** If database commit fails or is delayed, session might not exist when validation happens.

---

## Solutions

### Solution 1: Add Grace Period After Login (Recommended)

Don't validate token immediately after login. Add a grace period:

```dart
// In auth_service.dart
static DateTime? _lastLoginTime;
static const _validationGracePeriod = Duration(seconds: 10);

static Future<String?> getValidToken() async {
  final token = await getToken();
  if (token == null) return null;
  
  // Skip validation if we just logged in (grace period)
  if (_lastLoginTime != null) {
    final timeSinceLogin = DateTime.now().difference(_lastLoginTime!);
    if (timeSinceLogin < _validationGracePeriod) {
      return token; // Trust the token, skip validation
    }
  }
  
  // ... rest of validation logic
}

static Future<void> login(...) async {
  // ... existing login code ...
  
  // Store login time
  _lastLoginTime = DateTime.now();
}
```

### Solution 2: Make Token Validation Less Aggressive

Only validate token if it's been a while since last validation:

```dart
static DateTime? _lastValidationTime;
static const _validationInterval = Duration(minutes: 5);

static Future<String?> getValidToken() async {
  final token = await getToken();
  if (token == null) return null;
  
  // Only validate every 5 minutes
  if (_lastValidationTime != null) {
    final timeSinceValidation = DateTime.now().difference(_lastValidationTime!);
    if (timeSinceValidation < _validationInterval) {
      return token; // Skip validation, use cached result
    }
  }
  
  // ... validation logic ...
  _lastValidationTime = DateTime.now();
}
```

### Solution 3: Don't Clear Token on First 401

Give token a second chance before clearing:

```dart
static int _validationFailureCount = 0;

static Future<String?> getValidToken() async {
  final token = await getToken();
  if (token == null) return null;
  
  try {
    final response = await http.get(...);
    
    if (response.statusCode == 200) {
      _validationFailureCount = 0; // Reset on success
      return token;
    } else if (response.statusCode == 401) {
      _validationFailureCount++;
      
      // Only clear token after multiple failures
      if (_validationFailureCount >= 2) {
        await logout();
        return null;
      }
      
      // Return token anyway on first failure (might be temporary)
      return token;
    }
  } catch (e) {
    // Network error, return token anyway
    return token;
  }
}
```

### Solution 4: Fix Backend Session Creation

Ensure session is committed before returning token:

```python
# In auth_service.py login_user()
session = Session(...)
db.session.add(session)
db.session.flush()  # Ensure session ID is generated
db.session.commit()  # Commit immediately

# Verify session was created
if not Session.query.filter_by(session_token=token).first():
    # Retry or raise error
    pass
```

---

## Recommended Fix

**Combine Solutions 1 and 3:**
1. Add grace period after login (10 seconds)
2. Don't clear token on first 401 (allow retry)
3. Only clear token after multiple validation failures

This provides:
- ✅ No false positives immediately after login
- ✅ Still validates token for security
- ✅ Handles temporary network issues gracefully

---

## Testing

After implementing fix:

1. **Test Login:**
   - Login successfully
   - Should NOT see "session expired" immediately
   - Should be able to use app normally

2. **Test Token Expiration:**
   - Wait 24+ hours (or manually expire token)
   - Should see "session expired" when token actually expires

3. **Test Network Issues:**
   - Disconnect network temporarily
   - Should NOT clear token on temporary network error
   - Should retry when network returns

---

## Status

**Priority:** Medium (annoying but doesn't break functionality)  
**Impact:** User experience (confusing error message)  
**Fix Complexity:** Low (simple code changes)

---

## Next Steps

1. Implement Solution 1 (grace period) + Solution 3 (retry logic)
2. Test login flow
3. Monitor for false positive "session expired" messages
4. Adjust grace period/retry count if needed

