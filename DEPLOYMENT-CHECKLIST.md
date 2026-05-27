# 📋 Complete Deployment Checklist

## ✅ Pre-Deployment Phase

### **AWS Account Setup**
- [ ] AWS account created with payment method
- [ ] AWS CLI installed: `aws --version`
- [ ] AWS credentials configured: `aws sts get-caller-identity`
- [ ] Region set correctly: `aws configure get region` (should be us-east-1)
- [ ] IAM user has AdministratorAccess or equivalent policies
- [ ] Service quota check: EKS, EC2, RDS accessible

### **Local Tools**
- [ ] Terraform v1.5+ installed: `terraform --version`
- [ ] kubectl installed: `kubectl version --client`
- [ ] Docker installed: `docker --version`
- [ ] Git installed: `git --version`
- [ ] jq installed (optional): `jq --version`

### **Repository Setup**
- [ ] Git repository cloned or initialized
- [ ] All code committed: `git status` (clean working directory)
- [ ] Remote configured (if using GitHub)
- [ ] Branch is main or master

---

## ✅ Pre-Deployment - Application Code

### **Docker Configuration**
- [ ] Backend Dockerfile builds: `cd backend && docker build -t mern-backend:test .`
- [ ] Frontend Dockerfile builds: `cd frontend && docker build -t mern-frontend:test .`
- [ ] Docker images run locally without errors
- [ ] .dockerignore files properly configured
- [ ] Multi-stage builds optimized

### **Kubernetes Manifests**
- [ ] All YAML files valid: `kubectl apply -f k8s/ --dry-run=client`
- [ ] Secrets properly referenced
- [ ] ConfigMaps properly set
- [ ] Service types correct (backend: ClusterIP, frontend: LoadBalancer)
- [ ] Resource requests/limits set appropriately

### **Application Code**
- [ ] Environment variables documented in .env.example
- [ ] Backend has /api/health endpoint
- [ ] Frontend builds without errors: `npm run build`
- [ ] No hardcoded hostnames or ports (use env vars)
- [ ] Database connection string can be configured via env

### **Environment Files**
- [ ] .env.example created and documented
- [ ] No credentials in git repo: `git grep "AWS_SECRET"` (should be empty)
- [ ] .gitignore includes .env, node_modules, dist
- [ ] Environment variables documented

---

## ✅ Pre-Deployment - Configuration

### **Terraform Configuration**
- [ ] terraform/terraform.tfvars created (copied from example)
- [ ] Domain name entered: `domain_name = "yourdomain.com"`
- [ ] Alarm email entered: `alarm_email = "your@email.com"`
- [ ] Region choice confirmed: `primary_region = "us-east-1"`
- [ ] Cost level confirmed:
  - [ ] Minimal ($150): secondary_region = ""
  - [ ] Balanced ($300): 3 t3.small nodes
  - [ ] Enterprise ($700): secondary_region = "us-west-2"
- [ ] Terraform syntax valid: `terraform validate`

### **GitHub Actions Setup**
- [ ] Repository is public or Actions are enabled
- [ ] GitHub Secrets configured:
  - [ ] AWS_ACCESS_KEY_ID
  - [ ] AWS_SECRET_ACCESS_KEY
  - [ ] ECR_REGISTRY
  - [ ] SONAR_HOST_URL (optional)
  - [ ] SONAR_TOKEN (optional)
  - [ ] SLACK_WEBHOOK (optional)
- [ ] CI/CD workflow file in place: `.github/workflows/ci-cd.yml`
- [ ] Workflow file syntax valid

### **AWS Resources**
- [ ] ECR repositories created for backend and frontend:
  ```bash
  aws ecr create-repository --repository-name mern-backend
  aws ecr create-repository --repository-name mern-frontend
  ```
- [ ] Repository URLs noted down
- [ ] IAM user has ECR push permissions
- [ ] AWS Secrets Manager policies configured

---

## ✅ Deployment Phase - Terraform

### **Initialize Terraform**
```bash
cd terraform
terraform init
```
- [ ] Initialization successful
- [ ] State file created (terraform.tfstate)
- [ ] Plugins downloaded

### **Plan Deployment**
```bash
terraform plan -out=tfplan
```
- [ ] Plan shows resource count (50-60 resources)
- [ ] No errors in plan output
- [ ] Resource names match expectations
- [ ] Cost estimate reviewed (~$150 for minimal)
- [ ] Plan file saved (`tfplan`)

### **Review Plan Output**
- [ ] VPC and subnets will be created
- [ ] EKS cluster will be created
- [ ] RDS instance will be created
- [ ] ALB will be created
- [ ] IAM roles will be created
- [ ] Security groups will be created
- [ ] CloudWatch dashboard will be created

### **Apply Terraform**
```bash
terraform apply tfplan
```
- [ ] Apply started without errors
- [ ] Resources being created (watch AWS console)
- [ ] **WAIT 15-20 MINUTES** for EKS cluster creation
- [ ] No errors during apply
- [ ] Apply completed successfully

### **Verify Terraform Outputs**
```bash
terraform output
```
- [ ] Primary cluster name output: `eks_cluster_name`
- [ ] Primary cluster endpoint output: `eks_cluster_endpoint`
- [ ] ALB DNS output: `alb_dns_name`
- [ ] RDS endpoint output: `primary_db_endpoint`
- [ ] kubeconfig configuration command shown

---

## ✅ Post-Terraform - Kubernetes Setup

### **Configure kubectl**
```bash
# Use command from terraform output:
aws eks update-kubeconfig --region us-east-1 --name mern-app-primary

# Verify connection:
kubectl cluster-info
```
- [ ] kubectl can connect to cluster
- [ ] API server responds
- [ ] Cluster info displayed correctly

### **Verify EKS Cluster**
```bash
kubectl get nodes
kubectl get namespaces
```
- [ ] Nodes are Ready (show as "Ready" status)
- [ ] At least 2 nodes present
- [ ] System namespaces exist (kube-system, kube-public, etc.)

### **Create Application Namespace**
```bash
kubectl create namespace mern-app
# Or: kubectl apply -f k8s/01-namespace-secrets.yaml
```
- [ ] Namespace created: `kubectl get namespace mern-app`
- [ ] Secrets configured with actual database credentials
- [ ] ConfigMap created with application config

### **Deploy Secrets and ConfigMaps**
```bash
kubectl apply -f k8s/01-namespace-secrets.yaml
```
- [ ] Namespace created
- [ ] Secrets created: `kubectl get secrets -n mern-app`
- [ ] ConfigMap created: `kubectl get configmap -n mern-app`
- [ ] Values correct: `kubectl describe secret -n mern-app`

---

## ✅ Post-Terraform - Application Deployment

### **Deploy Backend**
```bash
kubectl apply -f k8s/03-backend.yaml
```
- [ ] Deployment created: `kubectl get deployment -n mern-app`
- [ ] Pods starting: `kubectl get pods -n mern-app`
- [ ] Service created: `kubectl get svc -n mern-app`
- [ ] Wait for Ready: `kubectl get pods -n mern-app --watch`

### **Verify Backend**
```bash
# Check pod logs
kubectl logs -n mern-app deployment/backend

# Check pod status
kubectl describe pod -n mern-app -l app=backend
```
- [ ] All pods are Running (not Pending or CrashLoopBackOff)
- [ ] No error logs in pod output
- [ ] Health check passing (no failed readiness/liveness probes)

### **Deploy Frontend**
```bash
kubectl apply -f k8s/04-frontend.yaml
```
- [ ] Deployment created
- [ ] Pods starting
- [ ] Service created: `kubectl get svc -n mern-app`
- [ ] LoadBalancer getting external IP (may take 1-2 min)

### **Verify Frontend**
```bash
kubectl get svc -n mern-app frontend
```
- [ ] EXTERNAL-IP assigned (not pending)
- [ ] Port 80 mapped correctly
- [ ] Can access URL: `curl http://<EXTERNAL-IP>`

---

## ✅ Database Setup

### **RDS Instance Verification**
```bash
# Check RDS instance
aws rds describe-db-instances --db-instance-identifier mern-app-primary

# Get endpoint from terraform output or:
terraform output primary_db_endpoint
```
- [ ] RDS instance is Available (not creating or modifying)
- [ ] Database name: `mern_app`
- [ ] Port: 5432 (or 3306 for MySQL)
- [ ] Encryption enabled
- [ ] Automated backups enabled
- [ ] Backup retention: 7 days

### **Database Connection Test**
```bash
# From a pod or local machine with network access:
mysql -h <RDS-ENDPOINT> -u admin -p

# Or from a pod:
kubectl exec -it <pod-name> -n mern-app -- /bin/sh
```
- [ ] Can connect to database
- [ ] Username and password correct
- [ ] Database `mern_app` exists
- [ ] Can list tables: `SHOW TABLES;`

### **Initialize Database**
- [ ] Run migrations if needed: `npm run migrate` or similar
- [ ] Create initial tables/schema
- [ ] Verify schema created: `DESCRIBE users;`
- [ ] Verify schema created: `DESCRIBE tasks;`

---

## ✅ Application Testing

### **Backend API Testing**
```bash
# Get backend service IP/endpoint
kubectl get svc -n mern-app backend

# Test health endpoint
curl -X GET http://<BACKEND-IP>:5000/api/health

# Test other endpoints
curl -X POST http://<BACKEND-IP>:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password123"}'
```
- [ ] Health endpoint responds with 200
- [ ] Register endpoint works
- [ ] Login endpoint works
- [ ] Task CRUD endpoints work

### **Frontend Testing**
```bash
# Get frontend external IP
kubectl get svc -n mern-app frontend

# Open in browser or curl
curl http://<EXTERNAL-IP>
```
- [ ] Frontend page loads
- [ ] No 404 errors
- [ ] CSS/JS files load correctly
- [ ] Can see login page
- [ ] Can see register page

### **End-to-End Testing**
- [ ] Create account via frontend
- [ ] Login with created account
- [ ] Create tasks via API
- [ ] See tasks in frontend
- [ ] Edit tasks
- [ ] Delete tasks
- [ ] Logout
- [ ] Login with same credentials again

---

## ✅ Monitoring and Logging

### **CloudWatch Setup**
```bash
# Check if CloudWatch dashboard created
aws cloudwatch list-dashboards
```
- [ ] Dashboard created: `mern-app-dashboard`
- [ ] Can view in AWS Console
- [ ] Shows CPU metrics
- [ ] Shows connection metrics
- [ ] Shows pod count metrics

### **CloudWatch Logs**
```bash
# Check log groups
aws logs describe-log-groups

# View logs
aws logs tail /aws/eks/mern-app-primary --follow
```
- [ ] Log groups created
- [ ] Logs being collected
- [ ] Backend logs visible
- [ ] Frontend logs visible

### **Pod Logs**
```bash
kubectl logs -n mern-app deployment/backend -f
kubectl logs -n mern-app deployment/frontend -f
```
- [ ] No critical errors
- [ ] Application started successfully
- [ ] Health checks passing

---

## ✅ Networking and Access

### **ALB Configuration**
```bash
# Get ALB details
aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerName,DNSName]'
```
- [ ] ALB created
- [ ] DNS name assigned
- [ ] Health checks passing
- [ ] Targets registered

### **Security Groups**
```bash
aws ec2 describe-security-groups --filters Name=tag:app,Values=mern-app
```
- [ ] Security groups created for EKS
- [ ] Security groups created for RDS
- [ ] Ingress rules allowing HTTP/HTTPS
- [ ] Egress rules allowing database connections

### **DNS (if using Route53)**
```bash
# Create CNAME record pointing to ALB
# Or use A record with alias to ALB
```
- [ ] Domain resolves to ALB
- [ ] Can access via custom domain
- [ ] SSL/TLS working (if configured)

---

## ✅ GitHub Actions CI/CD

### **First Deployment**
- [ ] Push code to main branch
- [ ] GitHub Actions workflow starts automatically
- [ ] Workflow runs all jobs:
  - [ ] test-backend passes
  - [ ] test-frontend passes
  - [ ] sonarqube-scan completes
  - [ ] build-and-push succeeds
  - [ ] deploy-to-eks completes

### **Verify CI/CD**
```bash
# Check GitHub Actions tab for workflow runs
# Should show recent pushes with checkmarks (✓)
```
- [ ] Recent workflow runs shown
- [ ] All jobs passed (green checkmarks)
- [ ] Docker images pushed to ECR
- [ ] New pods deployed to EKS

### **Verify ECR Images**
```bash
aws ecr describe-repositories
aws ecr describe-images --repository-name mern-backend
aws ecr describe-images --repository-name mern-frontend
```
- [ ] Images pushed to ECR
- [ ] Image tags show git commit SHAs
- [ ] Latest tag points to most recent build

---

## ✅ Cost Verification

### **AWS Billing Check**
```bash
# Check estimated charges
aws ce get-cost-and-usage \
  --time-period Start=2024-05-01,End=2024-05-02 \
  --granularity DAILY \
  --metrics "EstimatedCharges" \
  --group-by Type=DIMENSION,Key=SERVICE
```
- [ ] Actual costs align with estimate (~$150 for minimal)
- [ ] No unexpected charges
- [ ] Major cost items: EKS, EC2, RDS, ALB

### **AWS Budget Alert**
- [ ] Budget created in AWS Billing console
- [ ] Alert threshold set ($200 for minimal setup)
- [ ] Email notifications configured
- [ ] Can be notified of overspending

### **Infracost Check** (Optional)
```bash
infracost breakdown --path terraform
```
- [ ] Estimated costs shown
- [ ] Matches expected range
- [ ] Breakdown by service shown

---

## ✅ Backup and Recovery

### **RDS Backups**
```bash
aws rds describe-db-snapshots --db-instance-identifier mern-app-primary
```
- [ ] Automated backups enabled
- [ ] At least one snapshot exists
- [ ] Backup retention period: 7 days
- [ ] Point-in-time recovery enabled

### **EBS Snapshots**
```bash
aws ec2 describe-snapshots --owner-ids self
```
- [ ] Node volume snapshots created (automatic)
- [ ] Can restore from snapshot if needed

### **Database Backup Test**
```bash
# Try restoring from a snapshot to verify backups work
# (Optional - do this in test environment)
```
- [ ] Can create restore point
- [ ] Restore test succeeds
- [ ] Backup strategy verified

---

## ✅ Documentation

### **Deployment Documentation**
- [ ] TERRAFORM-GUIDE.md reviewed and saved
- [ ] GITHUB-ACTIONS-SETUP.md completed
- [ ] TRIVY-SONARQUBE-SETUP.md completed
- [ ] COST-OPTIMIZATION.md reviewed
- [ ] MINIMAL-DEPLOYMENT.md reviewed
- [ ] API documentation created
- [ ] Deployment procedure documented

### **Runbooks Created**
- [ ] How to scale up infrastructure
- [ ] How to update application code
- [ ] How to debug issues
- [ ] How to access logs
- [ ] How to restore from backup
- [ ] Emergency procedures

### **Credentials Documented** (Secure Location)
- [ ] Database admin credentials stored
- [ ] AWS account IDs noted
- [ ] SSH keys stored (if using EC2 directly)
- [ ] API keys stored securely
- [ ] NOT committed to git

---

## ✅ Final Verification

### **Application Health**
```bash
kubectl get all -n mern-app
```
- [ ] All pods Running
- [ ] All services have endpoints
- [ ] All deployments have desired replicas
- [ ] No failed pods

### **Full End-to-End Test**
1. [ ] Access frontend via LoadBalancer URL
2. [ ] Register new user
3. [ ] Login with user
4. [ ] Create task
5. [ ] Update task
6. [ ] Delete task
7. [ ] Logout
8. [ ] Login again with same user
9. [ ] All data persisted correctly

### **Monitoring Verification**
- [ ] Can see CloudWatch dashboard
- [ ] Can view pod metrics
- [ ] Can view database metrics
- [ ] Alarms configured and working

### **Cost Within Budget**
- [ ] Daily cost tracked
- [ ] Total monthly estimate < budgeted amount
- [ ] No unexpected charges
- [ ] Cost breakdown understood

---

## 🚀 Deployment Complete!

When all checkboxes are complete:

```bash
✅ Infrastructure deployed (Terraform)
✅ Kubernetes cluster ready (EKS)
✅ Application running (MERN stack)
✅ Database connected (RDS)
✅ CI/CD working (GitHub Actions)
✅ Monitoring active (CloudWatch)
✅ Backups configured (RDS snapshots)
✅ Costs within budget ($150/month)
```

---

## 📊 Post-Deployment Maintenance Schedule

### **Daily**
- [ ] Check application availability
- [ ] Monitor error rates in logs
- [ ] Verify CloudWatch alarms

### **Weekly**
- [ ] Review CloudWatch dashboard
- [ ] Check cost trends
- [ ] Verify backups completed

### **Monthly**
- [ ] Review and test backup restore procedure
- [ ] Analyze performance metrics
- [ ] Update documentation
- [ ] Plan for capacity needs

### **Quarterly**
- [ ] Security audit
- [ ] Disaster recovery drill
- [ ] Cost optimization review
- [ ] Update Terraform to latest versions

---

## 🆘 Emergency Procedures

### **If Application is Down**
1. Check pod status: `kubectl get pods -n mern-app`
2. Check pod logs: `kubectl logs -n mern-app <pod-name>`
3. Check deployment status: `kubectl describe deployment -n mern-app`
4. Check service endpoints: `kubectl get endpoints -n mern-app`
5. Check LoadBalancer: `kubectl describe svc -n mern-app frontend`

### **If Database is Down**
1. Check RDS status: `aws rds describe-db-instances`
2. Check security groups allow access
3. Check RDS logs in CloudWatch
4. Consider restoring from backup

### **If EKS Cluster is Down**
1. Check cluster status: `aws eks describe-cluster --name mern-app-primary`
2. Check node status: `kubectl get nodes`
3. Check cluster logs in CloudWatch
4. Contact AWS support if needed

---

**Congratulations! Your MERN application is now running in production on AWS EKS!** 🎉

For questions or issues, refer to the comprehensive guides:
- TERRAFORM-GUIDE.md
- GITHUB-ACTIONS-SETUP.md
- COST-OPTIMIZATION.md
- MINIMAL-DEPLOYMENT.md
