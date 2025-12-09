# How to Get HDFC Sky Tokens from Browser

## Step-by-Step Instructions

### Step 1: Log in to HDFC Sky Developer Portal
1. Open your browser
2. Go to: https://developer.hdfcsky.com
3. Log in with your credentials (Client ID/Email/Mobile → OTP → PIN)

### Step 2: Open Developer Tools
**Option A: Using Keyboard Shortcut (Easiest)**
- Press `F12` on your keyboard
- OR press `Ctrl + Shift + I` (Windows/Linux)
- OR press `Cmd + Option + I` (Mac)

**Option B: Using Browser Menu**
- **Chrome/Edge**: Click the three dots (⋮) → More tools → Developer tools
- **Firefox**: Click the hamburger menu (☰) → More tools → Web Developer Tools
- **Safari**: Enable Developer menu first: Preferences → Advanced → Show Develop menu

### Step 3: Navigate to Console Tab
1. In the Developer Tools window that opened, you'll see tabs at the top:
   - Elements / Inspector
   - Console ← **Click this one!**
   - Sources
   - Network
   - etc.

2. Click on the **Console** tab

### Step 4: Run the Command
1. You'll see a prompt at the bottom that looks like: `>`
2. Click in that area (or just start typing)
3. Copy and paste this entire line:
   ```javascript
   Object.keys(localStorage).forEach(k => console.log(k, localStorage.getItem(k)))
   ```
4. Press `Enter`

### Step 5: Copy the Values
1. You'll see output like:
   ```
   accessToken eyJhbGciOiJIUzI1NiJ9.eyJkZXZpY...
   token_id 7249eb031dce4a6bb2237912d6cb3bb5bd8e1c7d613b4507bf043110421e2ef9
   api_key 3347f702031d45539a95e94a0f46d2f2
   clientId S2239332
   ...
   ```

2. Look for these keys:
   - `accessToken` or `access_token` → This is your JWT token
   - `token_id` → This is your token ID
   - `api_key` → This is your API key (optional, you already have this)

3. **Copy the values** (the long strings after the key names)

### Step 6: Alternative Method - Application Tab
If the Console method doesn't work, try this:

1. In Developer Tools, click the **Application** tab (Chrome/Edge) or **Storage** tab (Firefox)
2. In the left sidebar, expand **Local Storage**
3. Click on `https://developer.hdfcsky.com`
4. You'll see a table with keys and values
5. Look for:
   - `accessToken` or `access_token`
   - `token_id`
6. Click on the value to select it, then copy it

### Step 7: Update .env File
1. Open the file: `scripts/brokers/hdfc_token_id_template.txt`
2. Paste the values:
   ```
   API_KEY=your_api_key_here
   TOKEN_ID=your_token_id_here
   ```
3. Save the file
4. Run: `.\scripts\brokers\import_hdfc_token_id.ps1`

## Troubleshooting

**Q: I don't see Developer Tools**
- Make sure you're on the HDFC Sky website (https://developer.hdfcsky.com)
- Try a different browser
- Make sure JavaScript is enabled

**Q: The Console shows an error**
- Make sure you copied the entire command (including the semicolon at the end)
- Try typing it manually instead of pasting

**Q: I don't see `accessToken` or `token_id` in the output**
- Make sure you're logged in to the HDFC Sky developer portal
- Try refreshing the page (F5) and running the command again
- Check the Application/Storage tab instead

**Q: The values look encrypted/encoded**
- That's normal! The `accessToken` is a JWT token (starts with `eyJ...`)
- The `token_id` is a long hexadecimal string
- Just copy them as-is

## Visual Guide

```
┌─────────────────────────────────────────┐
│  Browser Window                         │
│  ┌───────────────────────────────────┐  │
│  │  HDFC Sky Developer Portal        │  │
│  │  (You're logged in here)          │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  Developer Tools (F12)           │  │
│  │  ┌─────┬─────┬─────┬─────┐      │  │
│  │  │Elem │Cons │Netw │App  │      │  │
│  │  │ents │ole ←│ork  │licat│      │  │
│  │  └─────┴─────┴─────┴─────┘      │  │
│  │                                 │  │
│  │  > Object.keys(localStorage)... │  │
│  │  ← Paste command here          │  │
│  │                                 │  │
│  │  Output:                        │  │
│  │  accessToken eyJhbGciOiJIUz... │  │
│  │  token_id 7249eb031dce4a6bb... │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

