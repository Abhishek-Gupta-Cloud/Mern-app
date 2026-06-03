# Project Analysis

## Repository structure
- `services/auth-service`: Auth microservice
- `services/tasks-service`: Tasks microservice
- `services/api-gateway`: API gateway proxying frontend requests to auth/tasks
- `frontend`: React + Vite + Nginx frontend
- `backend`: legacy monolithic backend not used by current Docker Compose or Kubernetes deployment
- `docker-compose.yml`: local/prod container orchestration
- `k8s/`: Kubernetes manifests for namespace, MongoDB, services, deployments, ingress
- `terraform/`: AWS EKS infrastructure module definitions plus optional DB provisioning modules
- `.github/workflows/ci-cd.yml`: CI/CD pipeline for tests, image build, push, and deploy

## Actual runtime architecture
- Microservices-based deployment is the real production path.
- The frontend is a single-page app built by Vite and served by Nginx.
- The API gateway receives browser requests on `/api` and forwards them to:
  - `auth-service` for authentication
  - `tasks-service` for task data
- Both backend services connect to MongoDB.
- Production deployment target is AWS EKS with container images in Amazon ECR.

## Dependency map
- `frontend` → `api-gateway`
- `api-gateway` → `auth-service`
- `api-gateway` → `tasks-service`
- `auth-service` → `mongodb`
- `tasks-service` → `mongodb`
- `docker-compose.yml` also runs `mongo`

## Non-functional and legacy paths
- `backend/` is a legacy monolithic API that is not used by the live container or Kubernetes deployment path.
- `services/common/` exists but is not referenced by any runtime service.

## Major issues discovered
- Docker Compose referenced a missing `mongo-init.js` file.
- Frontend Nginx proxy targeted `host.docker.internal:5000` instead of `api-gateway`.
- Node runtime images lacked `curl`, so healthchecks could not execute.
- Kubernetes service manifests were missing `namespace: mern-app` and would deploy into `default`.
- Kubernetes auth/tasks deployments referenced the wrong secret name and lacked Mongo/JWT env injection.
- GitHub Actions workflow used undefined `matrix.image` and referenced missing K8s files.
- Terraform attempted to provision MongoDB with an invalid `aws_db_instance`/DocumentDB configuration.
- `tasks-service` stats aggregation used `req.user._id` instead of `req.user.id`.

## Fixes applied
- Docker Compose and Dockerfiles patched for runtime healthchecks.
- Local `.env` files created for `auth-service`, `tasks-service`, `api-gateway`, `frontend`, and legacy `backend`.
- Nginx config updated to proxy to `api-gateway:4000`.
- Kubernetes manifests fixed with correct namespaces and secret/env injection.
- CI workflow corrected to use actual service manifest files and matrix variables.
- Terraform provisioning made safe for MongoDB mode by disabling RDS when `db_engine = "mongodb"`.

## Validation status
- `frontend` build succeeded with `npm run build`.
- Service dependency installations succeeded in `auth-service`, `tasks-service`, `api-gateway`, `frontend`, and `backend`.
- Docker Compose config validated successfully.
- Docker daemon was unavailable in this execution environment, so container builds could not be completed here.

## Recommendation
- Local runnable path: `docker compose up --build -d`
- Production path: AWS EKS with current K8s manifests and Terraform infrastructure for EKS only, using in-cluster MongoDB.
