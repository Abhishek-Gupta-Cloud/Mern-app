# AWS Cost Optimization Guide - EKS Infrastructure

## 🎯 Cost Reduction Strategy

**From $400/month → $150/month (62% savings)**

---

## 📊 Cost Breakdown Comparison

### ❌ EXPENSIVE Setup ($700/month - Multi-Region HA)
```
EKS Cluster x2           = $146
EC2 Nodes (5 total)      = $100
RDS db.t3.medium Multi-AZ = $150
RDS Read Replica         = $100
ALB x2                   = $36
Data Transfer            = $30
=============================
TOTAL                    = ~$700/month
```

### ✅ MINIMAL Setup ($150/month - Single Region)
```
EKS Cluster x1           = $73
EC2 Nodes (2 x t3.micro) = $10
RDS db.t3.micro Single-AZ = $30
Data Transfer            = $10
ALB x1                   = $18
=============================
TOTAL                    = ~$150/month
```

### 🎯 BALANCED Setup ($300/month - Single Region with Backup)
```
EKS Cluster x1           = $73
EC2 Nodes (3 x t3.small) = $30
RDS db.t3.small Multi-AZ = $60
Data Transfer            = $10
ALB x1                   = $18
EBS Snapshots (backup)   = $20
=============================
TOTAL                    = ~$300/month
```

---

## 🚀 How to Deploy Minimal Cost Version

### **Option 1: Use Minimal Config (RECOMMENDED)**

```bash
cd terraform

# Copy minimal config
cp terraform.tfvars.example terraform.tfvars

# Edit to verify
cat terraform.tfvars

# Deploy
terraform init
terraform plan
terraform apply
```

**What's included:**
- Single region (us-east-1)
- 2 t3.micro nodes (minimum)
- t3.micro RDS (single AZ, no replica)
- No autoscaling
- Monitoring enabled for early issue detection

### **Option 2: Upgrade to Balanced Later**

```bash
# Start minimal ($150/month)
# Test your application
# Then upgrade by editing terraform.tfvars:

nano terraform.tfvars

# Change these lines:
# primary_node_group_desired = 2 → 3
# primary_node_group_max = 3 → 10
# instance_types = ["t3.micro"] → ["t3.small", "t3.medium"]
# db_instance_class = "db.t3.micro" → "db.t3.small"
# db_multi_az = false → true

terraform plan
terraform apply
```

### **Option 3: Add Secondary Region for HA**

```bash
nano terraform.tfvars

# Change this line:
# secondary_region = ""  →  "us-west-2"

# Costs jump from $150 → $450/month (+$300)
# Add for production critical apps

terraform plan
terraform apply
```

---

## 💰 Cost Reduction Techniques

### **1. Instance Type Selection** (Saves ~70%)
```hcl
# EXPENSIVE
instance_types = ["t3.medium", "t3.large"]  # $50-100/month

# MINIMAL
instance_types = ["t3.micro", "t3.small"]   # $10-30/month

# FREE TIER (if eligible)
instance_types = ["t2.micro"]  # $0/month for 12 months
```

### **2. Node Count** (Saves ~30%)
```hcl
# EXPENSIVE - More HA
primary_node_group_desired = 3
primary_node_group_max = 10

# MINIMAL - Just enough
primary_node_group_desired = 2
primary_node_group_max = 3

# Kubernetes still runs HA services within nodes
```

### **3. Database Configuration** (Saves ~80%)
```hcl
# EXPENSIVE
db_instance_class = "db.t3.medium"  # $150/month
db_multi_az = true                  # +50%
allocated_storage = 100             # $12/month

# MINIMAL
db_instance_class = "db.t3.micro"   # $30/month
db_multi_az = false                 # Save $15/month
allocated_storage = 20              # $2/month

# You can always scale up if needed
```

### **4. No Read Replica** (Saves ~$100)
```hcl
# EXPENSIVE
secondary_region = "us-west-2"      # Creates replica

# MINIMAL
secondary_region = ""               # Disable secondary region

# Use RDS automated backups instead (already enabled)
```

### **5. Single Region** (Saves ~$300)
```hcl
# EXPENSIVE - Multi-region failover
primary_region = "us-east-1"
secondary_region = "us-west-2"

# MINIMAL - Single region
primary_region = "us-east-1"
secondary_region = ""

# Route53 failover disabled
# Deploy to one region only
```

---

## 🎛️ Scaling Up When Needed

### **Stage 1: Development** ($150/month)
- Single region
- 2 t3.micro nodes
- t3.micro RDS
- Perfect for: Testing, staging, proof of concept

### **Stage 2: Production-Light** ($300/month)
- Single region
- 3 t3.small nodes
- t3.small RDS Multi-AZ
- Perfect for: Small production apps, startups

```bash
# Upgrade script
nano terraform.tfvars

# Changes:
primary_node_group_desired = 2 → 3
instance_types = ["t3.micro"] → ["t3.small"]
db_instance_class = "db.t3.micro" → "db.t3.small"
db_multi_az = false → true

terraform apply
```

### **Stage 3: Enterprise** ($700/month)
- Multi-region HA/DR
- 3 nodes per region
- t3.medium RDS Multi-AZ + Read Replica
- Perfect for: Mission-critical, high availability

```bash
# Upgrade to production config
cp terraform.tfvars.production.example terraform.tfvars
# Or edit to add secondary_region = "us-west-2"

terraform apply
```

---

## 🔧 Cost Monitoring

### **Set up AWS Budgets**
```bash
# Monitor spending in real-time
# AWS Console → Billing → Budgets → Create Budget

# Alert when spending exceeds $200/month (example)
```

### **Check Terraform Costs**
```bash
# Install Infracost
brew install infracost

# Run cost analysis
infracost breakdown --path .

# Before and after
infracost diff --path . -c terraform.tfvars
```

### **Monitor Actual Costs**
```bash
# Check AWS billing
aws ce get-cost-and-usage \
  --time-period Start=2024-05-01,End=2024-05-31 \
  --granularity MONTHLY \
  --metrics "BlendedCost"
```

---

## 🎯 terraform.tfvars - Quick Reference

### **Minimal Cost**
```hcl
primary_region           = "us-east-1"
secondary_region         = ""                    # DISABLED
instance_types           = ["t3.micro"]
primary_node_group_desired = 2
primary_node_group_max   = 3
db_instance_class        = "db.t3.micro"
db_multi_az              = false
db_allocated_storage     = 20
enable_autoscaling       = false
```

### **Balanced**
```hcl
primary_region           = "us-east-1"
secondary_region         = ""                    # DISABLED
instance_types           = ["t3.small", "t3.medium"]
primary_node_group_desired = 3
primary_node_group_max   = 10
db_instance_class        = "db.t3.small"
db_multi_az              = true
db_allocated_storage     = 50
enable_autoscaling       = true
```

### **Production HA/DR**
```hcl
primary_region           = "us-east-1"
secondary_region         = "us-west-2"           # ENABLED
instance_types           = ["t3.medium", "t3.large"]
primary_node_group_desired = 3
primary_node_group_max   = 10
secondary_node_group_desired = 2
secondary_node_group_max = 5
db_instance_class        = "db.t3.medium"
db_multi_az              = true
db_allocated_storage     = 100
enable_autoscaling       = true
```

---

## ⚠️ Trade-offs: What You Lose at Minimal Cost

### **No High Availability Across Regions**
- If us-east-1 goes down, app goes down
- Solution: Upgrade to multi-region later

### **Limited Compute Power**
- t3.micro can handle ~100-200 requests/sec
- If traffic spikes, you'll hit limits
- Solution: Scale up instance types or add nodes

### **Limited Database Capacity**
- 20GB storage for MVP (expandable)
- No read replicas for scaling reads
- Solution: Increase storage or add replica later

### **No Database High Availability**
- Single RDS instance (no Multi-AZ)
- Maintenance causes ~2 min downtime
- Solution: Enable Multi-AZ for $15/month more

### **Limited Monitoring**
- Basic monitoring only (no Datadog, etc.)
- Solution: Enable more detailed monitoring if needed

---

## ✅ When to Upgrade

**Upgrade to Balanced ($300) when:**
- ✅ Getting 200+ requests/second
- ✅ Database at >50% CPU
- ✅ Want zero-downtime deployments
- ✅ Running critical business app

**Upgrade to HA/DR ($700) when:**
- ✅ Can't afford downtime (SLA required)
- ✅ Compliance needs geographic redundancy
- ✅ Want automatic failover
- ✅ Fortune 500 customer requirements

---

## 🚀 Deployment Path

### **Step 1: Deploy Minimal ($150)**
```bash
cp terraform.tfvars.example terraform.tfvars
terraform apply
# Test your app
```

### **Step 2: Monitor Costs**
```bash
# Check actual bill after 1-2 weeks
# Verify it's ~$150/month
```

### **Step 3: Load Test**
```bash
# Simulate your expected traffic
# See if t3.micro can handle it
```

### **Step 4: Scale if Needed**
```bash
# If hitting limits, edit terraform.tfvars
# Increase instance types or node count
# Run terraform apply again
```

### **Step 5: Consider HA (Optional)**
```bash
# For production, consider adding:
# - Multi-AZ RDS ($15/month more)
# - Secondary region ($300/month more)
```

---

## 💡 Pro Tips

### **Use AWS Free Tier**
```bash
# Up to 12 months of t2.micro (if new account)
# Up to 750 hours/month = FREE for development
# Use during prototyping phase
```

### **Reserved Instances** (Save 40%)
```bash
# After 3 months of stable usage:
# - Buy 1-year reserved instance
# - Saves $40/month on compute
```

### **Spot Instances** (Save 70%)
```bash
# For non-critical workloads:
# - Use Spot instead of On-Demand
# - t3.micro Spot = $3/month
# - But can be interrupted
```

### **Auto-scaling** (Pay for what you use)
```bash
# Enable auto-scaling:
enable_autoscaling = true
# Nodes scale from 2-10 automatically
# Pay only for what you actually use
```

---

## 📞 Troubleshooting High Costs

### **Problem: Bill is $200+ instead of $150**
```bash
# Check what's running:
aws ec2 describe-instances --region us-east-1
aws rds describe-db-instances --region us-east-1

# Kill extra resources:
terraform destroy  # If starting over
# Or manually delete unused resources
```

### **Problem: Can't afford even $150**
```bash
# Option 1: Use Lambda + API Gateway instead
# Option 2: Use Docker locally (free)
# Option 3: Use Heroku free tier ($0)
```

### **Problem: Monthly bill keeps growing**
```bash
# Check for storage growth
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,AllocatedStorage]'

# Check for unattached volumes
aws ec2 describe-volumes --query 'Volumes[?State!=`in-use`]'

# Delete unused resources
```

---

## 🎯 Conclusion

**Start small, scale as you grow.**

1. Deploy minimal setup ($150/month)
2. Test your application
3. Monitor usage patterns
4. Scale up only when needed
5. Use auto-scaling to pay for actual usage

No need to pay $700/month from day one! 🚀

---

## 📊 Quick Comparison Table

| Feature | Minimal | Balanced | Production |
|---------|---------|----------|-----------|
| Cost/Month | $150 | $300 | $700 |
| Regions | 1 | 1 | 2 |
| Nodes | 2 micro | 3 small | 5 medium |
| RDS Instance | micro | small | medium |
| Multi-AZ | ❌ | ✅ | ✅ |
| Read Replica | ❌ | ❌ | ✅ |
| Auto-Scaling | ❌ | ✅ | ✅ |
| Failover | Manual | Manual | Automatic |
| SLA | None | 99% | 99.99% |
| Recommended For | Dev/Test | Small Prod | Enterprise |

---

**Choose your starting point and upgrade as you grow!** 🌱→🌳
