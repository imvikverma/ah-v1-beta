# How to Get HDFC Sky JWT Token from Browser

Since HDFC Sky authentication might be web-only, you can extract the JWT token from your browser session.

## Method 1: Browser Console

1. Open Developer Tools (F12)
2. Go to **Console** tab
3. Try these commands:

```javascript
// Check localStorage
localStorage.getItem('token')
localStorage.getItem('auth_token')
localStorage.getItem('jwt')
localStorage.getItem('authorization')

// Check sessionStorage
sessionStorage.getItem('token')
sessionStorage.getItem('auth_token')
sessionStorage.getItem('jwt')
sessionStorage.getItem('authorization')

// List all keys
Object.keys(localStorage)
Object.keys(sessionStorage)
```

## Method 2: Application Tab

1. Open Developer Tools (F12)
2. Go to **Application** tab
3. Check:
   - **Local Storage** → `https://developer.hdfcsky.com`
   - **Session Storage** → `https://developer.hdfcsky.com`
   - **Cookies** → `https://developer.hdfcsky.com`
4. Look for keys containing: `token`, `auth`, `jwt`, `authorization`

## Method 3: Network Tab

1. Open Developer Tools (F12)
2. Go to **Network** tab
3. Filter by "XHR" or "Fetch"
4. Look for API calls after login
5. Check the **Response** tab of those calls
6. Look for `token`, `access_token`, `jwt` in the response

## Method 4: Check Authorization Header

1. Open Developer Tools (F12)
2. Go to **Network** tab
3. Find any API call (like the `/update-im-app-details` one you saw)
4. Click on it → **Headers** tab
5. Look for **Authorization** header
6. Copy the JWT token value (the long string after "Bearer " or just the token)

## Once You Have the Token

Add it to your `.env` file:
```
HDFC_SKY_ACCESS_TOKEN=your_jwt_token_here
```

Then we can update the code to use this token for API calls instead of trying to authenticate via API.

