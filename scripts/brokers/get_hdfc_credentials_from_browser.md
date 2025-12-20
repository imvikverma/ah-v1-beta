# How to Get HDFC Sky api_key and token_id from Browser

Based on the HDFC Sky React code, credentials are stored in `localStorage`. Here's how to extract them:

## Method 1: Browser Console (Easiest & Recommended)

1. **Open Developer Tools** (Press `F12` or Right-click → Inspect)
2. Go to **Console** tab
3. Run these commands:

```javascript
// Get the exact keys HDFC Sky uses (from React code)
console.log('accessToken:', localStorage.getItem('accessToken'));
console.log('token_id:', localStorage.getItem('token_id'));
console.log('api_key:', localStorage.getItem('api_key'));
console.log('imIsLoggedIn:', localStorage.getItem('imIsLoggedIn'));

// Or list all localStorage keys to see what's available
Object.keys(localStorage).forEach(key => {
    console.log(key, ':', localStorage.getItem(key));
});
```

**Copy the values for:**
- `accessToken` - This is the JWT token (for Authorization header)
- `token_id` - Token ID (for API calls)
- `api_key` - API Key (for API calls)

## Method 2: Application Tab (Visual Method)

1. Open Developer Tools (F12)
2. Go to **Application** tab (or **Storage** in Firefox)
3. Expand:
   - **Local Storage** → `https://developer.hdfcsky.com`
4. Look for these **exact keys** (from React code):
   - `accessToken` - JWT token
   - `token_id` - Token ID
   - `api_key` - API Key
   - `imIsLoggedIn` - Login flag (not needed, just for reference)
5. Double-click each value to copy it

## Method 3: Network Tab (Check API Calls)

1. Open Developer Tools (F12)
2. Go to **Network** tab
3. Refresh the page (F5)
4. Look for any API calls (filter by "XHR" or "Fetch")
5. Click on a request → **Headers** tab
6. Check:
   - **Request URL** - might have `?api_key=...&token_id=...`
   - **Query String Parameters** section
   - **Request Payload** (if POST request)

## Method 4: Check Page Source / JavaScript

1. Open Developer Tools (F12)
2. Go to **Sources** tab (or **Debugger** in Firefox)
3. Look for JavaScript files that might contain these values
4. Or check **Console** for any global variables:
   ```javascript
   // Try these
   window.api_key
   window.token_id
   window.API_KEY
   window.TOKEN_ID
   ```

## What to Look For (Exact Keys from React Code)

Based on the HDFC Sky React component (`IndividualLogin.js`), these are the **exact localStorage keys**:

- ✅ `accessToken` - JWT token (used in Authorization header)
- ✅ `token_id` - Token ID (used in API calls)
- ✅ `api_key` - API Key (used in API calls)
- ℹ️ `imIsLoggedIn` - Login flag (not needed for API)

## Once You Find Them

1. Copy the `api_key` value
2. Copy the `token_id` value
3. (Optional) Copy the `accessToken` value (JWT token for Authorization header)
4. Use the template file method:
   - Run: `.\scripts\brokers\import_hdfc_token_id.ps1`
   - Paste the values directly in the template file:
     ```
     API_KEY=paste_api_key_here
     TOKEN_ID=paste_token_id_here
     ```
   - Save and run the script again

