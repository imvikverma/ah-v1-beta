#!/usr/bin/env python3
"""
AurumHarmony Deployment Setup Script

Prepares the project for deployment to GitHub, Cloudflare, Firebase, and Render.
"""

import os
import json
from pathlib import Path
from datetime import datetime

def setup_deployment():
    """Setup all deployment configurations."""
    print("AurumHarmony Deployment Setup")
    print("=" * 35)

    project_root = Path(__file__).parent

    # Create .gitignore
    create_gitignore(project_root)

    # Setup admin panel for Cloudflare
    setup_cloudflare_admin(project_root)

    # Setup Flutter app for Firebase
    setup_firebase_flutter(project_root)

    # Setup backend for Render
    setup_render_backend(project_root)

    # Create requirements.txt
    create_requirements(project_root)

    print("\nDeployment setup completed!")
    print("\nNext steps:")
    print("1. Create GitHub repository and push code")
    print("2. Deploy admin panel: wrangler pages deploy aurum_harmony/admin_panel")
    print("3. Deploy Flutter app: cd aurum_harmony/frontend/flutter_app && firebase deploy")
    print("4. Deploy backend: Create Render.com service with build/start commands")

def create_gitignore(project_root):
    """Create comprehensive .gitignore."""
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

    gitignore_path = project_root / '.gitignore'
    with open(gitignore_path, 'w') as f:
        f.write(gitignore_content)

    print("Created .gitignore")

def setup_cloudflare_admin(project_root):
    """Setup admin panel for Cloudflare Pages."""
    admin_dir = project_root / 'aurum_harmony' / 'admin_panel'

    # Create wrangler.toml
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

    print("Configured admin panel for Cloudflare Pages")

def setup_firebase_flutter(project_root):
    """Setup Flutter app for Firebase Hosting."""
    flutter_dir = project_root / 'aurum_harmony' / 'frontend' / 'flutter_app'

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

    print("Configured Flutter app for Firebase Hosting")

def setup_render_backend(project_root):
    """Setup backend for Render.com."""
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

    render_path = project_root / 'render.yaml'
    with open(render_path, 'w') as f:
        json.dump(render_config, f, indent=2)

    print("Configured backend for Render.com")

def create_requirements(project_root):
    """Create requirements.txt for backend."""
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
pytz==2023.3
"""

    req_path = project_root / 'requirements.txt'
    with open(req_path, 'w') as f:
        f.write(requirements)

    print("Created requirements.txt")

if __name__ == "__main__":
    setup_deployment()
