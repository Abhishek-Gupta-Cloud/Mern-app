# Deployment Guide

## Local development and local production (Docker Compose)

### Prerequisites
- Docker Desktop running
- `docker compose` available
- `cd c:\Users\shiva\Downloads\tranferintohdd\mern-app\mern-app`

### Start services locally
```bash
cd c:\Users\shiva\Downloads\tranferintohdd\mern-app\mern-app
docker compose up --build -d
```

### Verify
```bash
docker compose ps
docker compose logs -f auth
docker compose logs -f tasks
docker compose logs -f gateway
docker compose logs -f frontend
```

### Local application URLs
- Frontend: http://localhost
- Gateway health: http://localhost:4000/api/health
- Auth service health: via gateway at http://localhost:4000/api/health

## Production deployment (AWS EKS + Kubernetes)

### Step 1: provision EKS infrastructure
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars for your AWS account and domain
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

> Note: When `db_engine = "mongodb"`, Terraform will now skip RDS provisioning and rely on the in-cluster MongoDB StatefulSet.

### Step 2: build and push images to ECR
```bash
export AWS_REGION=us-east-1
export ECR_REGISTRY=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.${AWS_REGION}.amazonaws.com
IMAGE_TAG=$(git rev-parse --short HEAD)

aws ecr create-repository --repository-name mern-auth || true
aws ecr create-repository --repository-name mern-tasks || true
aws ecr create-repository --repository-name mern-gateway || true
aws ecr create-repository --repository-name mern-frontend || true

docker build -t ${ECR_REGISTRY}/mern-auth:${IMAGE_TAG} services/auth-service
docker build -t ${ECR_REGISTRY}/mern-tasks:${IMAGE_TAG} services/tasks-service
docker build -t ${ECR_REGISTRY}/mern-gateway:${IMAGE_TAG} services/api-gateway
docker build -t ${ECR_REGISTRY}/mern-frontend:${IMAGE_TAG} frontend

docker push ${ECR_REGISTRY}/mern-auth:${IMAGE_TAG}
docker push ${ECR_REGISTRY}/mern-tasks:${IMAGE_TAG}
docker push ${ECR_REGISTRY}/mern-gateway:${IMAGE_TAG}
docker push ${ECR_REGISTRY}/mern-frontend:${IMAGE_TAG}
```

### Step 3: deploy Kubernetes manifests
```bash
aws eks update-kubeconfig --name mern-app --region us-east-1
kubectl apply -f k8s/01-namespace-secrets.yaml
kubectl apply -f k8s/02-mongodb.yaml
kubectl apply -f k8s/auth-service/service.yaml -f k8s/auth-service/deployment.yaml
kubectl apply -f k8s/tasks-service/service.yaml -f k8s/tasks-service/deployment.yaml
kubectl apply -f k8s/api-gateway/service.yaml -f k8s/api-gateway/deployment.yaml
kubectl apply -f k8s/frontend/service.yaml -f k8s/frontend/deployment.yaml
kubectl apply -f k8s/ingress.yaml
kubectl rollout status deployment/auth-service -n mern-app --timeout=5m
kubectl rollout status deployment/tasks-service -n mern-app --timeout=5m
kubectl rollout status deployment/api-gateway -n mern-app --timeout=5m
kubectl rollout status deployment/frontend -n mern-app --timeout=5m
```

### Production environment reminders
- Update `k8s/ingress.yaml` host to your real domain.
- Keep `JWT_SECRET` secret and rotate regularly.
- In production, use a secure secret store for Kubernetes values.
