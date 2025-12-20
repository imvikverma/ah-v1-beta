#!/usr/bin/env python3
"""
AurumHarmony Deployment Script

Handles deployment to GitHub, Cloudflare Pages, Firebase Hosting, and Render.com
"""

import os
import sys
import subprocess
import json
from pathlib import Path
from datetime import datetime

class AurumHarmonyDeployer:
    def __init__(self):
        self.project_root = Path(__file__).parent
        self.timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

    def run_deployment_checks(self):
        """Run pre-deployment checks."""
        print("🔍 Running pre-deployment checks...")
        print("=" * 50)

        checks = [
            ("Project structure", self._check_project_structure),
            ("Flutter build", self._check_flutter_build),
            ("Admin panel assets", self._check_admin_panel),
            ("Backend dependencies", self._check_backend_deps),
            ("Environment configuration", self._check_env_config),
        ]

        passed = 0
        for check_name, check_func in checks:
            try:
                if check_func():
                    print(f"✅ {check_name}: PASSED")
                    passed += 1
                else:
                    print(f"❌ {check_name}: FAILED")
            except Exception as e:
                print(f"❌ {check_name}: ERROR - {e}")

        print(f"\nPre-deployment checks: {passed}/{len(checks)} passed")

        if passed == len(checks):
            print("🎉 All checks passed! Ready for deployment.")
            return True
        else:
            print("⚠️  Some checks failed. Please review before deploying.")
            return False

    def deploy_github(self):
        """Deploy to GitHub repository."""
        print("\n🚀 Deploying to GitHub...")
        print("=" * 30)

        try:
            # Check if git repository
            if not (self.project_root / '.git').exists():
                print("Initializing git repository...")
                subprocess.run(['git', 'init'], check=True, cwd=self.project_root)

            # Create .gitignore
            self._create_gitignore()

            # Add all files
            subprocess.run(['git', 'add', '.'], check=True, cwd=self.project_root)

            # Initial commit
            try:
                subprocess.run(['git', 'commit', '-m', f'Initial commit - AurumHarmony v1.0 ({self.timestamp})'],
                             check=True, cwd=self.project_root)
            except subprocess.CalledProcessError:
                # Commit might fail if already committed
                print("Repository already has commits")

            print("✅ GitHub repository prepared")
            print("📝 Next steps:")
            print("   1. Create repository on GitHub.com")
            print("   2. Add remote: git remote add origin <repository-url>")
            print("   3. Push: git push -u origin main")

            return True

        except Exception as e:
            print(f"❌ GitHub deployment failed: {e}")
            return False

    def deploy_admin_panel(self, platform='cloudflare'):
        """Deploy admin panel."""
        print(f"\n🚀 Deploying Admin Panel to {platform.title()}...")
        print("=" * 40)

        admin_dir = self.project_root / 'aurum_harmony' / 'admin_panel'

        if platform.lower() == 'cloudflare':
            return self._deploy_cloudflare_pages(admin_dir)
        elif platform.lower() == 'vercel':
            return self._deploy_vercel(admin_dir)
        else:
            print(f"❌ Unsupported platform: {platform}")
            return False

    def deploy_flutter_app(self, platform='firebase'):
        """Deploy Flutter app."""
        print(f"\n🚀 Deploying Flutter App to {platform.title()}...")
        print("=" * 40)

        flutter_dir = self.project_root / 'aurum_harmony' / 'frontend' / 'flutter_app'

        if platform.lower() == 'firebase':
            return self._deploy_firebase(flutter_dir)
        elif platform.lower() == 'vercel':
            return self._deploy_flutter_vercel(flutter_dir)
        else:
            print(f"❌ Unsupported platform: {platform}")
            return False

    def deploy_backend(self, platform='render'):
        """Deploy backend."""
        print(f"\n🚀 Deploying Backend to {platform.title()}...")
        print("=" * 40)

        if platform.lower() == 'render':
            return self._deploy_render()
        elif platform.lower() == 'heroku':
            return self._deploy_heroku()
        else:
            print(f"❌ Unsupported platform: {platform}")
            return False

    def _check_project_structure(self):
        """Check project structure."""
        required_files = [
            'aurum_harmony/master_codebase/Master_AurumHarmony_261125.py',
            'aurum_harmony/frontend/flutter_app/pubspec.yaml',
            'aurum_harmony/admin_panel/index.html',
        ]

        for file_path in required_files:
            if not (self.project_root / file_path).exists():
                print(f"Missing: {file_path}")
                return False

        return True

    def _check_flutter_build(self):
        """Check Flutter build capability."""
        try:
            flutter_dir = self.project_root / 'aurum_harmony' / 'frontend' / 'flutter_app'

            # Check if pubspec.yaml exists
            pubspec = flutter_dir / 'pubspec.yaml'
            if not pubspec.exists():
                return False

            # Try to get Flutter version (basic check)
            result = subprocess.run(['flutter', '--version'],
                                  capture_output=True, text=True, timeout=10)
            return result.returncode == 0

        except:
            return False

    def _check_admin_panel(self):
        """Check admin panel assets."""
        admin_dir = self.project_root / 'aurum_harmony' / 'admin_panel'
        required_files = ['index.html', 'styles.css', 'script.js']

        for file_name in required_files:
            if not (admin_dir / file_name).exists():
                return False

        return True

    def _check_backend_deps(self):
        """Check backend dependencies."""
        try:
            # Check if requirements.txt exists
            req_file = self.project_root / 'requirements.txt'
            if not req_file.exists():
                print("Warning: requirements.txt not found")
                return True  # Not critical for basic deployment

            # Try importing key modules
            import flask
            import sqlalchemy
            return True

        except ImportError as e:
            print(f"Missing backend dependency: {e}")
            return False

    def _check_env_config(self):
        """Check environment configuration."""
        # Check for environment files (but don't expose secrets)
        env_files = ['.env', '.env.local', '.env.production']

        found_config = False
        for env_file in env_files:
            if (self.project_root / env_file).exists():
                found_config = True
                break

        if not found_config:
            print("Warning: No environment configuration found")
            print("Make sure to configure secrets in deployment platform")

        return True  # Not blocking

    def _create_gitignore(self):
        """Create .gitignore file."""
        gitignore_content = """# AurumHarmony .gitignore

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Flutter
aurum_harmony/frontend/flutter_app/.flutter-plugins
aurum_harmony/frontend/flutter_app/.flutter-plugins-dependencies
aurum_harmony/frontend/flutter_app/.packages
aurum_harmony/frontend/flutter_app/.dart_tool/
aurum_harmony/frontend/flutter_app/build/
aurum_harmony/frontend/flutter_app/android/app/debug
aurum_harmony/frontend/flutter_app/android/app/profile
aurum_harmony/frontend/flutter_app/android/app/release
aurum_harmony/frontend/flutter_app/ios/Flutter/App.framework
aurum_harmony/frontend/flutter_app/ios/Flutter/flutter.framework

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Logs
*.log
logs/

# Database
*.db
*.sqlite
*.sqlite3

# Temporary files
tmp/
temp/
*.tmp

# Secrets and keys
secrets/
keys/
*.key
*.pem
*.crt
"""

        gitignore_path = self.project_root / '.gitignore'
        with open(gitignore_path, 'w') as f:
            f.write(gitignore_content)

        print("Created .gitignore file")

    def _deploy_cloudflare_pages(self, admin_dir):
        """Deploy to Cloudflare Pages."""
        try:
            # Create wrangler.toml for Cloudflare Pages
            wrangler_config = f"""name = "aurumharmony-admin"
compatibility_date = "{datetime.now().strftime('%Y-%m-%d')}"

[env.production]
routes = ["admin-v2.saffronbolt.in/*"]

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
    Referrer-Policy = "strict-origin-when-cross-origin"
"""

            wrangler_path = admin_dir / 'wrangler.toml'
            with open(wrangler_path, 'w') as f:
                f.write(wrangler_config)

            print("✅ Admin panel configured for Cloudflare Pages")
            print("📝 Deployment steps:")
            print("   1. Install Wrangler: npm install -g wrangler")
            print("   2. Login: wrangler auth login")
            print("   3. Deploy: wrangler pages deploy aurum_harmony/admin_panel")

            return True

        except Exception as e:
            print(f"❌ Cloudflare deployment setup failed: {e}")
            return False

    def _deploy_firebase(self, flutter_dir):
        """Deploy Flutter app to Firebase."""
        try:
            # Create firebase.json
            firebase_config = {
                "hosting": {
                    "public": "build/web",
                    "ignore": [
                        "firebase.json",
                        "**/.*",
                        "**/node_modules/**"
                    ],
                    "rewrites": [
                        {
                            "source": "**",
                            "destination": "/index.html"
                        }
                    ],
                    "headers": [
                        {
                            "source": "**/*.js",
                            "headers": [
                                {
                                    "key": "Cache-Control",
                                    "value": "max-age=31536000"
                                }
                            ]
                        },
                        {
                            "source": "**/*.css",
                            "headers": [
                                {
                                    "key": "Cache-Control",
                                    "value": "max-age=31536000"
                                }
                            ]
                        }
                    ]
                }
            }

            firebase_path = flutter_dir / 'firebase.json'
            with open(firebase_path, 'w') as f:
                json.dump(firebase_config, f, indent=2)

            # Create .firebaserc
            firebaserc_config = {
                "projects": {
                    "default": "aurumharmony-prod"
                }
            }

            firebaserc_path = flutter_dir / '.firebaserc'
            with open(firebaserc_path, 'w') as f:
                json.dump(firebaserc_config, f, indent=2)

            print("✅ Flutter app configured for Firebase Hosting")
            print("📝 Deployment steps:")
            print("   1. Install Firebase CLI: npm install -g firebase-tools")
            print("   2. Login: firebase login")
            print("   3. Initialize: cd aurum_harmony/frontend/flutter_app && firebase init")
            print("   4. Deploy: firebase deploy --only hosting")

            return True

        except Exception as e:
            print(f"❌ Firebase deployment setup failed: {e}")
            return False

    def _deploy_render(self):
        """Deploy backend to Render."""
        try:
            # Create render.yaml
            render_config = {
                "services": [
                    {
                        "type": "web",
                        "name": "aurumharmony-backend",
                        "runtime": "python3",
                        "buildCommand": "pip install -r requirements.txt",
                        "startCommand": "python aurum_harmony/master_codebase/Master_AurumHarmony_261125.py",
                        "envVars": [
                            {
                                "key": "FLASK_ENV",
                                "value": "production"
                            },
                            {
                                "key": "PYTHON_VERSION",
                                "value": "3.8"
                            }
                        ]
                    }
                ]
            }

            render_path = self.project_root / 'render.yaml'
            with open(render_path, 'w') as f:
                json.dump(render_config, f, indent=2)

            # Create requirements.txt if it doesn't exist
            req_path = self.project_root / 'requirements.txt'
            if not req_path.exists():
                requirements = """Flask==2.3.3
Flask-CORS==4.0.0
Flask-SQLAlchemy==3.0.5
python-jose[cryptography]==3.3.0
passlib==1.7.4
bcrypt==4.0.1
requests==2.31.0
pandas==2.0.3
numpy==1.24.3
scikit-learn==1.3.0
tensorflow==2.13.0
torch==2.0.1
backtrader==1.9.76.122
yfinance==0.2.18
beautifulsoup4==4.12.2
feedparser==6.0.10
schedule==1.2.0
pytz==2023.3
"""

                with open(req_path, 'w') as f:
                    f.write(requirements)

            print("✅ Backend configured for Render deployment")
            print("📝 Deployment steps:")
            print("   1. Go to render.com and create new Web Service")
            print("   2. Connect GitHub repository")
            print("   3. Set build command: pip install -r requirements.txt")
            print("   4. Set start command: python aurum_harmony/master_codebase/Master_AurumHarmony_261125.py")
            print("   5. Add environment variables (database URL, API keys, etc.)")

            return True

        except Exception as e:
            print(f"❌ Render deployment setup failed: {e}")
            return False

    def _deploy_vercel(self, app_dir):
        """Deploy to Vercel."""
        try:
            # Create vercel.json
            vercel_config = {
                "version": 2,
                "builds": [
                    {
                        "src": "index.html",
                        "use": "@vercel/static"
                    }
                ],
                "routes": [
                    {
                        "src": "/(.*)",
                        "dest": "/index.html"
                    }
                ],
                "headers": [
                    {
                        "source": "/(.*)",
                        "headers": [
                            {
                                "key": "X-Frame-Options",
                                "value": "DENY"
                            },
                            {
                                "key": "X-Content-Type-Options",
                                "value": "nosniff"
                            }
                        ]
                    }
                ]
            }

            vercel_path = app_dir / 'vercel.json'
            with open(vercel_path, 'w') as f:
                json.dump(vercel_config, f, indent=2)

            print(f"✅ {app_dir.name} configured for Vercel deployment")
            print("📝 Deployment steps:")
            print(f"   1. cd {app_dir}")
            print("   2. Install Vercel CLI: npm install -g vercel")
            print("   3. Deploy: vercel --prod")

            return True

        except Exception as e:
            print(f"❌ Vercel deployment setup failed: {e}")
            return False

    def _deploy_heroku(self):
        """Deploy backend to Heroku."""
        try:
            # Create Procfile
            procfile_content = "web: python aurum_harmony/master_codebase/Master_AurumHarmony_261125.py"

            procfile_path = self.project_root / 'Procfile'
            with open(procfile_path, 'w') as f:
                f.write(procfile_content)

            # Create runtime.txt
            runtime_content = "python-3.8.17"

            runtime_path = self.project_root / 'runtime.txt'
            with open(runtime_path, 'w') as f:
                f.write(runtime_content)

            print("✅ Backend configured for Heroku deployment")
            print("📝 Deployment steps:")
            print("   1. Install Heroku CLI")
            print("   2. Login: heroku login")
            print("   3. Create app: heroku create aurumharmony-backend")
            print("   4. Set environment variables: heroku config:set KEY=value")
            print("   5. Deploy: git push heroku main")

            return True

        except Exception as e:
            print(f"❌ Heroku deployment setup failed: {e}")
            return False

    def _deploy_flutter_vercel(self, flutter_dir):
        """Deploy Flutter web to Vercel."""
        try:
            # Create vercel.json for Flutter web
            vercel_config = {
                "version": 2,
                "builds": [
                    {
                        "src": "build/web/index.html",
                        "use": "@vercel/static-build",
                        "config": {
                            "distDir": "build/web"
                        }
                    }
                ],
                "routes": [
                    {
                        "src": "/(.*)",
                        "dest": "/build/web/$1"
                    }
                ]
            }

            vercel_path = flutter_dir / 'vercel.json'
            with open(vercel_path, 'w') as f:
                json.dump(vercel_config, f, indent=2)

            print("✅ Flutter app configured for Vercel deployment")
            print("📝 Deployment steps:")
            print("   1. cd aurum_harmony/frontend/flutter_app")
            print("   2. Build web: flutter build web --release")
            print("   3. Install Vercel CLI: npm install -g vercel")
            print("   4. Deploy: vercel --prod")

            return True

        except Exception as e:
            print(f"❌ Flutter Vercel deployment setup failed: {e}")
            return False

def main():
    """Main deployment function."""
    print("🚀 AurumHarmony Deployment Setup")
    print("=" * 40)

    deployer = AurumHarmonyDeployer()

    # Run checks
    if not deployer.run_deployment_checks():
        print("❌ Pre-deployment checks failed. Please fix issues before deploying.")
        return 1

    # Deployment options
    print("\n📋 Available Deployment Options:")
    print("1. GitHub Repository Setup")
    print("2. Admin Panel → Cloudflare Pages")
    print("3. Flutter App → Firebase Hosting")
    print("4. Backend → Render.com")
    print("5. All of the above")

    choice = input("\nSelect deployment option (1-5): ").strip()

    success = True

    if choice in ['1', '5']:
        if not deployer.deploy_github():
            success = False

    if choice in ['2', '5']:
        if not deployer.deploy_admin_panel('cloudflare'):
            success = False

    if choice in ['3', '5']:
        if not deployer.deploy_flutter_app('firebase'):
            success = False

    if choice in ['4', '5']:
        if not deployer.deploy_backend('render'):
            success = False

    if success:
        print("\n🎉 Deployment setup completed successfully!")
        print("\n📝 Next Steps:")
        print("1. Create GitHub repository and push code")
        print("2. Set up Cloudflare Pages for admin panel")
        print("3. Configure Firebase Hosting for Flutter app")
        print("4. Deploy backend to Render.com")
        print("5. Test all deployments and update API endpoints")
        return 0
    else:
        print("\n❌ Some deployments failed. Please check errors above.")
        return 1

if __name__ == "__main__":
    exit(main())
