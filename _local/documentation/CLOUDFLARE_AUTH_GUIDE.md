# Cloudflare Authentication Guide for D1 Migration

## Option 1: Interactive Login (Recommended - Easiest)

**Use this if you want the simplest setup:**

```powershell
cd worker
npx wrangler login
cd ..
.\scripts\migrate_d1_schema.ps1
```

This opens your browser and uses OAuth. No API keys needed!

---

## Option 2: API Token (For Automation/Scripts)

**Use this if you need non-interactive authentication:**

### Step 1: Create API Token

1. Go to: https://dash.cloudflare.com/profile/api-tokens
2. Click: **"Create Token"**
3. Click: **"Create Custom Token"**
4. Configure:
   - **Token name**: `AurumHarmony-D1-Migration` (or any name)
   - **Permissions**:
     - **Account** → **D1** → **Edit**
     - **Account** → **Workers Scripts** → **Edit** (if deploying workers)
   - **Account Resources**: Select your account
5. Click: **"Continue to summary"** → **"Create Token"**
6. **Copy the token immediately** (you won't see it again!)

### Step 2: Set Environment Variable

**PowerShell (Current Session):**
```powershell
$env:CLOUDFLARE_API_TOKEN = "your-token-here"
```

**PowerShell (Permanent - User Level):**
```powershell
[System.Environment]::SetEnvironmentVariable("CLOUDFLARE_API_TOKEN", "your-token-here", "User")
```

**PowerShell (Permanent - System Level - Requires Admin):**
```powershell
[System.Environment]::SetEnvironmentVariable("CLOUDFLARE_API_TOKEN", "your-token-here", "Machine")
```

### Step 3: Verify
```powershell
cd worker
npx wrangler whoami
```

Should show your account email.

---

## ❌ What NOT to Use

### Global API Key
- **Not recommended** for scripts/automation
- Less secure (full account access)
- Can be used, but API tokens are better

### Origin CA Key
- **Not relevant** for D1/Workers
- Only for certificate management
- Won't work for wrangler

---

## Recommendation

**For one-time migration:** Use `wrangler login` (Option 1) - it's the easiest!

**For automation/CI/CD:** Use API Token (Option 2) with proper permissions.

---

## Troubleshooting

**"Not authenticated" error:**
- Make sure you ran `wrangler login` OR set `CLOUDFLARE_API_TOKEN`
- Check token has D1 permissions
- Verify token hasn't expired

**"Permission denied" error:**
- Token needs **D1 → Edit** permission
- Check account resources are set correctly

