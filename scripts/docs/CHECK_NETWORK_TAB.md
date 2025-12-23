# How to Check Network Tab for API Calls

Since there are no navigation options on the HDFC Sky developer portal, let's check what API calls are made when the page loads.

## Steps:

1. **Go to https://developer.hdfcsky.com** (make sure you're logged in)

2. **Open Developer Tools:**
   - Press `F12`
   - OR right-click → "Inspect" or "Inspect Element"

3. **Go to Network Tab:**
   - Click the "Network" tab in Developer Tools
   - Make sure it's recording (red dot should be visible, or click the record button)

4. **Refresh the Page:**
   - Press `F5` or click the refresh button
   - This will capture all network requests made when the page loads

5. **Look for API Calls:**
   - In the Network tab, you'll see a list of requests
   - Look for requests that go to:
     - `developer.hdfcsky.com/oapi/...`
     - `developer.hdfcsky.com/api/...`
   - These are likely the API calls

6. **Click on an API Request:**
   - Click on any request that looks like an API call
   - You'll see details on the right side

7. **Check the "Headers" Tab:**
   - Look at "Request URL" - this is the full endpoint URL
   - Look at "Request Headers" - see what headers are sent
   - Look at "Query String Parameters" - see what parameters are in the URL

8. **Check the "Payload" Tab (if it's a POST request):**
   - See what data is sent in the request body

9. **Share the Information:**
   - Copy the "Request URL" (full URL)
   - Note the "Request Method" (GET/POST/PUT/DELETE)
   - Copy relevant "Request Headers" (especially Authorization if present)
   - If it's a POST, copy the "Payload" data

## What to Look For:

- Requests to `/oapi/v1/...` or `/oapi/v2/...`
- Requests that might be for positions, holdings, orders, or account info
- The authentication pattern used (headers, query params, etc.)

## Example of What You Might See:

```
Request URL: https://developer.hdfcsky.com/oapi/v1/dashboard/apps?token_id=...
Request Method: GET
Request Headers:
  Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
  Content-Type: application/json
Query String Parameters:
  token_id: 59181f88071543af9979a0e353fc0580fd552ffe58494b35a86219d55ca6314f
```

This will help us understand the correct endpoint structure and authentication pattern!

