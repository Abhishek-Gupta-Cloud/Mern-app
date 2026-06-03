# Troubleshooting

## Docker Compose issues

### Docker daemon unavailable
- Error: `failed to connect to the docker API ... The system cannot find the file specified.`
- Fix: Start Docker Desktop or ensure the Docker daemon is running.

### Healthcheck failures
- Auth, tasks, and gateway healthchecks use `curl -f`.
- If a healthcheck still fails, inspect logs:
  ```bash
docker compose logs -f auth
docker compose logs -f tasks
docker compose logs -f gateway
```

### MongoDB startup issues
- If Mongo fails to start, check that no other process is using port 27017.
- Confirm `mongo` container logs with `docker compose logs -f mongo`.

## Kubernetes issues

### Services not in namespace
- Verify service YAML files include `namespace: mern-app`.
- Correct manifests: `k8s/auth-service/service.yaml`, `k8s/tasks-service/service.yaml`, `k8s/api-gateway/service.yaml`, `k8s/frontend/service.yaml`, `k8s/ingress.yaml`.

### Secret injection failures
- Confirm `kubectl get secret app-secret -n mern-app` exists.
- Confirm auth/tasks deployments use `envFrom: secretRef: name: app-secret`.

### Ingress routes not resolving
- Update `k8s/ingress.yaml` host to your production domain.
- Use `kubectl describe ingress mern-app-ingress -n mern-app` to inspect errors.

## Application issues

### API requests return 404 or CORS errors
- Ensure frontend uses `VITE_API_URL=/api`.
- Confirm API gateway is reachable via `http://localhost:4000/api/health`.
- Confirm the frontend Nginx proxy is configured to route `/api/` to `api-gateway:4000`.

### JWT authentication fails
- Ensure `JWT_SECRET` is identical for both `auth-service` and `tasks-service`.
- Ensure `MONGO_URI` is correct and Mongo is reachable.

## CI/CD issues

### Undefined `matrix.image`
- `ci-cd.yml` now uses `matrix.service.name`.
- If you still see errors, verify the job matrix section in `.github/workflows/ci-cd.yml`.

### Missing Kubernetes manifest files
- The workflow now deploys actual manifests under `k8s/auth-service`, `k8s/tasks-service`, `k8s/api-gateway`, and `k8s/frontend`.

## Remaining manual checks
- Validate `frontend` build locally with `cd frontend && npm run build`.
- Ensure AWS credentials are valid for ECR/EKS deployments.
- Confirm the Docker daemon is running before `docker compose up --build`.
