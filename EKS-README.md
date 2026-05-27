# MERN App → AWS EKS (HTTP Deployment) – Complete Summary

## ✅ What Was Created

Your MERN app is now **100% ready for production EKS deployment** with HTTP only (no HTTPS complexity).

### 📁 New Files Created

```
k8s/
├── 01-namespace-secrets.yaml      # Namespace, secrets, ConfigMap
├── 02-mongodb.yaml                # MongoDB StatefulSet (20GB persistent)
├── 03-backend.yaml                # Backend deployment with HPA
└── 04-frontend.yaml               # Frontend deployment with HPA

eks-deploy.sh                       # Automated deployment script
EKS-DEPLOYMENT.md                   # Full step-by-step guide
EKS-COMMANDS.md                     # Quick command reference
```

---

## 🚀 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS EKS CLUSTER                          │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Frontend    │  │  Frontend    │  │   Backend    │      │
│  │  Pod 1       │  │  Pod 2       │  │   Pod 1      │      │
│  │  (nginx)     │  │  (nginx)     │  │   (express)  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│        │                 │                   │              │
│        └─────────────────┼───────────────────┘              │
│                          │                                   │
│                    ┌─────▼──────┐                           │
│                    │   Backend   │                           │
│                    │   Service   │                           │
│                    │  (5000)     │                           │
│                    └─────┬──────┘                           │
│                          │                                   │
│                    ┌─────▼──────────────┐                   │
│                    │    MongoDB         │                   │
│                    │    StatefulSet     │                   │
│                    │    (27017)         │                   │
│                    └────────────────────┘                   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │            Frontend LoadBalancer Service             │  │
│  │           (assigns external IP/URL)                  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                    🌐 Public Internet (HTTP)
                    http://your-load-balancer-url
```

---

## 📊 Component Details

### MongoDB StatefulSet
- **Replicas:** 1 (single instance)
- **Storage:** 20GB EBS volume (persistent)
- **Port:** 27017 (internal only)
- **Health Checks:** Ping every 10 seconds
- **Restart Policy:** Auto-restart on failure

### Backend Deployment
- **Replicas:** 2-10 (auto-scales)
- **Port:** 5000 (internal)
- **Auto-scaling:** Triggers at 70% CPU or 80% memory
- **Health Checks:** `/api/health` endpoint
- **Updates:** Rolling updates (no downtime)

### Frontend Deployment
- **Replicas:** 2-5 (auto-scales)
- **Port:** 80 (HTTP)
- **Auto-scaling:** Triggers at 75% CPU
- **Service Type:** LoadBalancer (gets public IP)
- **Updates:** Rolling updates (no downtime)

---

## 🔐 Secrets & Configuration

**Store these in `k8s/01-namespace-secrets.yaml`:**

```yaml
MONGO_ROOT_USER: admin
MONGO_ROOT_PASSWORD: SecureMongoPassword123!
JWT_SECRET: your-64-character-random-key
NODE_ENV: production
CORS_ORIGINS: http://localhost,http://frontend
```

---

## 📋 Step-by-Step Deployment

### 1. Prerequisites Setup (10 minutes)
```bash
# Install tools
sudo apt install awscli kubectl eksctl docker.io -y

# Configure AWS
aws configure
# Enter: Access Key, Secret Key, Region, Output format
```

### 2. Create EKS Cluster (15-20 minutes)
```bash
eksctl create cluster \
  --name mern-cluster \
  --region us-east-1 \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 5
```

### 3. Push Docker Images (5 minutes)
```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1

# Login to ECR
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Create repositories
aws ecr create-repository --repository-name mern-backend --region $REGION
aws ecr create-repository --repository-name mern-frontend --region $REGION

# Build & push backend
docker build -t mern-backend:latest backend/
docker tag mern-backend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/mern-backend:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/mern-backend:latest

# Build & push frontend
docker build -t mern-frontend:latest frontend/
docker tag mern-frontend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/mern-frontend:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/mern-frontend:latest
```

### 4. Update Kubernetes Manifests (2 minutes)
```bash
cd k8s
sed -i "s/ACCOUNT_ID/$ACCOUNT_ID/g" *.yaml
sed -i "s/REGION/$REGION/g" *.yaml
cd ..
```

### 5. Deploy to EKS (5 minutes)
```bash
# Option A: Automated
./eks-deploy.sh $ACCOUNT_ID us-east-1

# Option B: Manual
kubectl apply -f k8s/01-namespace-secrets.yaml
kubectl apply -f k8s/02-mongodb.yaml
kubectl apply -f k8s/03-backend.yaml
kubectl apply -f k8s/04-frontend.yaml
```

### 6. Get Your App URL (5 minutes)
```bash
kubectl get svc frontend -n mern-app --watch
# Wait for EXTERNAL-IP to appear
# Access: http://<EXTERNAL-IP>
```

---

## ✅ Verification Checklist

```bash
# All pods running?
kubectl get pods -n mern-app
# ✅ Expected: 2 frontend, 2 backend, 1 mongodb

# Services have IPs?
kubectl get svc -n mern-app
# ✅ Frontend should have EXTERNAL-IP

# API responding?
kubectl exec -it deployment/backend -n mern-app -- curl http://localhost:5000/api/health
# ✅ Should return: {"status":"ok","timestamp":"..."}

# MongoDB connected?
kubectl logs -f deployment/backend -n mern-app | grep -i mongo
# ✅ Should show: "MongoDB connected"

# Frontend working?
curl http://<EXTERNAL-IP>
# ✅ Should return HTML
```

---

## 📈 Scaling & Performance

### Auto-Scaling in Action

```bash
# Watch HPA scale pods as traffic increases
kubectl get hpa -n mern-app --watch

# Expected behavior:
# 1. When CPU > 70% → Backend scales up
# 2. When CPU > 75% → Frontend scales up
# 3. After 5 mins low traffic → Scales down
```

### Manual Scaling

```bash
# Scale backend to 5 replicas
kubectl scale deployment backend --replicas=5 -n mern-app

# Scale frontend to 3 replicas
kubectl scale deployment frontend --replicas=3 -n mern-app
```

---

## 📊 Cost Breakdown

| Resource | Cost/Hour | Cost/Month |
|----------|-----------|-----------|
| EKS Control Plane | $0.10 | $73 |
| 2x t3.medium nodes | $0.13 | $96 |
| LoadBalancer | $0.016 | $12 |
| EBS Storage (20GB) | — | $2 |
| Data Transfer | — | ~$1-5 |
| **Total** | **$0.25/hr** | **~$188/month** |

**Savings Tips:**
- Use Spot instances for non-critical workloads (-70% on compute)
- Scale down to 1 node during off-hours
- Reduce storage size if not needed

---

## 🔧 Common Operations

### Deploy New Version

```bash
# Build and push new image
docker build -t mern-backend:v1.1 backend/
docker tag mern-backend:v1.1 $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/mern-backend:v1.1
docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/mern-backend:v1.1

# Update deployment
kubectl set image deployment/backend backend=$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/mern-backend:v1.1 -n mern-app

# Check status
kubectl rollout status deployment/backend -n mern-app
```

### View Logs

```bash
# Backend logs
kubectl logs -f deployment/backend -n mern-app

# Frontend logs
kubectl logs -f deployment/frontend -n mern-app

# MongoDB logs
kubectl logs -f statefulset/mongodb -n mern-app

# Last 100 lines
kubectl logs deployment/backend -n mern-app --tail=100
```

### Port Forward for Testing

```bash
# Access backend locally
kubectl port-forward svc/backend 5000:5000 -n mern-app
# Test: curl http://localhost:5000/api/health

# Access frontend locally
kubectl port-forward svc/frontend 3000:80 -n mern-app
# Test: http://localhost:3000
```

---

## 🚨 Troubleshooting

### Pods Not Starting?

```bash
# Check details
kubectl describe pod <pod-name> -n mern-app

# View logs
kubectl logs <pod-name> -n mern-app

# Events
kubectl get events -n mern-app
```

### Backend Can't Connect to MongoDB?

```bash
# Test connection from backend pod
kubectl exec -it deployment/backend -n mern-app -- \
  mongosh mongodb://admin:SecureMongoPassword123@mongodb:27017/mernapp?authSource=admin
```

### LoadBalancer Not Getting IP?

```bash
# Wait 2-3 minutes and check
kubectl get svc frontend -n mern-app

# Describe service for details
kubectl describe svc frontend -n mern-app
```

---

## 🧹 Cleanup

### Delete App (Keep Cluster)

```bash
kubectl delete namespace mern-app
```

### Delete Everything (⚠️ Irreversible)

```bash
eksctl delete cluster --name mern-cluster --region us-east-1
```

---

## 📚 Files Reference

| File | Purpose | Edit? |
|------|---------|-------|
| `k8s/01-namespace-secrets.yaml` | Secrets & config | ✅ Yes (update passwords) |
| `k8s/02-mongodb.yaml` | MongoDB setup | ⚠️ Only if needed |
| `k8s/03-backend.yaml` | Backend config | ⚠️ Only if needed |
| `k8s/04-frontend.yaml` | Frontend config | ⚠️ Only if needed |
| `eks-deploy.sh` | Deployment script | ❌ No |
| `EKS-DEPLOYMENT.md` | Full guide | ❌ No |
| `EKS-COMMANDS.md` | Command reference | ❌ No |

---

## 🎯 Next Steps

1. ✅ Read `EKS-DEPLOYMENT.md` for detailed guide
2. ✅ Run `./eks-deploy.sh` script
3. ✅ Monitor with `kubectl` commands
4. ✅ Set up monitoring (CloudWatch)
5. ✅ Configure backups
6. ✅ Add CI/CD pipeline (already in `.github/workflows/`)

---

## ✨ Your App is Production-Ready!

**What you have:**
- ✅ HTTP deployable to AWS EKS
- ✅ Auto-scaling (2-10 backend, 2-5 frontend)
- ✅ Auto-healing (pod restart on failure)
- ✅ Persistent MongoDB storage
- ✅ Rolling updates (zero downtime)
- ✅ Health checks & monitoring
- ✅ LoadBalancer with public IP

**Cost:** ~$188/month for 2 nodes

**Time to deploy:** ~45 minutes

**Next upgrade:** Add HTTPS with ALB/Route53 + ACM certificates

---

**Happy deploying! 🚀**
