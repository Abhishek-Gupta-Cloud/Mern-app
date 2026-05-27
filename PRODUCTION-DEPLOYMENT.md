# Production Deployment Guide

## 1. Repository audit summary

This repository contains two deployment patterns:
- `backend/` + `frontend/` monolithic MERN application
- `services/` microservices architecture with `auth-service`, `tasks-service`, and `api-gateway`

### Found issues / inconsistencies

- `README.md` refers to `deploy.sh` and `backup.sh`, but those files are not present in the workspace.
- `docker-compose.yml` for microservices uses `env_file: ./services/.../.env.example` instead of a copied `.env` file. If you want custom production values, you must edit the `.env.example` files or update the compose file to load a real `.env`.
- Terraform infra is configured in `terraform/main.tf`, but the database module appears inconsistent with a MongoDB deployment:
  - `terraform/modules/rds/main.tf` maps `db_engine = "mongodb"` to `engine = "docdb"` and uses `aws_db_instance`, which is not a standard MongoDB Atlas or AWS DocumentDB deployment path.
  - `terraform/modules/rds_replica/main.tf` uses read replica settings that may not work for MongoDB/DocumentDB.
- `k8s/01-namespace-secrets.yaml` contains placeholder credentials and hardcoded secrets. Those values must be replaced before any production deployment.

## 2. Recommended production deployment path

### Option A: Docker Compose microservices

Use this when deploying to a single server, VPS, or small production environment.

1. Copy environment templates for each service:
   - `services/auth-service/.env.example`
   - `services/tasks-service/.env.example`
   - `services/api-gateway/.env.example`
   - `frontend/.env.example`

2. Update values for production. See Section 4 for exact variables.

3. Start the stack:

```bash
cd mern-app
docker compose up --build -d
```

4. Verify health checks:

```bash
curl http://localhost:4000/api/health
curl http://localhost:4000/api/auth/health
curl http://localhost:4000/api/tasks/health
```

5. Access the frontend at:

```text
http://localhost
```

### Option B: Kubernetes / EKS with Terraform

Use this for cloud production, high availability, and managed infrastructure.

1. Review and fix Terraform before use. Important files:
   - `terraform/variables.tf`
   - `terraform/main.tf`
   - `terraform/terraform.tfvars.example`
   - `terraform/terraform.tfvars.production.example`
   - `terraform/modules/rds/main.tf`
   - `terraform/modules/rds_replica/main.tf`

2. Create a `terraform.tfvars` file from one of the examples.

3. Initialize Terraform:

```bash
cd terraform
terraform init
```

4. Plan and apply:

```bash
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

5. Deploy Kubernetes manifests or Helm charts for the app after the cluster is created.

## 3. Required variables for production

### Microservices Docker deployment environment variables

#### `services/auth-service/.env.example`
- `PORT` = 5001
- `NODE_ENV` = production
- `MONGO_URI` = MongoDB connection string used by auth service
- `JWT_SECRET` = long random secret
- `JWT_EXPIRES_IN` = `7d` or another expiry
- `CORS_ORIGINS` = comma-separated origins for browser access

#### `services/tasks-service/.env.example`
- `PORT` = 5002
- `NODE_ENV` = production
- `MONGO_URI` = MongoDB connection string used by tasks service
- `JWT_SECRET` = same secret used by auth service
- `CORS_ORIGINS` = comma-separated origins for browser access

#### `services/api-gateway/.env.example`
- `PORT` = 4000
- `AUTH_URL` = `http://auth:5001` (service name in compose)
- `TASKS_URL` = `http://tasks:5002`

#### `frontend/.env.example`
- `VITE_API_URL` = `/api` for proxy to gateway

### Monolithic root backend environment variables

#### `backend/.env.example`
- `PORT` = 5000
- `NODE_ENV` = production
- `MONGO_URI` = MongoDB connection string
- `JWT_SECRET` = long random secret
- `JWT_EXPIRES_IN` = `7d`
- `CORS_ORIGINS` = production origin(s)

### Kubernetes / secrets variables

Replace the placeholders in `k8s/01-namespace-secrets.yaml`:
- `MONGO_ROOT_USER`
- `MONGO_ROOT_PASSWORD`
- `MONGO_DB`
- `JWT_SECRET`
- `JWT_EXPIRES_IN`
- `NODE_ENV` = production
- `PORT` = 5000 or service port
- `CORS_ORIGINS` = production origin list

### Terraform variables

Use `terraform/terraform.tfvars.example` or `terraform/terraform.tfvars.production.example` and set production values for:
- `project_name`
- `environment`
- `primary_region`
- `secondary_region` (optional)
- `primary_vpc_cidr`
- `secondary_vpc_cidr`
- `kubernetes_version`
- `instance_types`
- `primary_node_group_desired`
- `primary_node_group_min`
- `primary_node_group_max`
- `secondary_node_group_desired`
- `secondary_node_group_min`
- `secondary_node_group_max`
- `db_name`
- `db_engine`
- `db_engine_version`
- `db_instance_class`
- `db_allocated_storage`
- `db_multi_az`
- `enable_monitoring`
- `enable_autoscaling`
- `enable_ingress`
- `domain_name`
- `alarm_email`
- `tags` map values

## 4. Physical values to set for production

### MongoDB connection examples

For Docker Compose internal MongoDB:
```text
MONGO_URI=mongodb://admin:<secure-password>@mongo:27017/mernapp?authSource=admin&retryWrites=true&w=majority
```

For external or hosted MongoDB:
```text
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/mernapp?retryWrites=true&w=majority
```

### JWT secret
- Use a strong secret generated with a secure method.
- Example generator:
  - `openssl rand -base64 64`

### CORS origins
- Example:
  - `https://app.yourdomain.com,https://www.yourdomain.com`

### Terraform production values
- `primary_region` = `us-east-1` (or your AWS region)
- `secondary_region` = `us-west-2` (optional for HA)
- `instance_types` = `["t3.medium", "t3.large"]`
- `primary_node_group_desired` = `3`
- `db_engine` = `mongodb` (with caution; module may need correction)
- `domain_name` = `yourdomain.com`
- `alarm_email` = `alerts@yourdomain.com`

## 5. Important notes before production deployment

- Replace placeholder secrets before deploying.
- Confirm the database module supports your selected database engine. The current Terraform configuration is not ready for real MongoDB without review.
- If using Docker Compose, ensure `services/*/.env.example` values are updated or the compose file is changed to load a proper `.env` file.
- For Kubernetes, ensure secrets and config maps use secure values and do not expose plaintext credentials.

## 6. Recommended immediate fixes

1. Add `deploy.sh` and `backup.sh` or remove references from `README.md`.
2. Fix `docker-compose.yml` to use service-specific `.env` files instead of `.env.example` for production.
3. Review and update Terraform database modules for MongoDB/DocumentDB compatibility.
4. Replace placeholder values in `k8s/01-namespace-secrets.yaml` before production use.

---

If you want, I can also create a second guide that focuses only on the `services/` microservices deployment and the exact `.env` files needed for the production Docker Compose stack.