# Ngrok Setup & API Configuration - Tomorrow's Tasks

## 🎯 Goals
1. Set up ngrok with static domain
2. Configure static endpoints for backend APIs
3. Update Flutter app to use ngrok URLs instead of localhost
4. Test end-to-end connectivity

---

## 📋 Prerequisites

### 1. Ngrok Account Setup
- [ ] Sign up for ngrok account: https://dashboard.ngrok.com/signup
- [ ] Get your authtoken from: https://dashboard.ngrok.com/get-started/your-authtoken
- [ ] Install ngrok (if not already):
  ```powershell
  # Download from https://ngrok.com/download
  # Or via Chocolatey: choco install ngrok
  ```

### 2. Static Domain (Ngrok Pro/Paid)
- [ ] Upgrade to ngrok plan that supports static domains (if needed)
- [ ] Reserve a static domain in ngrok dashboard
- [ ] Note down your static domain (e.g., `aurumharmony-backend.ngrok-free.app`)

---

## 🔧 Setup Steps

### Step 1: Configure Ngrok Authtoken
```powershell
ngrok config add-authtoken YOUR_AUTHTOKEN_HERE
```

### Step 2: Create Ngrok Configuration File
Create `ngrok.yml` in project root:
```yaml
version: "2"
authtoken: YOUR_AUTHTOKEN_HERE
tunnels:
  backend:
    addr: 5000
    proto: http
    domain: YOUR_STATIC_DOMAIN.ngrok-free.app
    inspect: false
  admin:
    addr: 5001
    proto: http
    domain: YOUR_STATIC_DOMAIN_ADMIN.ngrok-free.app
    inspect: false
```

### Step 3: Start Ngrok Tunnels
```powershell
# Start both tunnels
ngrok start --all

# Or start individually:
ngrok start backend
ngrok start admin
```

### Step 4: Get Static URLs
- Main backend: `https://YOUR_STATIC_DOMAIN.ngrok-free.app`
- Admin panel: `https://YOUR_STATIC_DOMAIN_ADMIN.ngrok-free.app`

---

## 🔄 Update Flutter App

### Update `lib/constants.dart`:
```dart
/// Backend API base URLs
const String kBackendBaseUrl = 'https://YOUR_STATIC_DOMAIN.ngrok-free.app';
const String kAdminBaseUrl = 'https://YOUR_STATIC_DOMAIN_ADMIN.ngrok-free.app';
```

### Rebuild Flutter Web:
```powershell
cd "aurum_harmony\frontend\flutter_app"
flutter build web --release
```

### Update Cloudflare:
- Copy new build to `docs/`
- Commit and push
- Cloudflare will auto-deploy

---

## 🧪 Testing Checklist

- [ ] Ngrok tunnels are running
- [ ] Backend accessible via ngrok URL: `https://YOUR_DOMAIN/health`
- [ ] Admin panel accessible: `https://YOUR_DOMAIN/admin/users`
- [ ] Flutter app connects to ngrok URLs (not localhost)
- [ ] Cloudflare-hosted app can reach backend via ngrok
- [ ] CORS is working (check browser console)
- [ ] All API endpoints respond correctly

---

## 🔐 Security Notes

- **Ngrok Free**: URLs change on restart (unless using static domain)
- **Ngrok Pro**: Static domains, custom domains, reserved IPs
- **Authentication**: Consider adding basic auth or API keys for production
- **HTTPS**: Ngrok provides HTTPS automatically

---

## 📝 Current Backend Endpoints to Test

### Main App (Port 5000)
- `GET /health` - Health check
- `POST /predict` - AI prediction
- `POST /settle` - Settlement
- `GET /report/user/<user_id>` - User report
- `GET /backtest/realistic` - Realistic backtest
- `GET /backtest/edge` - Edge case backtest

### Admin Panel (Port 5001)
- `GET /admin` - Admin dashboard (HTML)
- `GET /admin/users` - User list (JSON)
- `POST /admin/update` - Update user

---

## 🚀 Quick Start Script (After Setup)

Create `start_ngrok.ps1`:
```powershell
# Start backend first
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest'; .\.venv\Scripts\Activate.ps1; python .\aurum_harmony\master_codebase\Master_AurumHarmony_261125.py"

# Wait a moment for backend to start
Start-Sleep -Seconds 3

# Start ngrok
Write-Host "Starting ngrok tunnels..." -ForegroundColor Green
ngrok start --all
```

---

## 💡 Tips

1. **Keep ngrok running**: Don't close the ngrok terminal while using the app
2. **Check ngrok dashboard**: https://dashboard.ngrok.com/status/tunnels
3. **Monitor requests**: Use ngrok web interface to see incoming requests
4. **Free tier limits**: Be aware of connection limits on free tier
5. **Static domains**: Worth upgrading if you need consistent URLs

---

## 🐛 Troubleshooting

**Ngrok won't start?**
- Check authtoken is correct
- Verify ports 5000/5001 aren't in use
- Check firewall isn't blocking ngrok

**CORS errors?**
- Verify CORS is enabled in backend (already done)
- Check ngrok URL is correct in Flutter app
- Clear browser cache

**Connection refused?**
- Make sure backend is running before starting ngrok
- Verify ngrok is pointing to correct ports
- Check ngrok dashboard for tunnel status

---

**Ready for tomorrow!** 🚀

