# Multi-Region EKS Deployment with Terraform

## 🏗️ Architecture Overview

This Terraform configuration deploys a production-ready, multi-region EKS infrastructure with:

```
┌─────────────────────────────────────────────────────────────────┐
│                     AWS GLOBAL INFRASTRUCTURE                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  PRIMARY REGION (us-east-1)        SECONDARY REGION (us-west-2) │
│  ┌──────────────────────────┐      ┌──────────────────────────┐ │
│  │  EKS Cluster             │      │  EKS Cluster             │ │
│  │  ┌────────────────────┐  │      │  ┌────────────────────┐  │ │
│  │  │ Frontend Pods (2)  │  │      │  │ Frontend Pods (2)  │  │ │
│  │  │ Backend Pods (3)   │  │      │  │ Backend Pods (2)   │  │ │
│  │  └────────────────────┘  │      │  └────────────────────┘  │ │
│  │  ALB (Public)            │      │  ALB (Public)            │ │
│  └──────────────────────────┘      └──────────────────────────┘ │
│           │                               │                      │
│           └───────────────┬───────────────┘                      │
│                           ▼                                       │
│                   ┌──────────────────┐                           │
│                   │   Route53        │                           │
│                   │   Failover       │                           │
│                   │   DNS            │                           │
│                   └──────────────────┘                           │
│                                                                   │
│  ┌──────────────────────────┐      ┌──────────────────────────┐ │
│  │ RDS Primary (Master)     │      │ RDS Replica (Read-only)  │ │
│  │ Multi-AZ                 │◄────►│ Cross-region             │ │
│  └──────────────────────────┘      └──────────────────────────┘ │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────────┤ │
│  │ CloudWatch Monitoring & Alarms across all regions           │ │
│  └──────────────────────────────────────────────────────────────┤ │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
terraform/
├── main.tf                          # Root module, orchestrates everything
├── variables.tf                     # Input variables
├── outputs.tf                       # Output values
├── terraform.tfvars.example         # Example variable values
├── terraform.lock.hcl               # Dependency lock file (auto-generated)
├── .gitignore                       # Git ignore patterns
│
└── modules/
    ├── eks/                         # EKS cluster module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── rds/                         # RDS primary database
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── rds_replica/                 # RDS read replica
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── route53/                     # Global routing & failover
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── monitoring/                  # CloudWatch & alarms
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## 🚀 Quick Start

### **Step 1: Install Terraform**
```bash
# macOS
brew install terraform

# Linux
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Verify
terraform version
```

### **Step 2: Configure AWS Credentials**
```bash
# Option A: Using AWS CLI
aws configure  # Enter Access Key ID, Secret Access Key, region

# Option B: Using environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Option C: Using AWS credentials file
cat ~/.aws/credentials
```

### **Step 3: Clone and Setup**
```bash
cd terraform

# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Edit configuration
nano terraform.tfvars
```

### **Step 4: Initialize Terraform**
```bash
terraform init
```

This downloads providers and sets up the working directory.

### **Step 5: Validate Configuration**
```bash
terraform validate

# View what will be created
terraform plan > plan.txt
cat plan.txt
```

### **Step 6: Deploy Infrastructure**
```bash
# Review the plan carefully!
terraform apply

# Type 'yes' when prompted
# Deployment takes 15-20 minutes
```

### **Step 7: Verify Deployment**
```bash
# Get outputs
terraform output

# Configure kubectl for primary cluster
aws eks update-kubeconfig --region us-east-1 --name mern-app-primary

# Test cluster connection
kubectl cluster-info
kubectl get nodes
```

---

## 🔧 Configuration Guide

### **terraform.tfvars** - Key Settings

```hcl
# Project
project_name = "mern-app"
environment  = "production"

# Regions
primary_region   = "us-east-1"      # Main deployment
secondary_region = "us-west-2"      # DR/HA failover

# Network
primary_vpc_cidr   = "10.0.0.0/16"
secondary_vpc_cidr = "10.1.0.0/16"

# Kubernetes
kubernetes_version = "1.30"
instance_types     = ["t3.medium", "t3.large"]

# Node Groups
primary_node_group_desired   = 3
primary_node_group_min       = 2
primary_node_group_max       = 10
secondary_node_group_desired = 2
secondary_node_group_min     = 1
secondary_node_group_max     = 5

# Database
db_engine         = "mongodb"    # or mysql, postgres
db_engine_version = "7.0"
db_instance_class = "db.t3.medium"
db_allocated_storage = 100      # GB

# Domain & DNS
domain_name = "yourdomain.com"
alarm_email = "devops@yourdomain.com"
```

---

## 📊 Resources Created

### **Per Region (2 total)**
| Resource | Count | Details |
|----------|-------|---------|
| EKS Cluster | 1 | Kubernetes 1.30 |
| Node Groups | 1 | Auto-scaling EC2 instances |
| VPC | 1 | 10.0.0.0/16 or 10.1.0.0/16 |
| Subnets | 4 | 2 Public + 2 Private |
| NAT Gateways | 2 | High availability |
| ALB | 1 | Application Load Balancer |
| Security Groups | 3 | Cluster, Nodes, ALB |
| IAM Roles | 5 | For cluster, nodes, ALB, OIDC |

### **Database**
| Resource | Details |
|----------|---------|
| RDS Primary | Multi-AZ, encrypted, automated backups |
| RDS Replica | Cross-region, read-only |
| Secrets Manager | Database credentials |
| KMS Key | Encryption |

### **Global**
| Resource | Details |
|----------|---------|
| Route53 Zone | Hosted zone for domain |
| Route53 Records | Failover routing policy |
| Health Checks | Monitor ALB endpoints |
| CloudWatch Dashboard | Cross-region metrics |
| CloudWatch Alarms | CPU, memory, connections |
| SNS Topic | Alert notifications |

---

## 🔄 Common Operations

### **View Current State**
```bash
# List resources
terraform state list

# Show resource details
terraform state show aws_eks_cluster.main

# Check all outputs
terraform output
```

### **Scale Nodes**
```bash
# Edit terraform.tfvars
nano terraform.tfvars

# Change desired node count
primary_node_group_desired = 5

# Apply changes
terraform plan
terraform apply
```

### **Update Kubernetes Version**
```bash
# Update in terraform.tfvars
kubernetes_version = "1.31"

# Apply (rolling update)
terraform apply
```

### **Destroy Infrastructure**
```bash
# WARNING: This deletes EVERYTHING
terraform destroy

# Selective destroy
terraform destroy -target=module.secondary_eks
```

### **State Management**
```bash
# Backup current state
terraform state pull > terraform.tfstate.backup

# List resource in state
terraform state list

# Remove from state (doesn't delete, just forgets)
terraform state rm aws_security_group.example

# Re-import resource
terraform import aws_security_group.example sg-xxxxx
```

---

## 🔐 Security Best Practices

### **1. Protect Terraform State**
```bash
# Enable remote state with encryption
terraform {
  backend "s3" {
    bucket         = "mern-terraform-state"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# Create S3 bucket & DynamoDB table
aws s3api create-bucket --bucket mern-terraform-state --region us-east-1
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

### **2. Use Variable Secrets**
```bash
# Don't commit sensitive values
echo "*.tfvars" >> .gitignore
echo "terraform.tfstate*" >> .gitignore

# Use AWS Secrets Manager or HashiCorp Vault
```

### **3. Lock Terraform Versions**
```bash
# Create .terraform-version
echo "1.7.0" > .terraform-version

# Or use terraform blocks
terraform {
  required_version = ">= 1.5, < 2.0"
}
```

### **4. Enable Audit Logging**
```bash
# CloudTrail logs all API changes
# RDS automated backups
# EKS audit logs
# All enabled by default in this config
```

---

## 📈 Monitoring & Debugging

### **Check Terraform Logs**
```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=/tmp/terraform.log

terraform apply
cat /tmp/terraform.log
```

### **Validate Resources**
```bash
# Check AWS resources
aws eks describe-cluster --name mern-app-primary
aws rds describe-db-instances --db-instance-identifier mern-app-primary-db
aws route53 list-hosted-zones

# Check Kubernetes
kubectl get nodes
kubectl get pods -A
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### **Test Failover**
```bash
# Stop primary ALB
# Route53 should automatically failover to secondary
# Verify using curl
curl yourdomain.com
# Should return secondary region response
```

---

## 💰 Cost Estimation

### **Per Region (Primary + Secondary)**

| Service | Cost/Month |
|---------|-----------|
| EKS Cluster | $73 |
| EC2 Nodes (2 t3.medium) | $60 |
| RDS (db.t3.medium, Multi-AZ) | $150 |
| ALB | $18 |
| NAT Gateway | $45 |
| Data Transfer | $0-50 |
| **Total per Region** | **~$346** |
| **Total (2 regions)** | **~$692** |

**Optimization Tips:**
- Use Reserved Instances for stable workloads (-40%)
- Use Spot Instances for non-critical nodes (-70%)
- Right-size database instances
- Enable S3 lifecycle policies

---

## 🚨 Troubleshooting

### **Terraform Plan Shows Errors**
```bash
# Validate syntax
terraform validate

# Check AWS credentials
aws sts get-caller-identity

# Check provider versions
terraform version
```

### **EKS Cluster Creation Fails**
```bash
# Check CloudFormation events
aws cloudformation describe-stack-events --stack-name eks-primary

# Check service limits
aws service-quotas list-service-quotas --service-code eks
```

### **Database Connection Issues**
```bash
# Check security group
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Test connection
kubectl run -it --rm debug --image=mongo --restart=Never -- \
  mongosh --host mern-app-primary-db.xxxxx.rds.amazonaws.com:27017 \
  --username admin --password
```

### **Route53 Failover Not Working**
```bash
# Check health checks
aws route53 get-health-check --health-check-id xxxxx

# Test DNS
nslookup yourdomain.com
dig yourdomain.com

# Check Route53 records
aws route53 list-resource-record-sets --hosted-zone-id /hostedzone/XXXXX
```

---

## 📚 Advanced Topics

### **Customizing Modules**
Edit files in `modules/` to customize:
- Add more node groups
- Configure cluster autoscaler
- Add private ECR repositories
- Setup VPC peering
- Configure EBS encryption

### **CI/CD Integration**
```bash
# Use in GitHub Actions
- name: Terraform Plan
  run: terraform plan -out=plan.tfplan

- name: Terraform Apply
  run: terraform apply plan.tfplan
```

### **Multi-Environment Setup**
```bash
# Create separate workspaces
terraform workspace new staging
terraform workspace new production

# Use different tfvars
terraform apply -var-file="staging.tfvars"
```

---

## ✅ Checklist

- [ ] AWS account with appropriate permissions
- [ ] Terraform installed locally
- [ ] AWS credentials configured
- [ ] terraform.tfvars created and reviewed
- [ ] Domain registered and managed in Route53
- [ ] `terraform init` completed
- [ ] `terraform plan` reviewed
- [ ] `terraform apply` executed
- [ ] Outputs verified
- [ ] kubectl configured for both regions
- [ ] Application deployed to EKS
- [ ] Load testing completed
- [ ] Monitoring and alarms verified
- [ ] Backup and disaster recovery tested

---

## 📞 Support & Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

---

## 🎯 Next Steps

1. **Configure remote backend** for state management
2. **Setup CI/CD** to automate Terraform deployments
3. **Deploy applications** using Helm or Kubernetes manifests
4. **Monitor** with Prometheus + Grafana
5. **Implement disaster recovery** procedures
6. **Document** team's runbooks

---

Enjoy your multi-region EKS infrastructure! 🚀
