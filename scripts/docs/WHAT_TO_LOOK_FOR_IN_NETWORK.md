# What to Look For in Network Tab

## Quick Search Terms:

In the Network tab filter box, try searching for:

1. **`oapi`** - Shows all HDFC Sky API calls
2. **`position`** - Positions-related endpoints
3. **`holding`** - Holdings/portfolio endpoints
4. **`order`** - Order-related endpoints
5. **`trade`** - Trade book endpoints
6. **`quote`** - Market quotes endpoints
7. **`dashboard`** - Dashboard API calls
8. **`im/`** - Internal management endpoints (like `/im/positions`)

## What a Good API Call Looks Like:

✅ **Good (API call):**
- URL: `https://developer.hdfcsky.com/oapi/v1/positions?token_id=...`
- Method: GET or POST
- Type: `fetch` or `xhr` (not `document`, `stylesheet`, `image`, etc.)
- Status: 200 (success) or 401/404 (but still shows the endpoint)

❌ **Skip (not API calls):**
- `main.c8eb70da.js` (JavaScript files)
- `.css` files (stylesheets)
- `.png`, `.jpg` (images)
- `favicon.ico` (icon)
- `index.html` (HTML pages)

## When You Find an API Call:

1. **Click on it** to see details
2. **Check "Headers" tab:**
   - Look at "Request URL" (the full endpoint)
   - Look at "Request Headers" (especially `Authorization` if present)
   - Look at "Query String Parameters" (like `token_id`, `api_key`)
3. **Check "Payload" tab** (if it's a POST request):
   - See what data is sent in the body
4. **Check "Response" tab:**
   - See what the API returns (JSON data)

## Example Endpoints to Look For:

- `/oapi/v1/positions` or `/oapi/v2/positions`
- `/oapi/v1/holdings` or `/oapi/v2/holdings`
- `/oapi/v1/orders` or `/oapi/v2/orders`
- `/oapi/v1/dashboard/apps`
- `/oapi/v1/im/positions` or `/oapi/v2/im/positions`
- `/oapi/v1/im/login` or `/oapi/v2/im/login`

## What to Share:

When you find an API call, share:
1. **Request URL** (the full URL with query parameters)
2. **Request Method** (GET/POST/PUT/DELETE)
3. **Request Headers** (especially `Authorization` header if present)
4. **Query Parameters** (if any in the URL)
5. **Request Payload** (if it's a POST request)

This will help us understand the correct endpoint structure and authentication pattern!

