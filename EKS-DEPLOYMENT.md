# 🚀 EKS Deployment Guide – HTTP Only

Complete step-by-step guide to deploy MERN app to AWS EKS cluster with HTTP (no HTTPS).

---

## Prerequisites

### 1. Install Required Tools

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# kubectl (Kubernetes CLI)
curl -LO https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# eksctl (EKS cluster manager)
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin/

# Docker
sudo apt install docker.io -y
sudo usermod -aG docker $USER
```

### 2. Configure AWS Credentials

```bash
aws configure
# Enter: Access Key ID
# Enter: Secret Access Key
# Enter: Region (e.g., us-east-1)
# Enter: Output format (json)
```

### 3. Get Your AWS Account ID

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Your AWS Account ID: $AWS_ACCOUNT_ID"
```

---

## Step 1: Create EKS Cluster

```bash
# Create cluster (takes 15-20 minutes)
eksctl create cluster \
  --name mern-cluster \
  --region us-east-1 \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 5 \
  --managed

# Verify
kubectl cluster-info
kubectl get nodes
```

**Output:** You should see 2 nodes running.

---

## Step 2: Push Docker Images to ECR

### Create ECR Repositories

```bash
REGION=us-east-1
ACCOUNT_ID=123456789012  # Replace with your account ID

# Create repositories
aws ecr create-repository \
  --repository-name mern-backend \
  --region $REGION

aws ecr create-repository \
  --repository-name mern-frontend \
  --region $REGION
```

### Build & Push Backend

```bash
# Login to ECR
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build backend
cd backend
docker build -t mern-backend:latest .

# Tag
docker tag mern-backend:latest \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/mern-backend:latest

# Push
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/mern-backend:latest
```

### Build & Push Frontend

```bash
# Build frontend
cd ../frontend
docker build -t mern-frontend:latest .

# Tag
docker tag mern-frontend:latest \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/mern-frontend:latest

# Push
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/mern-frontend:latest
```

---

## Step 3: Update Kubernetes Manifests

Replace placeholders in k8s files:

```bash
cd k8s

# Replace ACCOUNT_ID
sed -i "s/ACCOUNT_ID/123456789012/g" *.yaml

# Replace REGION
sed -i "s/REGION/us-east-1/g" *.yaml

cd ..
```

Or use the automated script:

```bash
chmod +x eks-deploy.sh
./eks-deploy.sh 123456789012 us-east-1
```

---

## Step 4: Deploy to EKS

### Option A: Automated Script (Recommended)

```bash
chmod +x eks-deploy.sh
./eks-deploy.sh 123456789012 us-east-1
```

### Option B: Manual Deployment

```bash
# 1. Create namespace and secrets
kubectl apply -f k8s/01-namespace-secrets.yaml

# 2. Deploy MongoDB
kubectl apply -f k8s/02-mongodb.yaml
kubectl wait --for=condition=Ready pod -l app=mongodb -n mern-app --timeout=300s

# 3. Deploy Backend
kubectl apply -f k8s/03-backend.yaml
kubectl wait --for=condition=available --timeout=300s deployment/backend -n mern-app

# 4. Deploy Frontend
kubectl apply -f k8s/04-frontend.yaml
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n mern-app
```

---

## Step 5: Get Your App URL

```bash
# Watch for LoadBalancer to assign external IP
kubectl get svc frontend -n mern-app --watch

# Copy the EXTERNAL-IP and access in browser
# Example: http://a1b2c3d4-1234567890.us-east-1.elb.amazonaws.com
```

---

## Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n mern-app

# Check services
kubectl get svc -n mern-app

# View pod logs
kubectl logs -f deployment/backend -n mern-app
kubectl logs -f deployment/frontend -n mern-app
kubectl logs -f statefulset/mongodb -n mern-app

# Test API health
kubectl exec -it deployment/backend -n mern-app -- curl http://localhost:5000/api/health

# Check resource usage
kubectl top pods -n mern-app
```

---

## Port Forwarding (Local Testing)

```bash
# Forward backend to local
kubectl port-forward svc/backend 5000:5000 -n mern-app
# Access: http://localhost:5000/api

# Forward frontend to local
kubectl port-forward svc/frontend 3000:80 -n mern-app
# Access: http://localhost:3000
```

---

## Scaling

```bash
# Manual scaling
kubectl scale deployment backend --replicas=5 -n mern-app

# Check HPA status
kubectl get hpa -n mern-app

# Watch auto-scaling
kubectl get hpa -n mern-app --watch
```

---

## Monitoring & Logs

```bash
# Real-time logs
kubectl logs -f deployment/backend -n mern-app

# Previous pod logs
kubectl logs deployment/backend -n mern-app --previous

# All logs from namespace
kubectl logs -n mern-app --all-containers=true --tail=50

# Follow multiple pods
kubectl logs -f deployment/backend -n mern-app --all-containers=true --max-log-requests=5
```

---

## Update & Redeploy

```bash
# After code changes, rebuild and push images
docker build -t mern-backend:latest backend/
docker tag mern-backend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/mern-backend:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/mern-backend:latest

# Kubernetes will auto-pull new image
kubectl rollout restart deployment/backend -n mern-app

# Check status
kubectl rollout status deployment/backend -n mern-app
```

---

## Troubleshooting

### Pods Not Starting?

```bash
# Check pod events
kubectl describe pod <pod-name> -n mern-app

# View pod logs
kubectl logs <pod-name> -n mern-app

# Check resource requests
kubectl top pods -n mern-app
```

### Backend Can't Connect to MongoDB?

```bash
# Check MongoDB is running
kubectl get pods -n mern-app | grep mongodb

# Test MongoDB connection
kubectl exec -it deployment/backend -n mern-app -- \
  mongosh mongodb://admin:SecureMongoPassword123@mongodb:27017/mernapp?authSource=admin
```

### Frontend Shows Blank Page?

```bash
# Check frontend logs
kubectl logs -f deployment/frontend -n mern-app

# Test API connectivity
kubectl exec -it deployment/frontend -n mern-app -- curl http://backend:5000/api/health
```

### LoadBalancer Pending?

```bash
# Check service status
kubectl describe svc frontend -n mern-app

# Wait for AWS to assign IP (2-3 minutes)
kubectl get svc frontend -n mern-app --watch
```

---

## Important Files

| File | Purpose |
|------|---------|
| `k8s/01-namespace-secrets.yaml` | Namespace, secrets, config |
| `k8s/02-mongodb.yaml` | MongoDB StatefulSet with persistence |
| `k8s/03-backend.yaml` | Backend deployment with HPA |
| `k8s/04-frontend.yaml` | Frontend deployment with HPA |
| `eks-deploy.sh` | Automated deployment script |

---

## Environment Variables in Secrets

Edit `k8s/01-namespace-secrets.yaml` before deploying:

```yaml
MONGO_ROOT_PASSWORD: YourStrongPassword123!
JWT_SECRET: YourLongRandomSecretKey...
```

---

## Cleanup & Cost Saving

```bash
# Delete all deployments (keep cluster)
kubectl delete namespace mern-app

# Delete EKS cluster (⚠️ irreversible)
eksctl delete cluster --name mern-cluster --region us-east-1
```

---

## Kubernetes Manifest Structure

```
k8s/
├── 01-namespace-secrets.yaml   # Secrets & ConfigMap
├── 02-mongodb.yaml              # MongoDB with persistence (20Gi)
├── 03-backend.yaml              # Backend with HPA (2-10 replicas)
└── 04-frontend.yaml             # Frontend with HPA (2-5 replicas)
```

---

## Resources & Limits

| Component | Requests | Limits |
|-----------|----------|--------|
| **Backend** | 100m CPU, 128Mi RAM | 500m CPU, 512Mi RAM |
| **Frontend** | 50m CPU, 64Mi RAM | 200m CPU, 256Mi RAM |
| **MongoDB** | 250m CPU, 256Mi RAM | 500m CPU, 512Mi RAM |

---

## Auto-Scaling Configuration

**Backend HPA:**
- Min replicas: 2
- Max replicas: 10
- Scale up: When CPU > 70% or Memory > 80%
- Scale down: After 3 minutes without high usage

**Frontend HPA:**
- Min replicas: 2
- Max replicas: 5
- Scale up: When CPU > 75%

---

## Cost Estimation (AWS EKS)

| Item | Hourly | Monthly |
|------|--------|---------|
| **EKS Control Plane** | $0.10 | ~$73 |
| **2x t3.medium nodes** | $0.13 | ~$96 |
| **Load Balancer** | $0.016 | ~$12 |
| **EBS Storage (20Gi)** | — | ~$2 |
| **Data Transfer** | — | ~$0-5 |
| **Total** | ~$0.25/hr | ~$188/month |

**Cost Optimization:**
- Use Spot instances for non-critical workloads
- Reduce node count during low traffic
- Use auto-scaling groups

---

## Support & Next Steps

1. ✅ Create EKS cluster
2. ✅ Push Docker images to ECR
3. ✅ Update Kubernetes manifests
4. ✅ Run eks-deploy.sh script
5. ✅ Access app via LoadBalancer URL
6. ✅ Monitor with kubectl commands
7. ✅ Scale as needed

For questions, check pod logs or describe resources for detailed error messages.

---

**Your app is now running on production-grade AWS EKS! 🎉**
