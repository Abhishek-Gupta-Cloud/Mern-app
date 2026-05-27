# Trivy & SonarQube Security & Quality Setup

## 🔒 Overview

The CI/CD pipeline now includes:
- **Trivy**: Container image vulnerability scanning
- **SonarQube**: Code quality and security analysis

---

## 📋 Prerequisites

### **Trivy** (Free, Built-in)
- ✅ Pre-installed in GitHub Actions
- ✅ No setup needed
- ✅ Scans for CVEs in Docker images
- ✅ Integrated with GitHub Security tab

### **SonarQube** (Optional, Free Plan Available)
- Setup required
- Analyzes code quality, security issues, code coverage
- Can be self-hosted or use SonarQube Cloud

---

## 🔒 Trivy Scanning

### What it does:
- Scans Docker images for vulnerabilities (CVE database)
- Checks dependencies for known security issues
- Fails build if CRITICAL vulnerabilities found
- Uploads results to GitHub Security tab

### How it works in CI/CD:
1. Build Docker image locally
2. Run Trivy scan
3. If CRITICAL vulnerabilities: ❌ Block push to ECR
4. If safe: ✅ Push to ECR

### GitHub Secrets needed:
✅ **None** - Trivy is built-in and free

### Manual Trivy scan locally:
```bash
# Install Trivy
# macOS
brew install trivy

# Linux
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Scan Docker image
trivy image mern-backend:latest
trivy image mern-frontend:latest

# Scan with JSON output
trivy image --format json --output report.json mern-backend:latest

# Scan and fail on CRITICAL
trivy image --exit-code 1 --severity CRITICAL mern-backend:latest
```

### View Trivy results in GitHub:
1. Go to repo → **Security** tab
2. Click **Code scanning** → View Trivy alerts
3. Each vulnerability shows:
   - Package name
   - Vulnerability ID (CVE-XXXX-XXXXX)
   - Severity (CRITICAL, HIGH, MEDIUM, LOW)
   - Recommended fix

---

## 📊 SonarQube Setup

### Option 1: SonarQube Cloud (Easiest)

#### Step 1: Create Account
```
1. Go to: https://sonarcloud.io/
2. Sign up with GitHub
3. Authorize GitHub integration
4. Create organization (e.g., "my-company")
5. Add repository
```

#### Step 2: Get Token
```
1. SonarCloud → My Account → Security → Generate Token
2. Copy token (looks like: squ_1a2b3c4d5e6f...)
3. Save as GitHub Secret
```

#### Step 3: Add GitHub Secrets
Repository → Settings → Secrets → New secret

| Secret Name | Value |
|------------|-------|
| `SONAR_HOST_URL` | `https://sonarcloud.io` |
| `SONAR_TOKEN` | Your SonarCloud token |

#### Step 4: Verify
Push code → Workflow runs → Check SonarCloud dashboard

---

### Option 2: Self-Hosted SonarQube (Advanced)

#### Step 1: Run SonarQube in Docker
```bash
docker run -d \
  -p 9000:9000 \
  --name sonarqube \
  sonarqube:latest

# Access at http://localhost:9000
# Default login: admin/admin
```

#### Step 2: Create Token
```
1. Login to http://localhost:9000
2. Admin → Security → Users → Tokens
3. Generate new token
4. Copy token
```

#### Step 3: Update GitHub Secrets
| Secret | Value |
|--------|-------|
| `SONAR_HOST_URL` | `http://your-server:9000` |
| `SONAR_TOKEN` | Your token |

#### Step 4: Deploy SonarQube to Production
```bash
# Using Docker Compose
docker-compose -f sonarqube-compose.yml up -d

# Or AWS ECS, EKS, etc.
```

---

## 📈 SonarQube Metrics

### What SonarQube analyzes:
| Metric | Description |
|--------|------------|
| **Code Smells** | Maintainability issues |
| **Bugs** | Potential runtime errors |
| **Vulnerabilities** | Security issues |
| **Coverage** | Unit test coverage % |
| **Duplications** | Code duplication % |
| **Technical Debt** | Estimated fix time |

### Quality Gate Rules (Default):
- ❌ Fail if: `coverage < 80%` or `bugs > 0`
- ⚠️ Warning if: `code_smells > 10`

---

## 📝 Configure Project Analysis

### Backend (`backend/` folder):
```yaml
sonar.projectKey=mern-backend
sonar.projectName=MERN Backend
sonar.sources=backend/src
sonar.exclusions=backend/node_modules/**,backend/**/*.test.js
sonar.javascript.lcov.reportPaths=backend/coverage/lcov.info
sonar.tests=backend/src
sonar.test.inclusions=**/*.test.js
```

### Frontend (`frontend/` folder):
```yaml
sonar.projectKey=mern-frontend
sonar.projectName=MERN Frontend
sonar.sources=frontend/src
sonar.exclusions=frontend/node_modules/**,frontend/dist/**
sonar.javascript.lcov.reportPaths=frontend/coverage/lcov.info
sonar.tests=frontend/src
sonar.test.inclusions=**/*.test.jsx
```

---

## 🧪 Generate Coverage Reports

### Backend (Node.js)
```bash
cd backend

# Install coverage tool
npm install --save-dev jest

# Add to package.json scripts:
"test": "jest",
"test:coverage": "jest --coverage"

# Run tests with coverage
npm run test:coverage
```

### Frontend (React/Vite)
```bash
cd frontend

# Install Vitest (Vite test runner)
npm install --save-dev vitest @vitest/coverage-v8

# Add to package.json scripts:
"test": "vitest",
"test:coverage": "vitest --coverage"

# Run tests with coverage
npm run test:coverage
```

---

## 🔍 View Results

### GitHub Security Tab:
```
Repository → Security → Code scanning → View alerts
```

Shows:
- Trivy vulnerability findings
- SARIF format analysis results
- Can be filtered by severity

### SonarQube Dashboard:
```
1. Go to: https://sonarcloud.io/dashboard
2. Select project
3. View:
   - Quality Gate status
   - Code metrics
   - Issue breakdown
   - Coverage trends
   - Duplicate code
```

---

## 🚀 CI/CD Pipeline Flow (with Trivy + SonarQube)

```
Push to GitHub
    ↓
test-backend (npm tests)
test-frontend (npm build)
sonarqube-scan (code quality analysis)
    ↓
build-and-push
  ├─ Build Docker image
  ├─ Run Trivy scan (vulnerability check)
  │   ├─ If CRITICAL found: ❌ FAIL
  │   └─ If safe: ✓ PASS
  ├─ Upload results to GitHub Security
  └─ Push to ECR
    ↓
deploy-to-eks (main branch only)
    ↓
notify-slack
```

---

## ⚠️ Handling Vulnerabilities

### Found a CRITICAL vulnerability?

#### Option 1: Update Dependency
```bash
# Backend
cd backend
npm update vulnerable-package
npm audit fix

# Frontend
cd frontend
npm update vulnerable-package
npm audit fix
```

#### Option 2: Suppress (Not Recommended)
In Dockerfile, add:
```dockerfile
# Trivy: ignore CVE-YYYY-XXXXX due to outdated dependency
# TODO: Update when package releases fix
RUN npm install
```

#### Option 3: Ignore in Workflow
Update `.github/workflows/ci-cd.yml`:
```yaml
- name: Run Trivy
  uses: aquasecurity/trivy-action@master
  with:
    ignore-unfixed: false  # Include unfixed CVEs
    skip-dirs: 'node_modules/some-package'
```

---

## 🛑 Fail Build on Quality Issues

### Block merge if quality gate fails:

#### 1. Set up branch protection rule:
```
Repository → Settings → Branches → Branch protection rules
  ├─ Require status checks to pass
  ├─ Select: test-backend, test-frontend, sonarqube-scan, build-and-push
  └─ Require branches to be up to date before merging
```

#### 2. SonarQube Quality Gate:
```
Admin → Quality Gates → Create/Edit
  ├─ Condition: coverage >= 80%
  ├─ Condition: bugs == 0
  ├─ Condition: vulnerabilities == 0
  └─ Condition: code_smells < 10
```

#### 3. When to fail:
```yaml
- If Trivy finds CRITICAL CVEs → ❌ Block deployment
- If SonarQube quality gate fails → ⚠️ Warning (optional block)
```

---

## 📊 Sample Results

### Trivy Output:
```
╞════════════════════════════════════════╡
│ mern-backend:latest (node 20-alpine)   │
├────────────────┬──────────────────────┤
│ Total          │ 5                    │
│ CRITICAL       │ 0                    │
│ HIGH           │ 1                    │
│ MEDIUM         │ 3                    │
│ LOW            │ 1                    │
└────────────────┴──────────────────────┘

HIGH: [npm package] express-js-dos
└─ Recommendation: Update to express@4.19.3+
```

### SonarQube Dashboard:
```
Quality Gate: ✅ PASSED

Code Metrics:
├─ Coverage: 85% ✅
├─ Bugs: 0 ✅
├─ Vulnerabilities: 0 ✅
├─ Code Smells: 8 ✅
├─ Duplication: 3.2% ✅
└─ Technical Debt: 2h

Issues:
├─ Code Smell (Minor): Missing error handling in async function
├─ Code Smell (Major): Function too complex (18 > 15)
└─ Security (Critical): SQL injection risk detected
```

---

## 🔧 Troubleshooting

### Trivy: "Image not found"
```bash
# Solution: Build image first before scanning
docker build -t mern-backend:latest backend/
trivy image mern-backend:latest
```

### SonarQube: "No coverage reports found"
```bash
# Solution: Run tests with coverage
npm run test:coverage
# Verify coverage/ directory exists
ls backend/coverage/
```

### SonarQube: "Authentication failed"
```bash
# Solution: Verify token
aws secrets list  # Check SONAR_TOKEN secret
# Or regenerate token in SonarCloud
```

### Trivy finds many vulnerabilities?
```bash
# Update base image to latest
docker pull node:20-alpine  # Get latest security patches
docker pull nginx:1.27-alpine

# Update dependencies
npm audit fix --force
npm update
```

---

## 📚 Resources

- [Trivy GitHub](https://github.com/aquasecurity/trivy)
- [SonarQube Cloud](https://sonarcloud.io/)
- [SonarQube Docs](https://docs.sonarqube.org/)
- [CVE Database](https://cve.mitre.org/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

---

## ✅ Checklist

- [ ] Add `SONAR_HOST_URL` secret to GitHub
- [ ] Add `SONAR_TOKEN` secret to GitHub
- [ ] Verify Trivy scanning works (check Actions logs)
- [ ] Verify SonarQube analysis works
- [ ] Set branch protection rules
- [ ] View first Trivy report in Security tab
- [ ] View first SonarQube report in dashboard
- [ ] Update dependencies if vulnerabilities found
- [ ] Configure coverage thresholds
- [ ] Set quality gate rules

---

## 🚀 Next Steps

1. **For SonarQube Cloud** (Recommended):
   - Create account at https://sonarcloud.io
   - Add GitHub secrets
   - Push code and watch analysis run

2. **For Self-Hosted SonarQube** (Advanced):
   - Deploy SonarQube server
   - Configure webhook back to GitHub
   - Set up quality gates

3. **Fix initial issues**:
   - Address all CRITICAL vulnerabilities
   - Fix code quality issues
   - Improve test coverage

4. **Enable branch protection**:
   - Require CI checks to pass
   - Require quality gate to pass
   - Require code review

Enjoy secure, high-quality code! 🎉
