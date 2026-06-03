# CRITICAL FIXES - QUICK GUIDE
**Apply these 6 fixes (Est. 2 hours) to make deployment production-ready**

---

## FIX 1: Terraform Database Engine
**File:** `terraform/terraform.tfvars` (or copy from example)  
**Time:** 2 min

```hcl
# Change FROM (BROKEN):
db_engine = "mongodb"

# Change TO (WORKING):
db_engine = "mysql"          # OR "postgres"
```

**Why:** AWS RDS doesn't support MongoDB directly. Must use MySQL/PostgreSQL or DocumentDB.

---

## FIX 2: Create tasks-service Kubernetes Service
**File:** `k8s/tasks-service/service.yaml` (CREATE NEW FILE)  
**Time:** 5 min

```yaml
apiVersion: v1
kind: Service
metadata:
  name: tasks-service
  namespace: mern-app
  labels:
    app: tasks-service
spec:
  type: ClusterIP
  selector:
    app: tasks-service
  ports:
    - port: 5002
      targetPort: 5002
      protocol: TCP
```

**Why:** Deployment references this service but file doesn't exist. Kubernetes won't find pods.

---

## FIX 3: Create Frontend Kubernetes Service
**File:** `k8s/frontend/service.yaml` (CREATE NEW FILE)  
**Time:** 5 min

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: mern-app
  labels:
    app: frontend
spec:
  type: LoadBalancer
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
```

**Why:** Frontend needs LoadBalancer to get public IP. Without it, app is unreachable.

---

## FIX 4: Fix Secret Name in Auth & Tasks Deployments
**Files:** 
- `k8s/auth-service/deployment.yaml` (line ~24)
- `k8s/tasks-service/deployment.yaml` (line ~24)

**Time:** 5 min each

**Search for:**
```yaml
envFrom:
  - secretRef:
      name: app-secrets     # ❌ WRONG - plural
```

**Replace with:**
```yaml
envFrom:
  - secretRef:
      name: app-secret      # ✅ CORRECT - singular
```

**Why:** Secret file defines `app-secret` (singular) but deployments reference `app-secrets` (plural). Pods won't start.

---

## FIX 5: Add Health Checks to API Gateway & Frontend
**Files:**
- `k8s/api-gateway/deployment.yaml` (in containers section)
- `k8s/frontend/deployment.yaml` (in containers section)

**Time:** 10 min

**Add to all containers:**

```yaml
          livenessProbe:
            httpGet:
              path: /api/health          # or "/" for frontend
              port: 4000                  # or 80 for frontend
            initialDelaySeconds: 30
            periodSeconds: 10
            failureThreshold: 3

          readinessProbe:
            httpGet:
              path: /api/health          # or "/" for frontend
              port: 4000                  # or 80 for frontend
            initialDelaySeconds: 10
            periodSeconds: 5
            failureThreshold: 3

          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "500m"
```

**Why:** Kubernetes needs to know if pods are healthy. Without probes, dead pods won't restart.

---

## FIX 6: Fix GitHub Actions CI/CD Workflow
**File:** `.github/workflows/ci-cd.yml`

**Time:** 10 min

### Change 1: Fix Trivy variable (Line ~186)
```yaml
# BEFORE:
output: 'trivy-results-${{ matrix.image }}.sarif'

# AFTER:
output: 'trivy-results-${{ matrix.service.name }}.sarif'
```

### Change 2: Fix Trivy upload (Line ~193)
```yaml
# BEFORE:
sarif_file: 'trivy-results-${{ matrix.image }}.sarif'

# AFTER:
sarif_file: 'trivy-results-${{ matrix.service.name }}.sarif'
```

### Change 3: Fix Trivy category (Line ~195)
```yaml
# BEFORE:
category: 'trivy-${{ matrix.image }}'

# AFTER:
category: 'trivy-${{ matrix.service.name }}'
```

### Change 4: Fix K8s manifest deployment (Lines ~214-219)
```yaml
# BEFORE (using non-existent files):
sed -i "s|AUTH_IMAGE|$ECR_REGISTRY/mern-auth:$IMAGE_TAG|g" k8s/03-backend.yaml
sed -i "s|TASKS_IMAGE|$ECR_REGISTRY/mern-tasks:$IMAGE_TAG|g" k8s/03-backend.yaml
sed -i "s|GATEWAY_IMAGE|$ECR_REGISTRY/mern-gateway:$IMAGE_TAG|g" k8s/03-backend.yaml
sed -i "s|FRONTEND_IMAGE|$ECR_REGISTRY/mern-frontend:$IMAGE_TAG|g" k8s/04-frontend.yaml

# AFTER (using actual files):
sed -i "s|your-docker-registry/mern-auth:latest|$ECR_REGISTRY/mern-auth:$IMAGE_TAG|g" k8s/auth-service/deployment.yaml
sed -i "s|your-docker-registry/mern-tasks:latest|$ECR_REGISTRY/mern-tasks:$IMAGE_TAG|g" k8s/tasks-service/deployment.yaml
sed -i "s|your-docker-registry/mern-gateway:latest|$ECR_REGISTRY/mern-gateway:$IMAGE_TAG|g" k8s/api-gateway/deployment.yaml
sed -i "s|your-docker-registry/mern-frontend:latest|$ECR_REGISTRY/mern-frontend:$IMAGE_TAG|g" k8s/frontend/deployment.yaml
```

**Why:** Workflow references `matrix.image` which doesn't exist (should be `matrix.service.name`). Also references k8s files that don't exist.

---

## BONUS: Remove Hardcoded Secrets (IMPORTANT!)

**File:** `k8s/01-namespace-secrets.yaml`

This file currently has hardcoded secrets. For production:

**Option A: Clean the file (RECOMMENDED)**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: mern-app

---
# Secrets will be created via kubectl command, not from file
# See deployment guide for: kubectl create secret...
```

**Option B: Keep template but don't commit to production**
```bash
# Never commit this file to production:
echo "k8s/01-namespace-secrets.yaml" >> .gitignore

# Create secrets manually in production:
kubectl create secret generic mongodb-secret \
  --from-literal=MONGO_ROOT_USER=admin \
  --from-literal=MONGO_ROOT_PASSWORD=$(openssl rand -base64 32) \
  --from-literal=MONGO_DB=merndb \
  -n mern-app
```

**Why:** Secrets in Git are a CRITICAL security vulnerability. Everyone with repo access has passwords.

---

## VERIFICATION CHECKLIST

```bash
# After applying all 6 fixes, run:

# 1. Validate Terraform
cd terraform
terraform validate          # Should show: Success!

# 2. Check k8s files exist
ls -la ../k8s/tasks-service/service.yaml       # Should exist
ls -la ../k8s/frontend/service.yaml            # Should exist

# 3. Check k8s syntax
kubectl apply -f ../k8s/ --dry-run=client      # Should show no errors

# 4. Verify secrets are not hardcoded
grep -r "SecureMongoPassword123" ../k8s/       # Should return NOTHING

# 5. Test GitHub workflow
git diff .github/workflows/ci-cd.yml           # Should show fixes
```

---

## APPLY FIXES IN ORDER

```bash
git checkout -b fix/production-deployment

# Fix 1: Terraform
nano terraform/terraform.tfvars

# Fix 2: Create tasks-service service
cat > k8s/tasks-service/service.yaml << 'EOF'
[content from FIX 3 above]
EOF

# Fix 3: Create frontend service
cat > k8s/frontend/service.yaml << 'EOF'
[content from FIX 4 above]
EOF

# Fix 4: Fix secrets in deployments
nano k8s/auth-service/deployment.yaml        # Replace app-secrets → app-secret
nano k8s/tasks-service/deployment.yaml       # Replace app-secrets → app-secret

# Fix 5: Add health checks
nano k8s/api-gateway/deployment.yaml         # Add probes & resources
nano k8s/frontend/deployment.yaml            # Add probes & resources

# Fix 6: Fix CI/CD workflow
nano .github/workflows/ci-cd.yml             # Fix 4 changes above

# Cleanup secrets
nano k8s/01-namespace-secrets.yaml           # Remove hardcoded values

# Commit
git add -A
git commit -m "fix: Production deployment ready - fix 6 critical blockers"
git push origin fix/production-deployment
```

---

## TIME ESTIMATE

| Fix | Time |
|-----|------|
| Fix 1: Terraform | 2 min |
| Fix 2: tasks-service service | 5 min |
| Fix 3: frontend service | 5 min |
| Fix 4: Secret names | 10 min |
| Fix 5: Health checks | 10 min |
| Fix 6: CI/CD workflow | 10 min |
| Bonus: Remove hardcoded secrets | 5 min |
| **TOTAL** | **~1 hour** |

**After fixes applied, full deployment to production: 4-5 hours**

---

**Status After Fixes: ✅ PRODUCTION-READY (with caveats - see audit report)**
