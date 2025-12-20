# 🚀 AurumHarmony Deployment: Step-by-Step Guide for Beginners

## 📋 **Overview**
This guide will walk you through deploying AurumHarmony to production. We'll upload to GitHub first, then deploy to three platforms. Don't worry - I'll explain every step!

---

## 🎯 **Phase 1: Upload to GitHub (5 minutes)**

### **Step 1.1: Open GitHub in Your Browser**
1. Open your web browser (Chrome, Firefox, Edge, etc.)
2. Go to: https://github.com/imvikverma/ah-v1-beta
3. Log in to GitHub if you're not already logged in

### **Step 1.2: Go to Upload Page**
1. Look for the **"Add file"** button (usually on the right side)
2. Click the small arrow next to "Add file"
3. Click **"Upload files"** from the dropdown menu

### **Step 1.3: Upload the Files**
You'll see a page where you can drag and drop files. Upload these **one by one**:

**File #1: `aurumharmony-minimal-deploy.zip`**
- This is the main deployment package (42KB)
- Find it in your project folder

**File #2: `DEPLOYMENT_GUIDE.md`**
- The deployment instructions
- Find it in your project folder

**File #3: `README.md`**
- Project description
- Find it in your project folder

**File #4: `requirements.txt`**
- Python dependencies
- Find it in your project folder

### **Step 1.4: Commit the Files**
1. Scroll down on the upload page
2. In the **"Commit message"** box, type:
   ```
   AurumHarmony v1.0 Production Release
   ```
3. Make sure **"Commit directly to the main branch"** is selected
4. Click the green **"Commit changes"** button

### **Step 1.5: Verify Upload**
- You should see the files now appear in your GitHub repository
- The repository should show the new files you uploaded

---

## ☁️ **Phase 2: Deploy Admin Panel to Cloudflare (10 minutes)**

### **Step 2.1: Open Cloudflare Dashboard**
1. Open your web browser
2. Go to: https://dash.cloudflare.com
3. Log in to your Cloudflare account

### **Step 2.2: Go to Pages**
1. On the left sidebar, click **"Pages"**
2. Click **"Create a project"**

### **Step 2.3: Connect to GitHub**
1. Select **"Connect to Git"**
2. Choose **GitHub** as the provider
3. Click **"Authorize Cloudflare"** (if asked)
4. Select your repository: **imvikverma/ah-v1-beta**

### **Step 2.4: Configure Build Settings**
1. **Project name**: `aurum-admin-v2`
2. **Production branch**: `main`
3. **Build settings**:
   - **Build command**: Leave empty (just type a space)
   - **Build output directory**: `aurum_harmony/admin_panel/`
   - **Root directory**: `/` (leave as is)

### **Step 2.5: Add Custom Domain (Optional)**
1. In the Pages project settings, go to **"Custom domains"**
2. Click **"Add custom domain"**
3. Enter: `admin-v2.saffronbolt.in`
4. Click **"Add domain"**
5. Follow Cloudflare's DNS instructions to point the domain

### **Step 2.6: Deploy**
1. Click **"Save and Deploy"**
2. Wait for the deployment to complete (usually 2-3 minutes)
3. Your admin panel will be live at: https://aurum-admin-v2.pages.dev

---

## 🔥 **Phase 3: Deploy Flutter App to Firebase (15 minutes)**

### **Step 3.1: Open Firebase Console**
1. Open your web browser
2. Go to: https://console.firebase.google.com
3. Log in with your Google account

### **Step 3.2: Create or Select Project**
1. Click **"Create a project"** (or select existing if you have one)
2. Project name: `aurumharmony`
3. Click **"Continue"** and follow the setup steps

### **Step 3.3: Enable Hosting**
1. In your project dashboard, click **"Hosting"** from the left menu
2. Click **"Get started"**

### **Step 3.4: Install Firebase CLI**
1. Open Command Prompt or PowerShell
2. Run: `npm install -g firebase-tools`
3. Run: `firebase login` (follow the browser login)

### **Step 3.5: Build Flutter Web App**
1. Open Command Prompt or PowerShell
2. Navigate to your project: `cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"`
3. Go to Flutter directory: `cd aurum_harmony\frontend\flutter_app`
4. Build the web app: `flutter build web --release`

### **Step 3.6: Deploy to Firebase**
1. In the Flutter directory, run: `firebase init hosting`
2. Select your Firebase project
3. Choose **"Hosting: Configure files for Firebase Hosting"**
4. Set public directory to: `build/web`
5. Configure as single-page app: **Yes**
6. Overwrite existing files: **No**
7. Then run: `firebase deploy --only hosting`

### **Step 3.7: Add Custom Domain (Optional)**
1. In Firebase console, go to Hosting → Custom domains
2. Click **"Add custom domain"**
3. Enter: `aurumharmony.saffronbolt.in`
4. Follow the DNS setup instructions

### **Step 3.8: Verify Deployment**
- Your app will be live at: https://your-project-id.web.app
- Check that the Flutter app loads correctly

---

## 🖥️ **Phase 4: Deploy Backend to Render.com (10 minutes)**

### **Step 4.1: Open Render Dashboard**
1. Open your web browser
2. Go to: https://dashboard.render.com
3. Log in to your Render account

### **Step 4.2: Create New Web Service**
1. Click **"New +"** button
2. Select **"Web Service"**

### **Step 4.3: Connect to GitHub**
1. Choose **"Connect GitHub"**
2. Authorize Render to access your GitHub
3. Select repository: **imvikverma/ah-v1-beta**
4. Click **"Connect"**

### **Step 4.4: Configure Service**
1. **Service Name**: `aurum-api`
2. **Environment**: `Python`
3. **Region**: Choose closest to your users (e.g., Singapore for India)
4. **Branch**: `main`
5. **Build Command**: `pip install -r requirements.txt`
6. **Start Command**: `python aurum_harmony/master_codebase/Master_AurumHarmony_261125.py`

### **Step 4.5: Add Environment Variables**
Click **"Add Environment Variable"** and add:
```
FLASK_ENV=production
SECRET_KEY=your_secure_random_key_here
HDFC_SKY_API_KEY=your_api_key
HDFC_SKY_API_SECRET=your_api_secret
KOTAK_NEO_API_KEY=your_api_key
KOTAK_NEO_API_SECRET=your_api_secret
```

### **Step 4.6: Deploy**
1. Click **"Create Web Service"**
2. Wait for deployment (usually 5-10 minutes)
3. Your API will be live at the URL shown in Render dashboard

### **Step 4.7: Add Custom Domain (Optional)**
1. In service settings, go to **"Custom Domains"**
2. Click **"Add Custom Domain"**
3. Enter: `api.saffronbolt.in`
4. Follow DNS setup instructions

---

## ✅ **Phase 5: Final Testing (5 minutes)**

### **Step 5.1: Test Admin Panel**
1. Go to: https://aurum-admin-v2.pages.dev (or your custom domain)
2. Try logging in with admin credentials
3. Check if user management works

### **Step 5.2: Test Flutter App**
1. Go to: https://your-project-id.web.app (or your custom domain)
2. Try registering a new user
3. Test the dashboard and basic features

### **Step 5.3: Test API**
1. Go to your Render API URL
2. Add `/api/health` to test: `https://your-api-url.onrender.com/api/health`
3. Should return JSON with status "healthy"

---

## 🌐 **Phase 6: Domain Setup (Optional - 30 minutes)**

### **Step 6.1: Buy Domains (if needed)**
- Go to GoDaddy, Namecheap, or Google Domains
- Buy: `saffronbolt.in` (if not already owned)
- The subdomains will work automatically

### **Step 6.2: DNS Configuration**
For each domain, add these DNS records:

**admin-v2.saffronbolt.in:**
- Type: CNAME
- Name: admin-v2
- Value: aurum-admin-v2.pages.dev

**aurumharmony.saffronbolt.in:**
- Type: CNAME
- Name: aurumharmony
- Value: your-firebase-project.web.app

**api.saffronbolt.in:**
- Type: CNAME
- Name: api
- Value: your-render-service.onrender.com

---

## 🎉 **Success! AurumHarmony is Live**

### **Your Live URLs:**
- **Admin Panel**: https://admin-v2.saffronbolt.in
- **Trading App**: https://aurumharmony.saffronbolt.in
- **API Backend**: https://your-api.onrender.com

### **Next Steps:**
1. **Test thoroughly** with real users
2. **Monitor performance** in each platform's dashboard
3. **Set up monitoring** for errors and usage
4. **Plan updates** for new features

---

## 🆘 **If Something Goes Wrong**

### **GitHub Issues:**
- Make sure you're logged in
- Check file sizes (must be <25MB for upload)
- Try uploading files one at a time

### **Cloudflare Issues:**
- Check that the build output directory is correct: `aurum_harmony/admin_panel/`
- Verify the files exist in your GitHub repo

### **Firebase Issues:**
- Make sure Firebase CLI is installed: `firebase --version`
- Check that Flutter build succeeded: look for `build/web/` folder

### **Render Issues:**
- Check environment variables are set correctly
- Verify the start command path is correct
- Check Render logs for error messages

### **Need Help?**
- Check the `DEPLOYMENT_GUIDE.md` file for detailed troubleshooting
- Each platform has extensive documentation
- Take it one step at a time!

---

**Remember: Take breaks between steps. Deployment can take time, but you'll have AurumHarmony live soon! 🚀**

*This guide is designed for beginners - follow each step carefully!* 📚✨
