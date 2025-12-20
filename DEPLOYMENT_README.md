# 🚀 AurumHarmony Deployment Guide

Complete deployment setup for GitHub, Cloudflare Pages, Firebase Hosting, and Render.com.

## 📋 Deployment Overview

AurumHarmony consists of four main components that need to be deployed:

1. **GitHub Repository** - Source code hosting and CI/CD
2. **Admin Panel** - Cloudflare Pages (admin-v2.saffronbolt.in)
3. **Flutter App** - Firebase Hosting (aurumharmony.com)
4. **Backend API** - Render.com (aurumharmony-backend.onrender.com)

## 🛠️ Quick Deployment Setup

### Automated Setup
```bash
# Run the deployment setup script
python deploy.py
```

This will:
- ✅ Run pre-deployment checks
- ✅ Configure all deployment platforms
- ✅ Create necessary configuration files
- ✅ Provide step-by-step deployment instructions

### Manual Setup

#### 1. GitHub Repository
```bash
# Initialize git and create repository
git init
git add .
git commit -m "Initial commit - AurumHarmony v1.0"

# Create repository on GitHub, then:
git remote add origin https://github.com/yourusername/aurumharmony.git
git push -u origin main
```

#### 2. Admin Panel → Cloudflare Pages
```bash
# Install Wrangler CLI
npm install -g wrangler

# Login to Cloudflare
wrangler auth login

# Deploy admin panel
wrangler pages deploy aurum_harmony/admin_panel --project-name aurumharmony-admin
```

#### 3. Flutter App → Firebase Hosting
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in Flutter directory
cd aurum_harmony/frontend/flutter_app
firebase init hosting

# Build and deploy
flutter build web --release
firebase deploy --only hosting
```

#### 4. Backend → Render.com
```bash
# Create new Web Service on Render.com
# Connect GitHub repository
# Set build command: pip install -r requirements.txt
# Set start command: python aurum_harmony/master_codebase/Master_AurumHarmony_261125.py
```

## 🔧 Environment Configuration

### Backend Environment Variables (Render.com)
```bash
# Database
DATABASE_URL=postgresql://...

# Authentication
JWT_SECRET_KEY=your-secret-key-here
FLASK_ENV=production

# Broker APIs
HDFC_SKY_API_KEY=your-hdfc-key
HDFC_SKY_API_SECRET=your-hdfc-secret
KOTAK_NEO_ACCESS_TOKEN=your-kotak-token
KOTAK_NEO_CLIENT_CODE=your-client-code

# Email (for notifications)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

### Admin Panel Environment
Update `aurum_harmony/admin_panel/script.js`:
```javascript
const API_BASE_URL = 'https://aurumharmony-backend.onrender.com';
```

### Flutter App Environment
Update `aurum_harmony/frontend/flutter_app/lib/services/api_service.dart`:
```dart
const String apiBaseUrl = 'https://aurumharmony-backend.onrender.com';
```

## 🚀 GitHub Actions CI/CD

### Automated Deployments

The repository includes GitHub Actions workflows for automatic deployments:

- **Admin Panel**: Deploys on changes to `aurum_harmony/admin_panel/`
- **Flutter App**: Deploys on changes to `aurum_harmony/frontend/flutter_app/`

### Required Secrets

Add these to your GitHub repository secrets:

```bash
# Cloudflare
CLOUDFLARE_API_TOKEN=your-cloudflare-token
CLOUDFLARE_ACCOUNT_ID=your-account-id

# Firebase
FIREBASE_SERVICE_ACCOUNT=key.json-content
```

## 📊 Domain Configuration

### Custom Domains
1. **Main App**: aurumharmony.com → Firebase Hosting
2. **Admin Panel**: admin-v2.saffronbolt.in → Cloudflare Pages
3. **Backend API**: aurumharmony-backend.onrender.com → Render.com

### DNS Setup
```
aurumharmony.com     → Firebase Hosting
admin.saffronbolt.in → Cloudflare Pages
api.aurumharmony.com → Render.com (CNAME)
```

## 🧪 Testing Deployments

### Health Checks
```bash
# Backend health
curl https://aurumharmony-backend.onrender.com/health

# Admin panel
curl https://admin-v2.saffronbolt.in

# Flutter app
curl https://aurumharmony.com
```

### API Testing
```bash
# Test trading calendar
curl "https://aurumharmony-backend.onrender.com/api/calendar/status"

# Test user registration
curl -X POST https://aurumharmony-backend.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

## 🔍 Troubleshooting

### Common Issues

#### Backend Deployment
**Issue**: `ModuleNotFoundError`
**Solution**: Ensure all dependencies are in `requirements.txt`

**Issue**: Database connection failed
**Solution**: Check `DATABASE_URL` environment variable

#### Flutter Deployment
**Issue**: Build fails
**Solution**: Run `flutter clean` and ensure correct Flutter version

**Issue**: White screen after deployment
**Solution**: Check Firebase hosting configuration and base href

#### Admin Panel Deployment
**Issue**: 404 errors
**Solution**: Ensure `index.html` is in root directory

**Issue**: API calls blocked
**Solution**: Check CORS configuration in backend

### Debug Commands
```bash
# Check backend logs (Render.com)
# Go to Render dashboard → Service → Logs tab

# Check Firebase deployment
firebase hosting:channel:list

# Check Cloudflare deployment
wrangler tail
```

## 📈 Performance Optimization

### Backend (Render.com)
- **Instance Type**: Starter (512MB RAM) → upgrade as needed
- **Auto-scaling**: Enable for high traffic
- **Database**: Use PostgreSQL for production

### Frontend (Firebase)
- **Caching**: Configure appropriate cache headers
- **CDN**: Firebase automatically provides CDN
- **Compression**: Enable gzip compression

### Admin Panel (Cloudflare)
- **Edge Computing**: Utilize Cloudflare Workers if needed
- **Caching**: Configure page rules for static assets
- **Security**: Enable Cloudflare security features

## 🔒 Security Checklist

- [ ] HTTPS enabled on all domains
- [ ] API keys stored as environment variables
- [ ] Database credentials secured
- [ ] CORS properly configured
- [ ] Input validation enabled
- [ ] Rate limiting implemented
- [ ] Admin panel access restricted

## 📱 Mobile App Deployment

### Android (Google Play)
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Upload to Google Play Console
```

### iOS (App Store)
```bash
# Build for iOS
flutter build ios --release

# Open in Xcode and archive
# Upload to App Store Connect
```

## 🔄 Updates and Maintenance

### Rolling Updates
1. **Test locally** with new changes
2. **Deploy to staging** environment first
3. **Run automated tests** on staging
4. **Deploy to production** if tests pass

### Backup Strategy
- **Database**: Automated daily backups on Render.com
- **Code**: Version control with GitHub
- **Assets**: Firebase storage for user uploads

## 📞 Support and Monitoring

### Monitoring Tools
- **Render.com**: Built-in monitoring and alerts
- **Firebase**: Performance monitoring and crash reports
- **Cloudflare**: Analytics and security monitoring
- **GitHub**: Actions logs and deployment status

### Alert Configuration
- Backend errors → Email alerts
- Deployment failures → GitHub notifications
- Performance issues → Monitoring dashboards

## 🎯 Success Metrics

### Deployment KPIs
- **Uptime**: >99.5% across all services
- **Response Time**: <500ms for API calls
- **Error Rate**: <1% for critical operations
- **Deployment Success**: 100% automated deployments

### User Experience
- **App Load Time**: <3 seconds
- **API Response**: <200ms average
- **Offline Capability**: Graceful degradation

## 📝 Deployment Checklist

### Pre-Deployment
- [ ] Run `python deploy.py` setup script
- [ ] Configure all environment variables
- [ ] Test all components locally
- [ ] Create GitHub repository

### Deployment Steps
- [ ] Deploy backend to Render.com
- [ ] Deploy admin panel to Cloudflare Pages
- [ ] Deploy Flutter app to Firebase Hosting
- [ ] Update DNS records
- [ ] Test all endpoints and functionality

### Post-Deployment
- [ ] Run end-to-end tests on production
- [ ] Monitor performance and errors
- [ ] Set up monitoring alerts
- [ ] Document any issues and resolutions

## 🎉 Launch Ready!

Once all components are deployed and tested, AurumHarmony will be live and ready for users!

**Next Steps:**
1. Run `python deploy.py` to configure everything
2. Follow the deployment instructions for each platform
3. Test thoroughly in production environment
4. Monitor and optimize performance
5. Scale as user base grows

🚀 **Let's get AurumHarmony live!**
