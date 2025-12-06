#!/bin/bash
# AurumHarmony Kubernetes Deployment Script
# Usage: ./k8s/deploy.sh [environment]

set -e

ENVIRONMENT=${1:-production}
NAMESPACE="aurumharmony"

echo "🚀 Deploying AurumHarmony to Kubernetes (${ENVIRONMENT})..."

# Check kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: kubectl is not configured or cluster is not accessible"
    exit 1
fi

# Create namespace
echo "📦 Creating namespace..."
kubectl apply -f k8s/namespace.yaml

# Check if secrets exist
if ! kubectl get secret aurumharmony-secrets -n ${NAMESPACE} &> /dev/null; then
    echo "⚠️  Warning: Secrets not found!"
    echo "   Please create k8s/secrets.yaml from k8s/secrets.yaml.template"
    echo "   Then run: kubectl apply -f k8s/secrets.yaml"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Apply ConfigMap
echo "⚙️  Applying ConfigMap..."
kubectl apply -f k8s/configmap.yaml

# Deploy PostgreSQL
echo "🗄️  Deploying PostgreSQL..."
kubectl apply -f k8s/postgres-statefulset.yaml

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n ${NAMESPACE} --timeout=300s || {
    echo "❌ PostgreSQL failed to start"
    kubectl logs -l app=postgres -n ${NAMESPACE} --tail=50
    exit 1
}

# Deploy Redis
echo "📦 Deploying Redis..."
kubectl apply -f k8s/redis-deployment.yaml

# Wait for Redis to be ready
echo "⏳ Waiting for Redis to be ready..."
kubectl wait --for=condition=ready pod -l app=redis -n ${NAMESPACE} --timeout=120s || {
    echo "❌ Redis failed to start"
    kubectl logs -l app=redis -n ${NAMESPACE} --tail=50
    exit 1
}

# Deploy Backend
echo "🚀 Deploying Backend..."
kubectl apply -f k8s/backend-deployment.yaml

# Wait for Backend to be ready
echo "⏳ Waiting for Backend to be ready..."
kubectl wait --for=condition=ready pod -l app=aurumharmony-backend -n ${NAMESPACE} --timeout=300s || {
    echo "❌ Backend failed to start"
    kubectl logs -l app=aurumharmony-backend -n ${NAMESPACE} --tail=50
    exit 1
}

# Deploy HPA
echo "📈 Deploying HorizontalPodAutoscaler..."
kubectl apply -f k8s/hpa.yaml

# Deploy Ingress (optional, may need certificate ARN)
echo "🌐 Deploying Ingress..."
read -p "Deploy Ingress? (requires certificate ARN configured) (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl apply -f k8s/ingress.yaml
    echo "✅ Ingress deployed. Check ALB creation in AWS console."
else
    echo "⏭️  Skipping Ingress deployment"
fi

# Show status
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Status:"
kubectl get all -n ${NAMESPACE}
echo ""
echo "🔍 To check logs:"
echo "   kubectl logs -l app=aurumharmony-backend -n ${NAMESPACE}"
echo ""
echo "🌐 To access services:"
echo "   kubectl port-forward -n ${NAMESPACE} svc/aurumharmony-backend-service 5000:5000"

