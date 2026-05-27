# GitHub Actions CI/CD Setup Guide

## 🚀 Overview

This GitHub Actions workflow automatically:
1. ✅ Runs tests on backend & frontend
2. 🐳 Builds Docker images
3. 📤 Pushes to AWS ECR
4. 🚀 Deploys to AWS EKS (main branch only)
5. 📢 Notifies Slack on status

---

## 📋 Prerequisites

- GitHub repository pushed to GitHub
- AWS Account with EKS cluster running
- ECR repositories created
- IAM user with ECR and EKS permissions

---

## 🔑 GitHub Secrets Setup

Add these secrets to your GitHub repository:
`Settings → Secrets and variables → Actions → New repository secret`

### **AWS Credentials**

#### 1. `AWS_ACCESS_KEY_ID`
```bash
# Create IAM user for CI/CD
aws iam create-user --user-name github-actions

# Attach policies for ECR and EKS
aws iam attach-user-policy \
  --user-name github-actions \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

aws iam attach-user-policy \
  --user-name github-actions \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

# Create access key
aws iam create-access-key --user-name github-actions

# Copy AccessKeyId → Add as AWS_ACCESS_KEY_ID secret
```

#### 2. `AWS_SECRET_ACCESS_KEY`
```bash
# From the create-access-key output above
# Copy SecretAccessKey → Add as AWS_SECRET_ACCESS_KEY secret
```

### **Optional: Slack Notifications**

#### 3. `SLACK_WEBHOOK` (Optional)
```bash
# Go to: https://api.slack.com/apps
# Create New App → From scratch
# Enable Incoming Webhooks
# Add New Webhook to Workspace
# Copy webhook URL → Add as SLACK_WEBHOOK secret
```

---

## 📝 Configuration

### Update these values in `.github/workflows/ci-cd.yml`:

```yaml
env:
  AWS_REGION: us-east-1              # Change to your region
  EKS_CLUSTER_NAME: mern-app         # Change to your cluster name
```

### Verify these paths in `k8s/`:
```
k8s/
├── 01-namespace-secrets.yaml
├── 03-backend.yaml
└── 04-frontend.yaml
```

---

## 🔧 IAM Policy (Minimal Permissions)

Create a custom policy with minimal permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "arn:aws:ecr:*:ACCOUNT_ID:repository/mern-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## ✅ Workflow Triggers

### Automatic triggers:

| Trigger | Action |
|---------|--------|
| **Push to `main`** | Test → Build → Push to ECR → Deploy to EKS |
| **Push to `develop`** | Test → Build → Push to ECR (no deploy) |
| **Push to `staging`** | Test → Build → Push to ECR (no deploy) |
| **Pull Request** | Test only (no build/deploy) |

---

## 🧪 Testing Locally Before Push

### 1. Test Backend
```bash
cd backend
npm install
npm run test --if-present
```

### 2. Test Frontend
```bash
cd frontend
npm install
npm run build
```

### 3. Build Docker Images
```bash
docker build -t mern-backend:latest backend/
docker build -t mern-frontend:latest frontend/
```

---

## 📊 Monitoring Workflow

### View workflow status:
1. Go to repository → **Actions** tab
2. Click on latest workflow run
3. View logs for each job

### Common failures:

| Error | Solution |
|-------|----------|
| `AWS credentials not configured` | Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` secrets |
| `ECR login failed` | Check IAM policy has ECR permissions |
| `EKS cluster not found` | Update `EKS_CLUSTER_NAME` environment variable |
| `kubectl: command not found` | GitHub Actions runner includes kubectl by default |
| `Deployment timeout` | Check pod logs: `kubectl logs -n mern-app <pod-name>` |

---

## 🔍 Debugging Workflow Issues

### 1. Enable Debug Logging
In `.github/workflows/ci-cd.yml`, add:
```yaml
jobs:
  test-backend:
    env:
      ACTIONS_STEP_DEBUG: true
```

### 2. Check AWS Credentials
```bash
aws sts get-caller-identity  # Run in workflow logs
```

### 3. Verify EKS Cluster Access
```bash
kubectl cluster-info
kubectl get nodes
```

---

## 📈 Advanced: Matrix Strategy

The workflow uses matrix strategy to build frontend & backend in parallel:
```yaml
strategy:
  matrix:
    image: [backend, frontend]
```

This runs 2 jobs simultaneously, reducing total CI/CD time.

---

## 🎯 Next Steps

1. **Push to GitHub**
   ```bash
   git add .github/workflows/ci-cd.yml
   git commit -m "feat: Add GitHub Actions CI/CD for EKS"
   git push origin main
   ```

2. **Monitor First Run**
   - Go to `Actions` tab
   - Watch workflow execution
   - Fix any errors

3. **Verify Deployment**
   ```bash
   kubectl get deployment -n mern-app
   kubectl get service frontend -n mern-app
   ```

---

## 💡 Tips

- **Cache Docker layers**: Workflow caches Docker builds for faster builds
- **Parallel testing**: Backend & frontend tests run simultaneously
- **Rolling updates**: Zero-downtime deployments (maxUnavailable: 0)
- **Auto-rollback**: Failed deployments don't remove old pods immediately
- **Secrets management**: Never commit secrets - always use GitHub Secrets

---

## 🚨 Security Best Practices

✅ **DO:**
- Use separate IAM user for CI/CD
- Rotate access keys quarterly
- Limit IAM permissions (least privilege)
- Use branch protection rules for `main`
- Require PR reviews before merge

❌ **DON'T:**
- Commit AWS credentials
- Use root AWS account
- Share access keys across projects
- Disable branch protection
- Push to main without testing

---

## 📞 Troubleshooting

### Q: Workflow passes tests but fails to deploy?
**A:** Check EKS cluster status and security groups
```bash
aws eks describe-cluster --name mern-app --query 'cluster.status'
kubectl get nodes
```

### Q: Images build but don't push to ECR?
**A:** Verify IAM user has ECR permissions
```bash
aws ecr describe-repositories --region us-east-1
```

### Q: Pods won't start after deployment?
**A:** Check pod logs
```bash
kubectl logs -n mern-app deployment/backend
kubectl logs -n mern-app deployment/frontend
kubectl describe pod -n mern-app <pod-name>
```

### Q: Want to test workflow without pushing?
**A:** Use GitHub Actions Act to run locally
```bash
# Install: https://github.com/nektos/act
act -j build-and-push
```

---

## 📚 Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [AWS Actions](https://github.com/aws-actions)
- [Docker Build Action](https://github.com/docker/build-push-action)
- [kubectl on GitHub](https://github.com/azure/setup-kubectl)
