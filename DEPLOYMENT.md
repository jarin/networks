# NetLang Deployment Guide

## Quick Start with mise

```bash
# Build TypeScript and Zig server
mise run all

# Run the server
mise run run

# Or build and run in one command
mise run dev
```

## Docker Deployment

### Build and Run Locally

```bash
# Build Docker image
mise run docker:build

# Run Docker container
mise run docker:run

# Or do both
mise run docker:build-run
```

### Manual Docker Commands

```bash
# Build
docker build -t netlang:latest .

# Run
docker run -p 8080:8080 netlang:latest

# Run with custom port
docker run -p 3000:8080 netlang:latest
```

## Production Deployment Options

### 1. DigitalOcean App Platform

**Easiest option - fully managed PaaS**

#### Setup Steps:

1. **Push to GitHub**
   ```bash
   git push origin main
   ```

2. **Create App in DigitalOcean**
   - Go to [DigitalOcean App Platform](https://cloud.digitalocean.com/apps)
   - Click "Create App"
   - Connect your GitHub repository
   - Select the repository and branch

3. **Configure App**
   ```yaml
   # App Spec (DigitalOcean will auto-detect Dockerfile)
   name: netlang
   services:
   - name: web
     dockerfile_path: Dockerfile
     github:
       repo: <your-username>/<repo-name>
       branch: main
       deploy_on_push: true
     health_check:
       http_path: /health
     http_port: 8080
     instance_count: 1
     instance_size_slug: basic-xxs  # $5/month
     routes:
     - path: /
   ```

4. **Environment Variables** (if needed)
   - Set in App Platform dashboard
   - Or via doctl CLI

5. **Deploy**
   - App Platform auto-deploys on git push
   - Monitor at: https://cloud.digitalocean.com/apps

**Cost**: Starting at $5/month (basic-xxs)

**Pros**:
- Zero DevOps overhead
- Auto-scaling
- Free SSL/TLS
- GitHub integration
- Rolling deployments

**Cons**:
- Less control than VPS
- Slightly more expensive for simple apps

---

### 2. DigitalOcean Droplet (VPS)

**More control, lower cost**

#### Setup Steps:

1. **Create Droplet**
   ```bash
   # Using doctl CLI
   doctl compute droplet create netlang \
     --image docker-20-04 \
     --size s-1vcpu-1gb \
     --region nyc1 \
     --ssh-keys <your-ssh-key-id>
   ```

2. **SSH into Droplet**
   ```bash
   ssh root@<droplet-ip>
   ```

3. **Install Docker** (if not using docker image)
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   ```

4. **Pull and Run Container**
   ```bash
   # Using GitHub Container Registry
   docker login ghcr.io -u <github-username>
   docker pull ghcr.io/<username>/<repo>:latest
   docker run -d -p 80:8080 --restart=unless-stopped \
     --name netlang ghcr.io/<username>/<repo>:latest
   ```

5. **Set up Nginx Reverse Proxy** (optional)
   ```nginx
   # /etc/nginx/sites-available/netlang
   server {
       listen 80;
       server_name your-domain.com;

       location / {
           proxy_pass http://localhost:8080;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }

       location /health {
           proxy_pass http://localhost:8080/health;
       }
   }
   ```

6. **Enable SSL with Certbot**
   ```bash
   apt-get install certbot python3-certbot-nginx
   certbot --nginx -d your-domain.com
   ```

**Cost**: $6/month (1GB RAM droplet)

**Pros**:
- Full control
- Lower cost
- Can run multiple apps

**Cons**:
- Manual setup
- You manage updates/security

---

### 3. Hetzner Cloud

**Best price/performance ratio**

#### Setup Steps:

1. **Create Server**
   ```bash
   # Using hcloud CLI
   hcloud server create \
     --name netlang \
     --type cx11 \
     --image docker-ce \
     --location nbg1
   ```

2. **SSH into Server**
   ```bash
   ssh root@<server-ip>
   ```

3. **Deploy Container**
   ```bash
   docker pull ghcr.io/<username>/<repo>:latest
   docker run -d -p 80:8080 --restart=unless-stopped \
     --name netlang ghcr.io/<username>/<repo>:latest
   ```

4. **Optional: Use docker-compose**
   ```yaml
   # docker-compose.yml
   version: '3.8'
   services:
     netlang:
       image: ghcr.io/<username>/<repo>:latest
       ports:
         - "80:8080"
       restart: unless-stopped
       healthcheck:
         test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
         interval: 30s
         timeout: 3s
         retries: 3
   ```

   ```bash
   docker-compose up -d
   ```

**Cost**: €4.15/month (CX11 - 2GB RAM)

**Pros**:
- Cheapest option
- Great performance
- EU data centers
- Excellent network

**Cons**:
- Manual setup
- No managed services

---

## GitHub Actions Auto-Deployment

### DigitalOcean App Platform

The included workflow automatically builds and pushes to GitHub Container Registry. Connect your DigitalOcean app to auto-deploy:

1. Enable GitHub Container Registry in your repo settings
2. Create DigitalOcean App from GitHub repo
3. Every push to `main` triggers a build and deploy

### DigitalOcean Droplet/Hetzner (Manual Deploy)

Add deployment step to `.github/workflows/build.yml`:

```yaml
- name: Deploy to VPS
  if: github.ref == 'refs/heads/main'
  env:
    SSH_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
    HOST: ${{ secrets.VPS_HOST }}
  run: |
    echo "$SSH_KEY" > deploy_key
    chmod 600 deploy_key
    ssh -i deploy_key -o StrictHostKeyChecking=no root@$HOST << 'EOF'
      docker pull ghcr.io/${{ github.repository }}:latest
      docker stop netlang || true
      docker rm netlang || true
      docker run -d -p 80:8080 --restart=unless-stopped \
        --name netlang ghcr.io/${{ github.repository }}:latest
    EOF
```

**Required Secrets** (Add in GitHub repo settings):
- `SSH_PRIVATE_KEY`: Your SSH private key
- `VPS_HOST`: Your VPS IP address

---

## Health Checks

The server exposes two endpoints for monitoring:

- **Liveness**: `GET /health` - Returns 200 if server is running
  ```json
  {"status":"ok","nodes":15,"uptime":"healthy"}
  ```

- **Readiness**: `GET /ready` - Returns 200 if server is ready
  ```json
  {"status":"ready"}
  ```

Use these in your deployment platform:
- **Kubernetes**: livenessProbe & readinessProbe
- **DigitalOcean**: Health check path: `/health`
- **Docker**: HEALTHCHECK instruction (already in Dockerfile)

---

## Monitoring & Logs

### Docker Logs
```bash
# View logs
docker logs netlang

# Follow logs
docker logs -f netlang

# Last 100 lines
docker logs --tail 100 netlang
```

### DigitalOcean App Platform
- View logs in dashboard: Apps → netlang → Runtime Logs
- Or use `doctl`:
  ```bash
  doctl apps logs <app-id> --type=run
  ```

### Metrics
For production monitoring, integrate:
- **Prometheus**: Scrape `/health` endpoint
- **Datadog**: Use agent in container
- **DigitalOcean Monitoring**: Built-in (App Platform)

---

## Scaling

### Vertical Scaling (More Resources)
- **DO App Platform**: Change instance size in dashboard
- **DO Droplet**: Resize droplet (requires reboot)
- **Hetzner**: Upgrade server type

### Horizontal Scaling (More Instances)
- **DO App Platform**: Increase instance count
- **Droplet/Hetzner**: Use load balancer + multiple droplets

---

## Cost Comparison

| Provider | Option | Cost/Month | RAM | vCPU | Notes |
|----------|--------|------------|-----|------|-------|
| DigitalOcean | App Platform (basic-xxs) | $5 | 512MB | 1 | Fully managed, auto-deploy |
| DigitalOcean | Droplet (s-1vcpu-1gb) | $6 | 1GB | 1 | Self-managed, more control |
| Hetzner | CX11 | €4.15 | 2GB | 1 | Best value, EU only |
| Hetzner | CPX11 | €4.75 | 2GB | 2 | Dedicated vCPU |

**Recommendation**:
- **Learning/Demo**: DigitalOcean App Platform (easiest)
- **Production**: Hetzner CX11 (best value)
- **High Traffic**: DigitalOcean App Platform with scaling

---

## Quick Deploy Commands

```bash
# Development
mise run dev

# Production build
mise run build

# Docker local
mise run docker:build-run

# Test health
mise run test-health
```
