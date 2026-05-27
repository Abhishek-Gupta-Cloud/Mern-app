# 🚀 Quick Deployment Guide - $150/Month Minimal Setup

## ⚡ 5-Minute Quick Start

### **Step 1: Prepare**
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

### **Step 2: Initialize**
```bash
terraform init
```

### **Step 3: Review Plan**
```bash
terraform plan

# Should show ~50-60 resources to create
# Cost estimate: ~$150/month
```

### **Step 4: Deploy**
```bash
terraform apply
# Type 'yes' when prompted
# Wait 15-20 minutes...
```

### **Step 5: Get Outputs**
```bash
terraform output
# Copy the command to configure kubectl
```

---

## 📋 Minimal Configuration Explanation

**Default `terraform.tfvars.example` uses:**

| Setting | Value | Cost |
|---------|-------|------|
| Regions | 1 (us-east-1) | Baseline |
| Nodes | 2 x t3.micro | $10/mo |
| EKS Cluster | 1 cluster | $73/mo |
| RDS | db.t3.micro, Single-AZ, 20GB | $30/mo |
| ALB | 1 load balancer | $18/mo |
| Monitoring | CloudWatch (basic) | Included |
| **TOTAL** | | **~$150/mo** |

---

## 🎛️ 3 Configuration Levels

### **Level 1: Development ($150/month) - DEFAULT**
```hcl
# Copy as-is
cp terraform.tfvars.example terraform.tfvars
terraform apply
```
✅ Perfect for: Testing, learning, staging  
✅ Includes: Basic monitoring, CloudWatch logs  
❌ Not suitable for: Production critical apps  

### **Level 2: Production-Light ($300/month)**
```hcl
# Edit terraform.tfvars
nano terraform.tfvars

# Make these changes:
primary_node_group_desired = 3
instance_types = ["t3.small", "t3.medium"]
db_instance_class = "db.t3.small"
db_multi_az = true
enable_autoscaling = true

terraform apply
```
✅ Perfect for: Small production apps  
✅ Includes: HA within region, auto-scaling  
⚠️ No cross-region failover  

### **Level 3: Enterprise HA/DR ($700/month)**
```bash
# Use production template
cp terraform.tfvars.production.example terraform.tfvars

# Edit domain and email
nano terraform.tfvars

terraform apply
```
✅ Perfect for: Mission-critical apps  
✅ Includes: Multi-region failover, read replicas  
✅ Suitable for: Enterprise requirements  

---

## 🔑 Key Settings Explained

### **To Stay at $150/month - DO NOT CHANGE:**
```hcl
primary_region           = "us-east-1"    # Single region
secondary_region         = ""              # DISABLED
instance_types           = ["t3.micro"]   # Cheapest
primary_node_group_desired = 2             # Minimum
db_instance_class        = "db.t3.micro"  # Cheapest
db_multi_az              = false           # No replica
db_allocated_storage     = 20              # Minimum
enable_autoscaling       = false           # Manual only
```

### **To Upgrade to $300/month - CHANGE THESE:**
```hcl
instance_types           = ["t3.small", "t3.medium"]
primary_node_group_desired = 3
db_instance_class        = "db.t3.small"
db_multi_az              = true
enable_autoscaling       = true
```

### **To Go to $700/month - ALSO CHANGE:**
```hcl
secondary_region         = "us-west-2"    # Add second region
primary_node_group_max   = 10
enable_monitoring        = true
```

---

## ✅ Deployment Checklist

```
[ ] AWS account with payment method
[ ] AWS CLI installed and configured
[ ] Terraform installed (v1.5+)
[ ] Git clone mern-app repo
[ ] Navigate to terraform/ directory
[ ] Copy terraform.tfvars.example → terraform.tfvars
[ ] Edit terraform.tfvars with your domain
[ ] Run: terraform init
[ ] Run: terraform plan (review output)
[ ] Run: terraform apply
[ ] Wait 15-20 minutes
[ ] Run: terraform output (copy kubeconfig commands)
[ ] Configure kubectl for primary cluster
[ ] Deploy your MERN app
[ ] Test everything works
[ ] Monitor costs for 1 week
```

---

## 📊 Real Cost Examples

### **100 Users (Minimal)**
```
EKS:      $73
Compute:  $10
Database: $30
ALB:      $18
Transfer: $5
─────────────
TOTAL:   $136/month
```
- 2 nodes running 24/7
- ~500 daily active users
- 1GB database
- Single region (US-EAST-1)

### **1,000 Users (Balanced)**
```
EKS:      $73
Compute:  $30
Database: $60
ALB:      $18
Transfer: $10
─────────────
TOTAL:   $191/month
```
- 3 nodes running 24/7
- ~5,000 daily active users
- 10GB database
- Single region with Multi-AZ

### **10,000 Users (Enterprise)**
```
EKS x2:   $146
Compute:  $100
Database: $180 (Multi-AZ + Replica)
ALB x2:   $36
Transfer: $50
─────────────
TOTAL:   $512/month
```
- 5 nodes per region
- ~50,000 daily active users
- 100GB database
- Multi-region with failover

---

## 🔍 Verify Cost After Deployment

### **1. Check AWS Billing**
```bash
aws ce get-cost-and-usage \
  --time-period Start=2024-05-01,End=2024-05-02 \
  --granularity DAILY \
  --metrics "BlendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE
```

### **2. Monitor with Infracost**
```bash
# Install
brew install infracost

# Check cost
cd terraform
infracost breakdown --path . --format table
```

### **3. Set AWS Budget Alert**
```
AWS Console → Billing → Budgets → Create Budget
├─ Monthly budget: $200
├─ Alert threshold: $180
└─ Email: your@email.com
```

---

## ⚠️ Important Notes

### **What's Included**
✅ VPC with public + private subnets  
✅ EKS cluster with managed node groups  
✅ RDS with automated backups  
✅ CloudWatch monitoring  
✅ Application Load Balancer  
✅ AWS Secrets Manager for credentials  
✅ KMS encryption for database  

### **What's NOT Included** (Add if needed)
❌ Domain name (use your own registered domain)  
❌ SSL/TLS certificates (use AWS ACM - free)  
❌ Monitoring tools (use Prometheus/Grafana - free)  
❌ CI/CD tools (use GitHub Actions - free)  
❌ Log analysis (use CloudWatch Logs - $5/month)  

### **Limits at Minimal Cost**
⚠️ **Compute**: 2 small nodes = ~200 req/sec max  
⚠️ **Database**: 20GB storage (expandable)  
⚠️ **Network**: ~10 Mbps baseline  
⚠️ **Availability**: No cross-region failover  

---

## 📈 Growth Path

```
Week 1: Deploy minimal ($150)
         ↓
         Load test your app
         ↓
Week 2-4: Monitor performance
         ↓
         Traffic analysis:
         └─ If ≤200 req/sec → Stay minimal
         └─ If 200-1000 req/sec → Upgrade to balanced
         └─ If >1000 req/sec → Upgrade to enterprise
         ↓
Month 2: Scale up if needed (edit tfvars, run terraform apply)
```

---

## 🛠️ Common Operations

### **Add More Nodes**
```bash
nano terraform.tfvars
# Change: primary_node_group_desired = 2 → 3
terraform apply
```

### **Upgrade to Bigger Database**
```bash
nano terraform.tfvars
# Change: db_instance_class = "db.t3.micro" → "db.t3.small"
terraform apply
```

### **Enable Multi-AZ (HA)**
```bash
nano terraform.tfvars
# Change: db_multi_az = false → true
terraform apply
```

### **Destroy Everything**
```bash
# WARNING: This deletes everything
terraform destroy
```

---

## 📞 Support

### **Common Issues**

**Q: Terraform apply is stuck?**  
A: EKS cluster creation takes 10-15 minutes. Be patient.

**Q: Getting AWS errors?**  
A: Check AWS credentials: `aws sts get-caller-identity`

**Q: How do I access my app?**  
A: Run `terraform output` to get LoadBalancer URL

**Q: Can I add custom domain?**  
A: Yes, update Route53 after initial deployment

**Q: What if I run out of nodes?**  
A: Pods will be pending. Scale nodes: increase `primary_node_group_desired`

---

## 🎉 Next Steps

1. **Deploy** infrastructure (this guide)
2. **Deploy** your MERN app to EKS
3. **Monitor** for 1-2 weeks
4. **Scale** up if needed (5 min terraform update)
5. **Add** more regions if needed (optional)

---

## 💡 Remember

✅ **Start small, scale as you grow**  
✅ **Terraform makes scaling easy**  
✅ **AWS provides free monitoring**  
✅ **You can always delete and try again**  
✅ **$150/month is just a starting point**

Ready to deploy? 🚀

```bash
cd terraform
terraform init
terraform apply
```

Good luck! 🎉
