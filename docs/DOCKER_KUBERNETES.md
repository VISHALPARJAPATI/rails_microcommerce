# Docker and Kubernetes (Step 9)

## Docker

### Production image

Build and run the production image (port 80, Thruster):

```bash
docker build -t rails_microcommerce .
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY="$(cat config/master.key)" \
  -e DATABASE_URL="mysql2://user:pass@host:3306/dbname" \
  --name rails_microcommerce rails_microcommerce
```

The container runs `db:prepare` on startup when the command is the Rails server.

### Local development with Docker Compose

Runs the app, MySQL, Redis, Zookeeper, and Kafka:

```bash
docker compose up -d
docker compose run --rm app bin/rails db:create db:migrate
```

- **App:** http://localhost:3000  
- **MySQL:** localhost:3306 (root/password)  
- **Redis:** localhost:6379  
- **Kafka:** localhost:9092 (from host); use `kafka:29092` from another container  

Required env for the app (`DATABASE_URL`, `REDIS_URL`, `KAFKA_BROKERS`) are set in `docker-compose.yml`. Add Stripe keys via a `.env` file or override in compose if needed.

---

## Kubernetes

Manifests live under `kubernetes/`. Deploy in order:

1. **Namespace**
   ```bash
   kubectl apply -f kubernetes/namespace.yaml
   ```

2. **ConfigMap** (non-sensitive env)
   ```bash
   kubectl apply -f kubernetes/configmap.yaml
   ```
   Edit `configmap.yaml` to set `REDIS_URL` and `KAFKA_BROKERS` if you use Redis/Kafka in-cluster.

3. **Secret** (sensitive env)
   ```bash
   cp kubernetes/secret.yaml.example kubernetes/secret.yaml
   # Edit secret.yaml with real values (RAILS_MASTER_KEY, DATABASE_URL, etc.)
   kubectl apply -f kubernetes/secret.yaml
   ```
   Do not commit `secret.yaml` (it is gitignored).

4. **Deployment and Service**
   ```bash
   kubectl apply -f kubernetes/deployment.yaml
   kubectl apply -f kubernetes/service.yaml
   ```
   Update `deployment.yaml` with your image (e.g. `ghcr.io/your-org/rails_microcommerce:latest`). The app listens on port 80 and exposes `/up` for liveness/readiness.

5. **Ingress** (optional)
   ```bash
   kubectl apply -f kubernetes/ingress.yaml
   ```
   Change `host` and add your ingress class / TLS annotations as needed.

### Database and dependencies

Production database, Redis, and Kafka are not included in these manifests. Use a managed service or deploy them separately (e.g. MySQL StatefulSet or operator, Redis, Kafka). Set `DATABASE_URL`, `REDIS_URL`, and `KAFKA_BROKERS` in the Secret or ConfigMap to point to those services.

### Building and pushing the image for K8s

```bash
docker build -t your-registry/rails_microcommerce:latest .
docker push your-registry/rails_microcommerce:latest
```

Then set `image: your-registry/rails_microcommerce:latest` in `kubernetes/deployment.yaml`.
