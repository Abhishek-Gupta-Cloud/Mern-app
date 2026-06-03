# MERN App — Production Deployment Guide

This repository contains a MERN task-management application with two deployment patterns:
- Microservices (recommended): `services/` + `api-gateway` + `frontend`
- Monolithic (reference): `backend/` + `frontend/`

This README consolidates the production deployment steps and checklist.

## Production Deployment Options

1) Docker Compose (single server / VPS)
   - Copy env examples and set production values:
     - `services/auth-service/.env.example` → `.env`
     - `services/tasks-service/.env.example` → `.env`
     - `services/api-gateway/.env.example` → `.env`
     - `frontend/.env.example` → `.env.local`
   - Build and start:
     ```bash
     docker compose up --build -d
     ```
   - Verify health endpoints: `http://localhost:4000/api/health`

2) Kubernetes (AWS EKS) + Terraform (recommended for cloud production)
   - Prepare Terraform variables: copy `terraform/terraform.tfvars.example` → `terraform/terraform.tfvars` and edit values (region, instance types, domain, db settings).
   - Initialize and apply:
     ```bash
     cd terraform
     terraform init
     terraform plan -out=tfplan
     terraform apply tfplan
     ```
   - Build and push images to ECR, then deploy k8s manifests:
     ```bash
     # Build & push (example)
     ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
     REGION=us-east-1
     # create repos, build, tag, push images for services and frontend

     # Deploy manifests (after updating image URLs)
     kubectl apply -f k8s/01-namespace-secrets.yaml
     kubectl apply -f k8s/02-mongodb.yaml
     kubectl apply -f k8s/03-backend.yaml
     kubectl apply -f k8s/04-frontend.yaml
     ```

## Quick CI/CD (GitHub Actions)
- Required repository secrets:
  - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
  - `ECR_REGISTRY` (optional), `SONAR_HOST_URL`, `SONAR_TOKEN` (optional)
  - `SLACK_WEBHOOK` (optional)
- Workflow path: `.github/workflows/ci-cd.yml` — verifies tests, builds images, runs Trivy & SonarQube, pushes to ECR and deploys to EKS.

## Important Warnings & Notes
- Review `terraform/modules/rds/` and `rds_replica/`: the current Terraform module treats `db_engine = "mongodb"` in a non-standard way — verify DB module supports your chosen engine (DocumentDB vs RDS). Do not deploy to production until validated.
- Replace placeholder secrets in `k8s/01-namespace-secrets.yaml` before applying.
- `docker-compose.yml` references `.env.example` in some services — ensure the compose file uses real `.env` files for production.

## GitHub Actions - Quick fixes (issues found)
- In `.github/workflows/ci-cd.yml` the build matrix uses `matrix.service` with keys `name/context/repo`, but some steps reference `matrix.image` — replace occurrences of `matrix.image` with `matrix.service.name` or `matrix.service.repo`.
- Ensure Trivy SARIF filenames use the correct matrix variable and that the upload action receives the correct file path.
- Confirm the workflow tags and pushes images consistently before deployment steps use those tags in k8s manifests.

## Recommended files to keep (already present)
- `DEPLOYMENT-CHECKLIST.md` — production checklist
- `TERRAFORM-GUIDE.md`, `terraform/MINIMAL-DEPLOYMENT.md` — infra guides
- `README-MICROSERVICES.md` — local microservices runbook
- `.github/GITHUB-ACTIONS-SETUP.md`, `.github/TRIVY-SONARQUBE-SETUP.md` — CI docs

## Files you can consolidate or archive
- `EKS-README.md`, `EKS-DEPLOYMENT.md`, `EKS-COMMANDS.md` — these are EKS-specific and largely overlap with `TERRAFORM-GUIDE.md` and `PRODUCTION-DEPLOYMENT.md`. Consider consolidating into the Terraform/EKS guide.

## Next steps I can do for you
- Fix `.github/workflows/ci-cd.yml` issues (matrix variable names, Trivy SARIF paths).
- Create a single consolidated `docs/` folder and move or merge redundant .md files.
- Validate Terraform DB module and propose a patch to support MongoDB/DocumentDB correctly.

---
If you want I can now apply the CI workflow fixes and finish consolidating docs — tell me which next step to take.
