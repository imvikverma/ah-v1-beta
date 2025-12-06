# AurumHarmony Kubernetes Deployment

Complete Kubernetes setup for deploying AurumHarmony to production on AWS EKS (Mumbai region).

## 📋 Prerequisites

1. **Kubernetes Cluster** (AWS EKS recommended)
   - Minimum: 3 nodes (t3.medium or larger)
   - Region: ap-south-1 (Mumbai) for data residency

2. **kubectl** configured to access your cluster

3. **Docker** and container registry (ECR, Docker Hub, etc.)

4. **AWS ALB Ingress Controller** installed in cluster

5. **Storage Class** configured (gp3 for EBS in Mumbai)

## 🚀 Quick Start

### 1. Build and Push Docker Image

```bash
# Build the image
docker build -f k8s/Dockerfile -t aurumharmony/backend:latest .

# Tag for your registry (example: AWS ECR)
docker tag aurumharmony/backend:latest YOUR_ACCOUNT.dkr.ecr.ap-south-1.amazonaws.com/aurumharmony/backend:latest

# Push to registry
docker push YOUR_ACCOUNT.dkr.ecr.ap-south-1.amazonaws.com/aurumharmony/backend:latest
```

### 2. Create Secrets

```bash
# Copy the template
cp k8s/secrets.yaml.template k8s/secrets.yaml

# Edit secrets.yaml with your actual values
# IMPORTANT: Generate strong passwords and keys!

# Create the secret
kubectl apply -f k8s/secrets.yaml
```

**Generate Secrets:**
```bash
# Flask Secret Key
python -c "import secrets; print(secrets.token_hex(32))"

# JWT Secret Key
python -c "import secrets; print(secrets.token_hex(32))"

# Encryption Key (32 bytes for Fernet)
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

### 3. Deploy to Kubernetes

```bash
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Create ConfigMap
kubectl apply -f k8s/configmap.yaml

# Deploy PostgreSQL
kubectl apply -f k8s/postgres-statefulset.yaml

# Deploy Redis
kubectl apply -f k8s/redis-deployment.yaml

# Wait for database to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n aurumharmony --timeout=300s

# Deploy Backend
kubectl apply -f k8s/backend-deployment.yaml

# Deploy HPA (Auto-scaling)
kubectl apply -f k8s/hpa.yaml

# Deploy Ingress (update certificate ARN first!)
kubectl apply -f k8s/ingress.yaml
```

### 4. Initialize Database

```bash
# Get a pod name
POD_NAME=$(kubectl get pods -n aurumharmony -l app=aurumharmony-backend -o jsonpath='{.items[0].metadata.name}')

# Run database migrations
kubectl exec -n aurumharmony $POD_NAME -- python -c "
from aurum_harmony.database.db import init_db
init_db()
"
```

## 📊 Architecture

```
┌─────────────────────────────────────────────────┐
│              AWS ALB (Ingress)                  │
│         api.aurumharmony.com:443                 │
└──────────────────┬──────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
   ┌────▼────┐          ┌──────▼──────┐
   │ Backend │          │   Backend   │
   │  Pod 1  │          │   Pod 2-N    │
   └────┬────┘          └──────┬───────┘
        │                     │
        └──────────┬──────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
   ┌────▼────┐          ┌──────▼──────┐
   │PostgreSQL│         │    Redis    │
   │StatefulSet│        │ Deployment  │
   └──────────┘         └─────────────┘
```

## 🔧 Configuration

### Scaling

The HPA automatically scales based on CPU (70%) and Memory (80%):

- **Min Replicas**: 3
- **Max Replicas**: 50
- **Target**: 15,000 users by 2030

### Resource Limits

**Backend Pods:**
- Requests: 512Mi memory, 250m CPU
- Limits: 2Gi memory, 1000m CPU

**PostgreSQL:**
- Requests: 512Mi memory, 250m CPU
- Limits: 2Gi memory, 1000m CPU
- Storage: 50Gi (adjustable)

**Redis:**
- Requests: 256Mi memory, 100m CPU
- Limits: 1Gi memory, 500m CPU

### Health Checks

All services include:
- **Liveness Probe**: Restarts container if unhealthy
- **Readiness Probe**: Removes from load balancer if not ready
- **Startup Probe**: Allows time for slow startup

## 🔐 Security

1. **Secrets Management**: All sensitive data in Kubernetes Secrets
2. **Network Policies**: Consider adding NetworkPolicies for pod-to-pod communication
3. **TLS**: Ingress configured for HTTPS with AWS ACM certificate
4. **RBAC**: Create ServiceAccounts with minimal permissions

## 📈 Monitoring

### Recommended Tools

1. **Prometheus + Grafana**: Metrics and dashboards
2. **ELK Stack**: Log aggregation
3. **AWS CloudWatch**: Cloud-native monitoring
4. **Kubernetes Dashboard**: Cluster overview

### Key Metrics to Monitor

- Pod CPU/Memory usage
- Request latency (p50, p95, p99)
- Error rates
- Database connection pool
- Redis cache hit rate
- Active users and trades

## 🔄 Updates and Rollouts

### Rolling Update

```bash
# Update image
kubectl set image deployment/aurumharmony-backend \
  flask-backend=aurumharmony/backend:v1.1.0 \
  -n aurumharmony

# Watch rollout
kubectl rollout status deployment/aurumharmony-backend -n aurumharmony

# Rollback if needed
kubectl rollout undo deployment/aurumharmony-backend -n aurumharmony
```

### Database Migrations

```bash
# Run migrations in a job
kubectl create job --from=cronjob/migrate-db migrate-db-manual -n aurumharmony
```

## 🐛 Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n aurumharmony
kubectl describe pod <pod-name> -n aurumharmony
kubectl logs <pod-name> -n aurumharmony
```

### Check Services

```bash
kubectl get svc -n aurumharmony
kubectl describe svc <service-name> -n aurumharmony
```

### Check Ingress

```bash
kubectl get ingress -n aurumharmony
kubectl describe ingress aurumharmony-ingress -n aurumharmony
```

### Database Connection Issues

```bash
# Test database connectivity
kubectl exec -it <backend-pod> -n aurumharmony -- \
  python -c "from aurum_harmony.database.db import db; print('Connected!')"
```

## 📝 Environment-Specific Configs

For different environments (dev, staging, prod), create separate:

- `k8s/configmap-dev.yaml`
- `k8s/configmap-prod.yaml`
- `k8s/secrets-dev.yaml` (stored in sealed-secrets or external secret manager)
- `k8s/secrets-prod.yaml` (stored in sealed-secrets or external secret manager)

## 🔗 Related Documentation

- [AWS EKS Setup Guide](https://docs.aws.amazon.com/eks/)
- [ALB Ingress Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

## 📞 Support

For issues or questions:
1. Check pod logs: `kubectl logs -n aurumharmony <pod-name>`
2. Check events: `kubectl get events -n aurumharmony --sort-by='.lastTimestamp'`
3. Review this README and Kubernetes documentation

