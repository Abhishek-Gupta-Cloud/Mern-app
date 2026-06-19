# ── Stage 1: build ───────────────────────────────────────────────
FROM dhi.io/node:22-alpine-dev AS builder
RUN apk update && apk upgrade --no-cache
WORKDIR /app
ARG VITE_API_URL=/api
ENV VITE_API_URL=$VITE_API_URL

COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# ── Stage 2: serve with nginx ──────────────────────────────────────
FROM dhi.io/nginx:1.31-alpine
COPY --chown=nginx:nginx --from=builder /app/dist /usr/share/nginx/html
COPY --chown=nginx:nginx nginx.conf /etc/nginx/conf.d/default.conf
USER nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
