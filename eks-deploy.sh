#!/bin/bash

# ──────────────────────────────────────────────────────────────────────
# MERN App – EKS Deployment Script (HTTP-only, simplified)
# ──────────────────────────────────────────────────────────────────────
# Usage: ./eks-deploy.sh <aws-account-id> <region>
# Example: ./eks-deploy.sh 123456789012 us-east-1
# ──────────────────────────────────────────────────────────────────────

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <aws-account-id> <region>"
    echo "Example: $0 123456789012 us-east-1"
    exit 1
fi

ACCOUNT_ID=$1
REGION=$2
CLUSTER_NAME="mern-cluster"
PROJECT_NAME="mern-app"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         MERN App – EKS Deployment Script (HTTP)               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "AWS Account ID: $ACCOUNT_ID"
echo "Region: $REGION"
echo "Cluster Name: $CLUSTER_NAME"
echo ""

# ── Step 1: Prerequisites Check ────────────────────────────────────
echo "🔍 Checking prerequisites..."
command -v aws &> /dev/null || { echo "❌ AWS CLI not installed"; exit 1; }
command -v kubectl &> /dev/null || { echo "❌ kubectl not installed"; exit 1; }
command -v docker &> /dev/null || { echo "❌ Docker not installed"; exit 1; }

# ── Step 2: Create EKS Cluster ────────────────────────────────────
echo ""
echo "📋 EKS Cluster Status:"
if aws eks describe-cluster --name $CLUSTER_NAME --region $REGION &> /dev/null; then
    echo "✅ Cluster '$CLUSTER_NAME' already exists"
else
    echo "❌ Cluster not found. Creating..."
    echo ""
    echo "Run this command to create cluster:"
    echo ""
    echo "eksctl create cluster \\"
    echo "  --name $CLUSTER_NAME \\"
    echo "  --region $REGION \\"
    echo "  --nodegroup-name workers \\"
    echo "  --node-type t3.medium \\"
    echo "  --nodes 2 \\"
    echo "  --nodes-min 2 \\"
    echo "  --nodes-max 5 \\"
    echo "  --managed"
    echo ""
    read -p "Press ENTER after cluster is created..."
fi

# ── Step 3: Configure kubectl ──────────────────────────────────────
echo ""
echo "🔐 Configuring kubectl..."
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION
kubectl cluster-info

# ── Step 4: Build and Push Docker Images ──────────────────────────
echo ""
echo "🐳 Docker Images:"
read -p "Did you already push images to ECR? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Login to ECR:"
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
    
    echo ""
    echo "Creating ECR repositories..."
    aws ecr create-repository --repository-name mern-backend --region $REGION 2>/dev/null || echo "Repository already exists"
    aws ecr create-repository --repository-name mern-frontend --region $REGION 2>/dev/null || echo "Repository already exists"
    
    echo ""
    echo "Building and pushing backend..."
    docker build -t mern-backend:latest backend/
    docker tag mern-backend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/mern-backend:latest
    docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/mern-backend:latest
    
    echo ""
    echo "Building and pushing frontend..."
    docker build -t mern-frontend:latest frontend/
    docker tag mern-frontend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/mern-frontend:latest
    docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/mern-frontend:latest
fi

# ── Step 5: Update Kubernetes Manifests ────────────────────────────
echo ""
echo "📝 Updating Kubernetes manifests..."
cd k8s
for file in *.yaml; do
    sed -i "s/ACCOUNT_ID/$ACCOUNT_ID/g" "$file"
    sed -i "s/REGION/$REGION/g" "$file"
done
cd ..

# ── Step 6: Deploy to EKS ──────────────────────────────────────────
echo ""
echo "🚀 Deploying to EKS..."
echo ""

echo "📦 Step 1: Creating namespace and secrets..."
kubectl apply -f k8s/01-namespace-secrets.yaml
sleep 5

echo ""
echo "📦 Step 2: Deploying MongoDB..."
kubectl apply -f k8s/02-mongodb.yaml
echo "⏳ Waiting for MongoDB to be ready (this may take 1-2 minutes)..."
kubectl wait --for=condition=Ready pod -l app=mongodb -n mern-app --timeout=300s 2>/dev/null || true
sleep 10

echo ""
echo "📦 Step 3: Deploying Backend..."
kubectl apply -f k8s/03-backend.yaml
echo "⏳ Waiting for Backend to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/backend -n mern-app 2>/dev/null || true
sleep 5

echo ""
echo "📦 Step 4: Deploying Frontend..."
kubectl apply -f k8s/04-frontend.yaml
echo "⏳ Waiting for Frontend to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n mern-app 2>/dev/null || true
sleep 5

# ── Step 7: Display Results ────────────────────────────────────────
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                   ✅ Deployment Complete!                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "📊 Pod Status:"
kubectl get pods -n mern-app
echo ""

echo "🔌 Services:"
kubectl get svc -n mern-app
echo ""

echo "🌐 Frontend URL:"
FRONTEND_URL=$(kubectl get svc frontend -n mern-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending...")
echo "http://$FRONTEND_URL"
echo ""

echo "📋 Useful Commands:"
echo "  • View all resources:     kubectl get all -n mern-app"
echo "  • View pod logs:          kubectl logs -f deployment/backend -n mern-app"
echo "  • Check pod details:      kubectl describe pod <pod-name> -n mern-app"
echo "  • Port forward backend:   kubectl port-forward svc/backend 5000:5000 -n mern-app"
echo "  • Port forward frontend:  kubectl port-forward svc/frontend 3000:80 -n mern-app"
echo "  • Check resource usage:   kubectl top pods -n mern-app"
echo ""

echo "⏳ Note: Frontend LoadBalancer URL may take 2-3 minutes to assign."
echo "   Run: kubectl get svc frontend -n mern-app --watch"
echo ""
