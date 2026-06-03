# Architecture

## High-level architecture

```
Browser
   ↓
Frontend (React + Nginx)
   ↓ /api
API Gateway (services/api-gateway)
   ├─ /api/auth → auth-service
   └─ /api/tasks → tasks-service

auth-service → MongoDB
tasks-service → MongoDB
```

## Component roles

- `frontend`
  - Builds React app with Vite
  - Serves static assets via Nginx
  - Proxies `/api` requests to `api-gateway`

- `api-gateway`
  - Receives browser calls at `/api`
  - Forwards `/api/auth` to `auth-service`
  - Forwards `/api/tasks` to `tasks-service`

- `auth-service`
  - Handles registration, login, and user identity
  - Signs JWT tokens with `JWT_SECRET`
  - Stores users in MongoDB

- `tasks-service`
  - Handles task CRUD operations
  - Protects routes with JWT authentication
  - Stores tasks in MongoDB

- `mongodb`
  - Runs either as Docker Compose `mongo` container or Kubernetes StatefulSet
  - Used by both auth and tasks services

## Network topology

- Docker Compose uses two custom networks:
  - `backend-net` for backend services and MongoDB
  - `frontend-net` for frontend and API gateway

- Kubernetes uses namespace `mern-app`.
- In production, ingress routes `/api` to `api-gateway` and `/` to `frontend`.
