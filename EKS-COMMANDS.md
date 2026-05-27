# EKS Deployment Quick Reference

## 🚀 Quick Start (5 Steps)

```bash
# 1. Get Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo $AWS_ACCOUNT_ID

# 2. Create cluster
eksctl create cluster --name mern-cluster --region us-east-1 --nodegroup-name workers --node-type t3.medium --nodes 2

# 3. Push images
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
# Build and push backend/frontend to ECR

# 4. Update manifests
cd k8s && sed -i "s/ACCOUNT_ID/$AWS_ACCOUNT_ID/g" *.yaml && sed -i "s/REGION/us-east-1/g" *.yaml && cd ..

# 5. Deploy
./eks-deploy.sh $AWS_ACCOUNT_ID us-east-1
```

---

## 📋 All Commands

### Cluster Management

```bash
# Create cluster
eksctl create cluster --name mern-cluster --region us-east-1 --nodegroup-name workers --node-type t3.medium --nodes 2

# Delete cluster
eksctl delete cluster --name mern-cluster

# Get cluster info
aws eks describe-cluster --name mern-cluster --region us-east-1

# Update kubectl config
aws eks update-kubeconfig --name mern-cluster --region us-east-1

# Get nodes
kubectl get nodes
```

### Pod Management

```bash
# Get all pods
kubectl get pods -n mern-app

# Get pod details
kubectl describe pod <pod-name> -n mern-app

# View pod logs
kubectl logs -f pod/<pod-name> -n mern-app

# Exec into pod
kubectl exec -it <pod-name> -n mern-app -- /bin/sh

# Port forward
kubectl port-forward pod/<pod-name> 5000:5000 -n mern-app
```

### Deployment Management

```bash
# Get deployments
kubectl get deployments -n mern-app

# Restart deployment
kubectl rollout restart deployment/backend -n mern-app

# Check rollout status
kubectl rollout status deployment/backend -n mern-app

# Scale deployment
kubectl scale deployment/backend --replicas=5 -n mern-app

# Update image
kubectl set image deployment/backend backend=$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/mern-backend:latest -n mern-app
```

### Service Management

```bash
# Get services
kubectl get svc -n mern-app

# Get service details
kubectl describe svc frontend -n mern-app

# Port forward service
kubectl port-forward svc/backend 5000:5000 -n mern-app
```

### StatefulSet Management (MongoDB)

```bash
# Get StatefulSets
kubectl get statefulset -n mern-app

# Delete StatefulSet (keeps pods)
kubectl delete statefulset mongodb -n mern-app

# Delete PVC (loses data)
kubectl delete pvc mongodb-storage-mongodb-0 -n mern-app
```

### Scaling & Auto-scaling

```bash
# View HPA status
kubectl get hpa -n mern-app

# Create HPA manually
kubectl autoscale deployment backend --min=2 --max=10 --cpu-percent=70 -n mern-app

# Watch HPA
kubectl get hpa -n mern-app --watch
```

### Logs & Monitoring

```bash
# Follow logs
kubectl logs -f deployment/backend -n mern-app

# Last 100 lines
kubectl logs -n mern-app deployment/backend --tail=100

# All containers in pod
kubectl logs -f pod/<pod-name> -n mern-app --all-containers=true

# Resource usage
kubectl top pods -n mern-app
kubectl top nodes

# Get events
kubectl get events -n mern-app --sort-by='.lastTimestamp'
```

### Configuration

```bash
# View secrets
kubectl get secrets -n mern-app

# Get secret value
kubectl get secret app-secret -n mern-app -o jsonpath='{.data.JWT_SECRET}' | base64 -d

# View ConfigMap
kubectl get configmap -n mern-app

# Edit ConfigMap
kubectl edit configmap app-config -n mern-app

# Edit Secret
kubectl edit secret app-secret -n mern-app
```

### Deployment Manifests

```bash
# Apply manifest
kubectl apply -f k8s/01-namespace-secrets.yaml

# Delete manifest
kubectl delete -f k8s/01-namespace-secrets.yaml

# Apply all manifests in folder
kubectl apply -f k8s/

# Delete all in folder
kubectl delete -f k8s/

# Dry run (preview)
kubectl apply -f k8s/03-backend.yaml --dry-run=client
```

### Cleanup

```bash
# Delete namespace (deletes all resources)
kubectl delete namespace mern-app

# Delete specific resource
kubectl delete deployment backend -n mern-app

# Delete all pods (restart)
kubectl delete pods --all -n mern-app

# Force delete stuck pod
kubectl delete pod <pod-name> -n mern-app --grace-period=0 --force
```

### Troubleshooting

```bash
# Check pod status
kubectl get pods -n mern-app -o wide

# Describe pod for errors
kubectl describe pod <pod-name> -n mern-app

# View all errors
kubectl get events -n mern-app

# Check resource limits
kubectl describe resourcequota -n mern-app

# Get container exit code
kubectl logs <pod-name> -n mern-app --previous

# Debug with interactive shell
kubectl debug pod/<pod-name> -it -n mern-app -- /bin/bash
```

---

## 🔗 Useful URLs

| Component | Type | Command |
|-----------|------|---------|
| Frontend | LoadBalancer | `kubectl get svc frontend -n mern-app` → EXTERNAL-IP |
| Backend | ClusterIP | `kubectl port-forward svc/backend 5000:5000 -n mern-app` |
| MongoDB | ClusterIP | Internal only: `mongodb:27017` |

---

## 📊 Check Everything

```bash
# Complete status
kubectl get all -n mern-app

# All namespaces
kubectl get all --all-namespaces

# Storage
kubectl get pvc -n mern-app

# Network policies
kubectl get networkpolicies -n mern-app

# RBAC
kubectl get rolebindings -n mern-app
```

---

## 🆘 Common Issues

| Issue | Solution |
|-------|----------|
| Pod stuck in Pending | `kubectl describe pod <name> -n mern-app` |
| CrashLoopBackOff | `kubectl logs <pod> -n mern-app --previous` |
| ImagePullBackOff | Check ECR access and image name |
| MongoDB not ready | `kubectl logs statefulset/mongodb -n mern-app` |
| LoadBalancer pending | Wait 2-3 minutes for AWS to assign IP |

---

## Cost Optimization

```bash
# Check node utilization
kubectl top nodes

# Check pod resource requests
kubectl describe nodes

# Scale down manually
kubectl scale deployment backend --replicas=1 -n mern-app

# Use spot instances (update nodegroup)
eksctl create nodegroup --cluster=mern-cluster --spot ...
```

---

## Environment Variables

```bash
# Set region
export AWS_REGION=us-east-1

# Set account ID
export AWS_ACCOUNT_ID=123456789012

# Set cluster name
export CLUSTER_NAME=mern-cluster
```

---

**Save this for quick reference!** 📌
