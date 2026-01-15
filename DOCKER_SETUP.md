# Docker Setup Guide for AurumHarmony

Quick guide to run AurumHarmony using Docker Compose for local development.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+

## Quick Start

### 1. Start All Services

```bash
# Start backend, PostgreSQL, and Redis
docker-compose up -d

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend
```

### 2. Initialize Database

```bash
# Run database migrations (first time only)
docker-compose exec backend python -c "from aurum_harmony.database.db import init_db; init_db()"
```

### 3. Access Services

- **Backend API**: http://localhost:5000
- **Secondary Port**: http://localhost:5001
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

### 4. Optional: Start pgAdmin (Database UI)

```bash
# Start with pgAdmin
docker-compose --profile tools up -d

# Access pgAdmin at http://localhost:5050
# Email: admin@aurumharmony.com
# Password: admin
```

## Environment Variables

### Option 1: Use .env file (Recommended)

```bash
# Copy example file
cp .env.example .env

# Edit .env with your actual values
nano .env

# Start with env file
docker-compose up -d
```

### Option 2: Edit docker-compose.yml

Modify the environment section in `docker-compose.yml` directly.

### Generate Secure Keys

```bash
# Flask Secret Key
python3 -c "import secrets; print(secrets.token_hex(32))"

# JWT Secret Key
python3 -c "import secrets; print(secrets.token_hex(32))"

# Encryption Key
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

## Common Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart a service
docker-compose restart backend

# View logs
docker-compose logs -f backend

# Execute command in container
docker-compose exec backend python manage.py some-command

# Rebuild after code changes
docker-compose up -d --build

# Stop and remove volumes (⚠️ deletes data)
docker-compose down -v

# Scale backend (multiple instances)
docker-compose up -d --scale backend=3
```

## Development Workflow

The `docker-compose.yml` mounts your local code into the container:

```yaml
volumes:
  - ./aurum_harmony:/app/aurum_harmony
  - ./api:/app/api
  - ./engines:/app/engines
```

**This means:**
- Code changes are reflected immediately
- No need to rebuild for Python changes
- Need to restart backend if changing dependencies: `docker-compose restart backend`

## Troubleshooting

### Database Connection Issues

```bash
# Check if PostgreSQL is ready
docker-compose exec postgres pg_isready -U aurum_user

# View PostgreSQL logs
docker-compose logs postgres
```

### Backend Won't Start

```bash
# Check logs
docker-compose logs backend

# Rebuild image
docker-compose build --no-cache backend
docker-compose up -d backend
```

### Port Already in Use

```bash
# Check what's using the port
sudo lsof -i :5000

# Change ports in docker-compose.yml
ports:
  - "5555:5000"  # Use different host port
```

### Clear Everything and Start Fresh

```bash
# Stop and remove containers, networks, and volumes
docker-compose down -v

# Remove images
docker-compose down --rmi all

# Start fresh
docker-compose up -d --build
```

## Production Deployment

For production, use the Kubernetes setup in `k8s/` directory instead:

```bash
# See k8s/README.md for full instructions
kubectl apply -f k8s/
```

## Architecture

```
┌─────────────────────────────────────┐
│     AurumHarmony Backend (Flask)    │
│         Port: 5000, 5001            │
└───────────┬─────────────────┬───────┘
            │                 │
            ↓                 ↓
  ┌─────────────────┐  ┌──────────────┐
  │   PostgreSQL    │  │    Redis     │
  │   Port: 5432    │  │  Port: 6379  │
  └─────────────────┘  └──────────────┘
```

## Next Steps

1. Configure your broker API keys in `.env`
2. Set up proper SECRET_KEY and JWT_SECRET_KEY
3. Initialize database with `init_db()`
4. Access the API at http://localhost:5000
5. Check logs: `docker-compose logs -f`

For questions, see the main README.md or deployment guides.
