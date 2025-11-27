# AurumHarmony v1.0 Beta - Quick Start Commands

## 🚀 Start Backend (Flask)

Open PowerShell in the project root and run:

```powershell
cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"
.\.venv\Scripts\Activate.ps1
python .\aurum_harmony\master_codebase\Master_AurumHarmony_261125.py
```

**Or as a single line:**
```powershell
cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"; .\.venv\Scripts\Activate.ps1; python .\aurum_harmony\master_codebase\Master_AurumHarmony_261125.py
```

**What it does:**
- Starts Flask backend on `http://localhost:5000` (main app)
- Starts Admin panel on `http://localhost:5001` (admin API)

**Keep this terminal window open!**

---

## 🎨 Start Frontend (Flutter Web)

Open a **new** PowerShell window and run:

```powershell
cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest\aurum_harmony\frontend\flutter_app"
flutter pub get
flutter run -d chrome
```

**Or if dependencies are already installed:**
```powershell
cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest\aurum_harmony\frontend\flutter_app"; flutter run -d chrome
```

**What it does:**
- Opens Flutter web app in Chrome
- Connects to backend at `http://localhost:5000` and `http://localhost:5001`

---

## 📦 Install/Update Dependencies

### Backend (Python)
```powershell
cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"
.\.venv\Scripts\Activate.ps1
pip install -r .\Other_Files\requirements.txt
```

### Frontend (Flutter)
```powershell
cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest\aurum_harmony\frontend\flutter_app"
flutter pub get
```

---

## 🔧 Build Flutter Web for Cloudflare

```powershell
cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest\aurum_harmony\frontend\flutter_app"
flutter clean
flutter pub get
flutter build web --release
```

Then copy to `docs/`:
```powershell
cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"
if (Test-Path docs) { Remove-Item -Recurse -Force docs }; New-Item -ItemType Directory -Path docs; Copy-Item -Recurse "aurum_harmony\frontend\flutter_app\build\web\*" -Destination "docs\"
```

Commit and push:
```powershell
git add docs
git commit -m "Update Flutter web build"
git push
```

---

## 📍 Project Structure

```
AurumHarmonyTest/
├── aurum_harmony/
│   ├── master_codebase/
│   │   └── Master_AurumHarmony_261125.py  ← Backend entry point
│   └── frontend/
│       └── flutter_app/                    ← Flutter app
├── engines/                                ← Backend engines
├── Other_Files/
│   └── requirements.txt                    ← Python dependencies
└── QUICK_START.md                          ← This file!
```

---

## 🆘 Troubleshooting

**Backend won't start?**
- Check if port 5000 or 5001 is already in use
- Make sure virtual environment is activated (`.venv\Scripts\Activate.ps1`)
- Verify Python dependencies are installed

**Flutter won't run?**
- Run `flutter doctor` to check setup
- Make sure you're in the `flutter_app` directory
- Try `flutter clean` then `flutter pub get`

**Can't connect to backend?**
- Make sure backend is running (check terminal output)
- Verify backend shows "Running on http://0.0.0.0:5000"
- Check browser console for CORS errors

---

**💡 Tip:** Pin this file (`QUICK_START.md`) in your IDE or keep it open in a tab for quick reference!

