# Module 6 — Docker (1.5 Weeks)

> **Objective:** Master containerization from Dockerfile best practices to production-grade multi-service applications with security scanning.

---

## 🚢 Real-World Analogy: Docker is Like Shipping Containers

Before Docker, deploying software was like **moving houses** — fragile, different every time, things always break.
Docker is like the **standardized shipping container** that revolutionized global trade:

```
📦 BEFORE DOCKER (Moving house — chaos!):

  Developer's Laptop → "Works on my machine!" 😤
  Testing Server     → "Missing library version 2.3" 💥
  Production Server  → "Wrong Python version" 🔥
  
  Every server is set up differently, like every house is packed differently.


📦 AFTER DOCKER (Shipping container — standard!):

  ┌──────────────────────────────────────────┐
  │  Docker Container                        │
  │  ┌──────────────────────────────────┐    │
  │  │  Your App + ALL its dependencies │    │
  │  │  Python 3.11 + Flask + Libraries │    │
  │  │  Exact same everywhere!          │    │
  │  └──────────────────────────────────┘    │
  └──────────────────────────────────────────┘
       │              │              │
    Laptop       Test Server    Production
    ✅ Works!     ✅ Works!      ✅ Works!
```

### The Restaurant Kitchen Analogy
```
   Docker Image  = Recipe Card (frozen, read-only)
   Container     = Dish being cooked (running instance of the recipe)
   Dockerfile    = Step-by-step cooking instructions
   Docker Hub    = Cookbook library (community recipes)
   Volume        = Shared pantry (data persists even if kitchen closes)
   Network       = Kitchen pass-through window (containers talk to each other)
   
   You can run 10 containers from 1 image,
   just like cooking 10 dishes from 1 recipe!
```

### Container vs Virtual Machine
```
  🖥️ VM (Virtual Machine)           📦 Container (Docker)
  ┌────────────────────┐          ┌────────────────────┐
  │  Your App          │          │  Your App          │
  │  Libraries         │          │  Libraries         │
  │  Full OS (Ubuntu)  │  ← HEAVY │  (Shared OS kernel)│ ← LIGHT
  │  Virtual Hardware  │          │                    │
  └────────────────────┘          └────────────────────┘
  Size: 1-20 GB                   Size: 50-500 MB
  Boot: 30-60 seconds             Boot: 1-3 seconds
  RAM: 512MB-8GB overhead         RAM: ~10MB overhead
  
  VM = Renting an entire house (own plumbing, electricity)
  Container = Renting an apartment (shared building services)
```

### Real-World Cost Impact
| Metric | Without Docker | With Docker |
|--------|---------------|-------------|
| Server setup time | 2-4 hours | 30 seconds |
| "Works on my machine" bugs | Weekly | Never |
| Servers needed (same traffic) | 10 VMs | 3 container hosts |
| Monthly AWS cost | $5,000 | $1,500 |
| Deploy speed | 30 min | 2 min |

---

## Topics

### Docker Architecture
- Docker daemon, client, registry, images, containers
- Container vs VM — process isolation vs hardware virtualization
- OCI (Open Container Initiative) standards

### Dockerfile Deep Dive
| Instruction | Purpose | Best Practice |
|-------------|---------|---------------|
| `FROM` | Base image | Use specific tags, not `latest` |
| `RUN` | Execute commands | Combine with `&&`, clean up in same layer |
| `COPY` vs `ADD` | Add files | Prefer `COPY` (simpler, predictable) |
| `CMD` vs `ENTRYPOINT` | Default command | `ENTRYPOINT` for tool, `CMD` for defaults |
| `EXPOSE` | Document port | Doesn't publish — just documentation |
| `WORKDIR` | Set working dir | Use absolute paths |
| `USER` | Run as non-root | Always set for production |
| `ARG` vs `ENV` | Variables | `ARG` build-time, `ENV` runtime |
| `HEALTHCHECK` | Container health | Always add for production |

### Multi-Stage Builds
```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Production stage
FROM gcr.io/distroless/nodejs20-debian12
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["dist/server.js"]
```

### Docker Networking
| Driver | Scope | Use Case |
|--------|-------|----------|
| **bridge** | Single host | Default, container-to-container |
| **host** | Single host | No network isolation (performance) |
| **none** | Single host | No networking |
| **overlay** | Multi-host | Swarm/multi-node |

### Docker Compose
- Multi-container application definition
- Service dependencies, networks, volumes
- Environment-specific overrides

### Security
- **Distroless images** — minimal attack surface
- **Trivy** — vulnerability scanning
- **Docker Secrets** — sensitive data management
- **Non-root user** — never run as root in production
- **Read-only filesystem** — `--read-only`
- **Resource limits** — `--memory`, `--cpus`

---

## Real-Time Project: Microservices Voting App with Security Scanning

### Architecture
```
┌─────────────────────────────────────────────────┐
│              Docker Compose Setup                 │
│                                                  │
│  ┌──────────┐     ┌──────────┐                  │
│  │  Vote     │     │  Result  │                  │
│  │  (Python) │     │ (Node.js)│                  │
│  │  :5000    │     │  :5001   │                  │
│  └─────┬─────┘     └────┬─────┘                  │
│        │                │                        │
│  ┌─────▼─────┐    ┌────▼──────┐                 │
│  │   Redis   │    │ PostgreSQL │                 │
│  │  (Cache)  │    │ (Storage)  │                 │
│  └─────┬─────┘    └────▲──────┘                 │
│        │               │                        │
│        └───┐    ┌──────┘                        │
│        ┌───▼────▼───┐                           │
│        │   Worker    │                           │
│        │   (.NET)    │                           │
│        └─────────────┘                           │
│                                                  │
│  Trivy: Image scanning                          │
│  ECR: Image registry                            │
│  Secrets: DB credentials via Docker secrets      │
└──────────────────────────────────────────────────┘
```

### Project Files

#### docker-compose.yml
```yaml
version: '3.9'

services:
  vote:
    build:
      context: ./vote
      dockerfile: Dockerfile
    ports:
      - "5000:80"
    networks:
      - frontend
      - backend
    depends_on:
      - redis
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  result:
    build:
      context: ./result
      dockerfile: Dockerfile
    ports:
      - "5001:80"
    networks:
      - frontend
      - backend
    depends_on:
      - db

  worker:
    build:
      context: ./worker
      dockerfile: Dockerfile
    networks:
      - backend
    depends_on:
      - redis
      - db

  redis:
    image: redis:7-alpine
    networks:
      - backend
    volumes:
      - redis-data:/data

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER_FILE: /run/secrets/db_user
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      POSTGRES_DB: votes
    secrets:
      - db_user
      - db_password
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend

secrets:
  db_user:
    file: ./secrets/db_user.txt
  db_password:
    file: ./secrets/db_password.txt

volumes:
  redis-data:
  db-data:

networks:
  frontend:
  backend:
```

#### Trivy Scanning
```bash
# Scan image for vulnerabilities
trivy image --severity HIGH,CRITICAL vote:latest
trivy image --severity HIGH,CRITICAL result:latest

# Scan Dockerfile for misconfigurations
trivy config ./vote/Dockerfile

# Generate report
trivy image --format json --output report.json vote:latest
```

#### Push to ECR
```bash
# Authenticate
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

# Tag and push
docker tag vote:latest ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/vote:v1.0.0
docker push ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/vote:v1.0.0
```

### Deliverables
- [ ] 5-service voting app running via Docker Compose
- [ ] Multi-stage Dockerfiles with distroless base images
- [ ] Trivy scan reports with zero CRITICAL vulnerabilities
- [ ] Docker secrets for database credentials
- [ ] Images pushed to AWS ECR
- [ ] docker-compose.yml with health checks, networks, volumes
- [ ] Image size optimized (< 100MB per service)

---

## Interview Questions
1. Explain Docker image layers and caching
2. `CMD` vs `ENTRYPOINT` — when to use each?
3. How to optimize Docker image size?
4. What are multi-stage builds and why use them?
5. Docker bridge vs host networking?
6. How to scan Docker images for vulnerabilities?
7. What are dangling images and how to clean them?
8. Explain Docker volumes vs bind mounts
9. How to handle secrets in Docker?
10. What is a distroless image?
