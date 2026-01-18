# Flutter Frontend Docker Setup

This directory contains Docker configurations for building and deploying the AurumHarmony Flutter frontend across multiple platforms.

## Services

### 1. Flutter Web (`flutter-web`)
**Purpose**: Serves the Flutter web application using nginx

**Build**: 
```bash
docker-compose up -d flutter-web
```

**Access**: http://localhost:8080

**Features**:
- Production-optimized Flutter web build
- Nginx with gzip compression
- API proxying to backend services
- Proper caching headers
- Security headers

### 2. Flutter Android (`flutter-android`)
**Purpose**: Builds Android APK files

**Build**:
```bash
docker-compose --profile build up flutter-android
```

**Output**: APK will be generated at:
```
aurum_harmony/frontend/flutter_app/build/app/outputs/flutter-apk/app-release.apk
```

**Note**: Uses Docker profiles to avoid running by default. Only builds when explicitly requested.

### 3. Flutter iOS (`flutter-ios`)
**Purpose**: Prepares iOS builds (requires macOS for actual compilation)

**Build**:
```bash
docker-compose --profile build up flutter-ios
```

**Note**: 
- iOS builds require macOS and Xcode
- This container is primarily for CI/CD pipelines with macOS runners
- For local iOS development, use `flutter build ios` directly on a Mac

## Quick Start

### Run the Web Frontend
```bash
# Start backend services first
docker-compose up -d postgres redis backend

# Start the Flutter web frontend
docker-compose up -d flutter-web

# Access at http://localhost:8080
```

### Build Android APK
```bash
# Build the Android APK
docker-compose --profile build up flutter-android

# Find the APK at:
# ./aurum_harmony/frontend/flutter_app/build/app/outputs/flutter-apk/app-release.apk
```

### Full Stack (Backend + Frontend)
```bash
# Start everything except build services
docker-compose up -d

# This will start:
# - PostgreSQL
# - Redis
# - Backend API
# - Flutter Web Frontend
```

## Configuration

### Backend URLs
The Flutter web app is configured to proxy API requests to the backend:
- `/api/*` → `http://backend:5000/`
- `/admin/*` → `http://backend:5001/admin/`

### Environment Variables
You can customize the backend URLs by modifying the `docker-compose.yml`:
```yaml
flutter-web:
  environment:
    - BACKEND_URL=http://backend:5000
    - ADMIN_URL=http://backend:5001
```

## Development

### Local Development (without Docker)
For faster development, run Flutter directly:
```bash
cd aurum_harmony/frontend/flutter_app
flutter pub get
flutter run -d chrome  # For web
flutter run -d android # For Android (requires emulator)
flutter run -d ios     # For iOS (requires macOS)
```

### Hot Reload
For hot reload during development, mount the source code:
```yaml
flutter-web:
  volumes:
    - ./aurum_harmony/frontend/flutter_app:/app
```
Then use `flutter run -d web-server --web-port 8080` inside the container.

## Dockerfiles

- **Dockerfile.web**: Multi-stage build (Flutter build + nginx serve)
- **Dockerfile.android**: Android SDK + Flutter for APK generation
- **Dockerfile.ios**: iOS preparation (requires macOS for actual build)
- **nginx.conf**: nginx configuration for Flutter web app

## Troubleshooting

### Port Already in Use
If port 8080 is already in use, change it in `docker-compose.yml`:
```yaml
flutter-web:
  ports:
    - "8081:80"  # Change 8080 to any available port
```

### Android Build Fails
Ensure you have accepted Android licenses:
```bash
docker-compose --profile build run flutter-android flutter doctor --android-licenses
```

### Backend Connection Issues
Make sure the backend is running and healthy:
```bash
docker-compose ps backend
docker-compose logs backend
```

## Production Deployment

### Web
1. Build the production image:
```bash
docker build -f Dockerfile.web -t aurumharmony-flutter-web:latest .
```

2. Deploy to your container orchestration platform (Kubernetes, ECS, etc.)

3. Update backend URLs to production endpoints

### Android
1. Build the APK:
```bash
docker-compose --profile build up flutter-android
```

2. Sign the APK with your keystore:
```bash
jarsigner -keystore your-keystore.jks app-release.apk your-alias
```

3. Distribute via Google Play Store or other channels

### iOS
1. Use a macOS machine or CI/CD with macOS runners
2. Build the iOS app:
```bash
flutter build ios --release
```
3. Archive and submit to App Store using Xcode

## Monitoring

Check service status:
```bash
# All services
docker-compose ps

# Flutter web logs
docker-compose logs -f flutter-web

# Backend logs
docker-compose logs -f backend
```

Health checks:
- Web Frontend: http://localhost:8080
- Backend API: http://localhost:5000/health
- Admin API: http://localhost:5001/admin
