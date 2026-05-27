# MERN Microservices – 4-Tier Architecture

Production-ready Task Management Application using Docker Compose microservices.

```
Tier 1 (Presentation)  →  React + Vite + Nginx (frontend)
Tier 2 (API Gateway)   →  Node.js + Express (gateway)
Tier 3 (Services)      →  auth-service + tasks-service
Tier 4 (Data)          →  MongoDB 7
```

## 🚀 Quick Start

### Docker Compose microservices (Recommended)

```bash
# 1. Clone and enter the project
git clone <repo-url> && cd mern-app

# 2. Copy service env files
cp services/auth-service/.env.example services/auth-service/.env
cp services/tasks-service/.env.example services/tasks-service/.env
cp services/api-gateway/.env.example services/api-gateway/.env
cp frontend/.env.example frontend/.env.local

# 3. Edit environment variables
# Update: JWT_SECRET, CORS_ORIGINS, and MongoDB connection strings as needed

# 4. Launch all services
docker compose up --build -d

# 5. View logs
docker compose logs -f

# 6. App is live at http://localhost
```

**Stop:**
```bash
docker compose down
```

### Local Development (without Docker)

**Prerequisites:** Node.js 20+, MongoDB running locally

**Backend and frontend monolith (legacy):**
```bash
cd backend
npm install
cp .env.example .env   # set MONGO_URI=mongodb://localhost:27017/mernapp
npm run dev
```

```bash
cd frontend
npm install
npm run dev            # http://localhost:5173 (proxies /api → :5000)
```

> Note: The current recommended deployment is the `services/` microservices stack. The `backend/` and `frontend/` folders remain for reference only.

---

## 📋 Project Structure

```
mern-app/
├── docker-compose.yml          # Microservices Docker Compose stack
├── README-MICROSERVICES.md     # Microservices deployment guide
├── EKS-README.md               # AWS EKS deployment guide
├── PRODUCTION-DEPLOYMENT.md    # Deployment summary and variables
├── services/
│   ├── auth-service/
│   ├── tasks-service/
│   ├── api-gateway/
│   └── common/
├── frontend/
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── .env.example
│   └── src/
└── k8s/
    ├── 01-namespace-secrets.yaml
    ├── 02-mongodb.yaml
    ├── 03-backend.yaml
    └── 04-frontend.yaml
```

---

## 🔌 API Reference

### Authentication

| Method | Endpoint           | Auth | Request           | Response      |
|--------|-------------------|------|-------------------|---------------|
| POST   | `/api/auth/register` | ✗    | `{name, email, password}` | `{token, user}` |
| POST   | `/api/auth/login`    | ✗    | `{email, password}` | `{token, user}` |
| GET    | `/api/auth/me`       | ✓    | —                 | `{user}`      |

### Tasks

| Method | Endpoint           | Auth | Query Params      | Description       |
|--------|-------------------|------|-------------------|-------------------|
| GET    | `/api/tasks`       | ✓    | `status, priority, page, limit` | List user's tasks |
| GET    | `/api/tasks/:id`   | ✓    | —                 | Get single task   |
| POST   | `/api/tasks`       | ✓    | —                 | Create task       |
| PATCH  | `/api/tasks/:id`   | ✓    | —                 | Update task       |
| DELETE | `/api/tasks/:id`   | ✓    | —                 | Delete task       |
| GET    | `/api/tasks/stats` | ✓    | —                 | Task statistics   |

### Health

| Method | Endpoint         | Auth | Response            |
|--------|------------------|------|---------------------|
| GET    | `/api/health`    | ✗    | `{status, timestamp}` |

---

## 🔐 Security Features

✅ **Implemented:**
- JWT authentication with 7-day expiry
- Password hashing with bcryptjs
- Rate limiting (200 req/15 min)
- CORS validation
- Security headers (Helmet)
- Request size limiting (10KB)
- MongoDB injection prevention
- Non-root Docker user
- Health checks with automatic restarts

⚠️ **To Add:**
- HTTPS/TLS (via Let's Encrypt or reverse proxy)
- API key management
- Audit logging
- Two-factor authentication

---

## 📦 Environment Variables

### Auth service (`services/auth-service/.env`)

```env
PORT=5001
NODE_ENV=production

# MongoDB
MONGO_URI=mongodb://admin:password@mongo:27017/mernapp?authSource=admin&retryWrites=true&w=majority

# JWT
JWT_SECRET=<openssl rand -base64 64>
JWT_EXPIRES_IN=7d

# CORS
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

### Tasks service (`services/tasks-service/.env`)

```env
PORT=5002
NODE_ENV=production

# MongoDB
MONGO_URI=mongodb://admin:password@mongo:27017/mernapp?authSource=admin&retryWrites=true&w=majority

# JWT
JWT_SECRET=<openssl rand -base64 64>

# CORS
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

### API Gateway (`services/api-gateway/.env`)

```env
PORT=4000
AUTH_URL=http://auth:5001
TASKS_URL=http://tasks:5002
```

### Frontend (`frontend/.env.local`)

```env
VITE_API_URL=/api
```

---

## 🚢 Deployment

### Quick Deployment

```bash
# Use Docker Compose for the microservices stack
docker compose up --build -d
```

### Guides

- See `README-MICROSERVICES.md` for local microservices deployment.
- See `EKS-README.md` for AWS EKS deployment.
- See `PRODUCTION-DEPLOYMENT.md` for production readiness and variable guidance.

### Supported Platforms

- ✅ Docker Compose (VPS, EC2, DigitalOcean, Linode)
- ✅ Kubernetes (EKS, GKE, AKS)
- ✅ Render.com
- ✅ Railway.app
- ✅ Vercel (frontend only)
- ✅ AWS ECS
- ✅ Docker Hub + Custom VPS

**See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed instructions.**

---

## 💾 Backups

```bash
# Create backup
./backup.sh backup

# List backups
./backup.sh list

# Restore from backup
./backup.sh restore ./backups/backup-20240521_120000

# Cleanup old backups (keep last 7)
./backup.sh cleanup
```

---

## 📊 Monitoring & Logs

```bash
# View all logs
docker compose logs -f

# View specific service
docker compose logs -f api      # Backend
docker compose logs -f mongo    # Database
docker compose logs -f frontend # Frontend

# Check service health
docker compose ps

# Restart services
docker compose restart
```

---

## 🛠 Development

### Run Tests

```bash
# Backend
cd backend && npm run test

# Frontend
cd frontend && npm run test
```

### Linting

```bash
# Backend
cd backend && npm run lint

# Frontend
cd frontend && npm run build
```

---

## 🤝 Contributing

1. Create a feature branch: `git checkout -b feature/amazing-feature`
2. Commit changes: `git commit -m 'Add amazing feature'`
3. Push to branch: `git push origin feature/amazing-feature`
4. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License – see LICENSE.md for details.

---

## 🆘 Troubleshooting

| Problem | Solution |
|---------|----------|
| API won't start | Check MongoDB connection: `docker compose logs mongo` |
| CORS errors | Update `CORS_ORIGINS` in backend `.env` |
| 502 Bad Gateway | Verify API health: `curl http://localhost:5000/api/health` |
| Port already in use | Change port in `docker-compose.yml` |
| Database won't connect | Verify `MONGO_URI` and credentials |

**For more help:** Check [DEPLOYMENT.md](./DEPLOYMENT.md) → Troubleshooting section
| POST   | /api/auth/login       | ✗    | Login, get JWT      |
| GET    | /api/auth/me          | ✓    | Get current user    |
| GET    | /api/tasks            | ✓    | List tasks (filter) |
| POST   | /api/tasks            | ✓    | Create task         |
| GET    | /api/tasks/:id        | ✓    | Get one task        |
| PATCH  | /api/tasks/:id        | ✓    | Update task         |
| DELETE | /api/tasks/:id        | ✓    | Delete task         |
| GET    | /api/tasks/stats      | ✓    | Count by status     |
| GET    | /api/health           | ✗    | Health check        |

## Environment variables (backend)

| Variable        | Default               | Description           |
|-----------------|-----------------------|-----------------------|
| PORT            | 5000                  | Server port           |
| MONGO_URI       | —                     | MongoDB connection URL|
| JWT_SECRET      | —                     | JWT signing secret    |
| JWT_EXPIRES_IN  | 7d                    | Token lifetime        |
| CORS_ORIGINS    | http://localhost:5173 | Allowed origins       |

## Production checklist

- [ ] Replace `JWT_SECRET` with a 64-char random string
- [ ] Set strong `MONGO_ROOT_PASSWORD`
- [ ] Enable HTTPS (add Certbot / Traefik in docker-compose)
- [ ] Add `NODE_ENV=production` in backend container
- [ ] Set up MongoDB replica set for transactions
- [ ] Configure log aggregation (ELK / Loki)
