# Running the project as microservices (local)

This document explains how to run the converted microservice setup locally using Docker Compose and how to run a basic end-to-end smoke test.

Prerequisites
- Docker Engine / Docker Desktop
- `curl` and `jq` (for bash test), or PowerShell

Quick start

1. Copy example envs if you want to customize:

```bash
cp services/auth-service/.env.example services/auth-service/.env
cp services/tasks-service/.env.example services/tasks-service/.env
cp services/api-gateway/.env.example services/api-gateway/.env
```

2. Build and run everything:

```bash
docker compose up --build -d
```

3. Verify health endpoints:

```bash
curl http://localhost:4000/api/health
curl http://localhost:4000/api/auth/health
curl http://localhost:4000/api/tasks/health
```

E2E smoke test

Run the provided script (bash):

```bash
./scripts/e2e-test.sh
```

Or PowerShell:

```powershell
.
\scripts\e2e-test.ps1
```

Troubleshooting
- If MongoDB fails to initialise, check `mongo-init.js` and container logs: `docker compose logs -f mongo`.
- If services do not become healthy, inspect their logs: `docker compose logs -f auth` or `tasks` or `gateway`.

Notes
- Frontend proxy is configured to the gateway (`vite.config.js` points `/api` to `http://localhost:4000`).
- Shared utilities are available in `services/common` for reuse.
