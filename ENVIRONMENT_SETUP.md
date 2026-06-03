# Environment Setup

## `.env` files created
- `services/auth-service/.env`
- `services/tasks-service/.env`
- `services/api-gateway/.env`
- `frontend/.env`
- `backend/.env`

## Local service variables

### `services/auth-service/.env`
- `PORT=5001`
- `NODE_ENV=development`
- `MONGO_URI=mongodb://admin:secure_change_me@mongo:27017/mernapp?authSource=admin&retryWrites=true&w=majority`
- `JWT_SECRET=change_this_jwt_secret`
- `JWT_EXPIRES_IN=7d`
- `CORS_ORIGINS=http://localhost:5173`

### `services/tasks-service/.env`
- `PORT=5002`
- `NODE_ENV=development`
- `MONGO_URI=mongodb://admin:secure_change_me@mongo:27017/mernapp?authSource=admin&retryWrites=true&w=majority`
- `JWT_SECRET=change_this_jwt_secret`
- `JWT_EXPIRES_IN=7d`
- `CORS_ORIGINS=http://localhost:5173`

### `services/api-gateway/.env`
- `PORT=4000`
- `AUTH_URL=http://auth:5001`
- `TASKS_URL=http://tasks:5002`

### `frontend/.env`
- `VITE_API_URL=/api`

### `backend/.env`
- `PORT=5000`
- `NODE_ENV=development`
- `MONGO_URI=mongodb://localhost:27017/mernapp`
- `JWT_SECRET=change_this_jwt_secret`
- `JWT_EXPIRES_IN=7d`
- `CORS_ORIGINS=http://localhost:5173,http://localhost:80,http://localhost:3000`

## Kubernetes secrets
- `k8s/01-namespace-secrets.yaml` contains:
  - `MONGO_ROOT_USER`
  - `MONGO_ROOT_PASSWORD`
  - `MONGO_DB`
  - `JWT_SECRET`
  - `JWT_EXPIRES_IN`
  - `MONGO_URI`

## Notes
- `frontend` uses `VITE_API_URL` at build time.
- `api-gateway` uses `AUTH_URL` and `TASKS_URL` at runtime.
- Auth and tasks services use the same `JWT_SECRET` for token verification.
