# 🎮 Tetris Game Deployment Guide

This guide covers multiple deployment options for the Tetris Game application.

## 🏗️ Architecture

- **Frontend**: React + Vite + TypeScript (served via Nginx)
- **Backend**: FastAPI + Python (Tetris game logic)
- **Database**: None (stateless application)

## 🚀 Deployment Options

### 1. Kubernetes (Recommended for Production)

#### Prerequisites
- Docker installed
- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured
- NGINX Ingress Controller installed

#### Quick Deploy
```bash
# Linux/Mac
./deploy.sh

# Windows PowerShell
.\deploy.ps1
```

#### Manual Deploy
```bash
# Build images
docker build -t tetris-backend:latest ./backend
docker build -t tetris-frontend:latest ./frontend

# Deploy to Kubernetes
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/ingress.yaml

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s deployment/tetris-backend -n tetris-game
kubectl wait --for=condition=available --timeout=300s deployment/tetris-frontend -n tetris-game
```

#### Access the Application
```bash
# Option 1: Port forward (easiest)
kubectl port-forward svc/tetris-frontend-service 3000:80 -n tetris-game
# Visit: http://localhost:3000

# Option 2: Ingress (production)
# Add to /etc/hosts: <INGRESS_IP> tetris.local
# Visit: http://tetris.local
```

#### Monitoring
```bash
# Check status
kubectl get pods -n tetris-game
kubectl get services -n tetris-game

# View logs
kubectl logs -f deployment/tetris-backend -n tetris-game
kubectl logs -f deployment/tetris-frontend -n tetris-game

# Scale deployment
kubectl scale deployment tetris-backend --replicas=3 -n tetris-game
```

#### Cleanup
```bash
# Linux/Mac
./undeploy.sh

# Windows PowerShell
.\undeploy.ps1

# Manual cleanup
kubectl delete namespace tetris-game
```

### 2. Vercel + Railway/Render

#### Frontend (Vercel)
1. Push code to GitHub
2. Connect repository to Vercel
3. Set environment variables:
   ```
   VITE_API_BASE_URL=https://your-backend-url.com
   ```
4. Deploy automatically

#### Backend (Railway)
1. Connect GitHub repository to Railway
2. Select backend folder as root
3. Railway will auto-detect Python and deploy
4. Set custom domain if needed

### 3. Docker Compose (Local Development)

```yaml
# docker-compose.yml
version: '3.8'
services:
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      - HOST=0.0.0.0
      - PORT=8000

  frontend:
    build: ./frontend
    ports:
      - "3000:80"
    environment:
      - VITE_API_BASE_URL=http://localhost:8000
    depends_on:
      - backend
```

```bash
# Deploy
docker-compose up -d

# Cleanup
docker-compose down
```

### 4. Cloud Providers

#### AWS EKS
```bash
# Create EKS cluster
eksctl create cluster --name tetris-game --region us-west-2

# Deploy application
kubectl apply -f k8s/
```

#### Google GKE
```bash
# Create GKE cluster
gcloud container clusters create tetris-game --zone us-central1-a

# Deploy application
kubectl apply -f k8s/
```

#### Azure AKS
```bash
# Create AKS cluster
az aks create --resource-group myResourceGroup --name tetris-game

# Deploy application
kubectl apply -f k8s/
```

## 🔧 Configuration

### Environment Variables

#### Frontend
- `VITE_API_BASE_URL`: Backend API URL (default: http://localhost:8000)

#### Backend
- `HOST`: Server host (default: 0.0.0.0)
- `PORT`: Server port (default: 8000)

### Kubernetes Resources

#### Resource Limits
- **Backend**: 256Mi memory, 200m CPU
- **Frontend**: 128Mi memory, 100m CPU

#### Scaling
- **Backend**: 2 replicas (can scale based on load)
- **Frontend**: 2 replicas (can scale based on traffic)

## 🔍 Troubleshooting

### Common Issues

1. **Images not found**
   ```bash
   # Ensure images are built
   docker images | grep tetris
   ```

2. **Pods not starting**
   ```bash
   kubectl describe pod <pod-name> -n tetris-game
   kubectl logs <pod-name> -n tetris-game
   ```

3. **Service not accessible**
   ```bash
   kubectl get svc -n tetris-game
   kubectl port-forward svc/tetris-frontend-service 3000:80 -n tetris-game
   ```

4. **CORS issues**
   - Check API_BASE_URL configuration
   - Verify ingress annotations

### Health Checks
- Backend: `GET /` (returns {"message": "Tetris Game Backend"})
- Frontend: `GET /` (returns HTML page)

## 📊 Monitoring & Observability

### Metrics
```bash
# Install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# View resource usage
kubectl top pods -n tetris-game
kubectl top nodes
```

### Logging
```bash
# Centralized logging with ELK stack or similar
# View application logs
kubectl logs -f deployment/tetris-backend -n tetris-game --tail=100
```

## 🔐 Security

### Best Practices
- Use non-root containers
- Set resource limits
- Enable network policies
- Use secrets for sensitive data
- Regular security scans

### HTTPS/TLS
```yaml
# Add to ingress.yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - tetris.yourdomain.com
    secretName: tetris-tls
```

## 🚀 CI/CD Pipeline

### GitHub Actions Example
```yaml
name: Deploy to Kubernetes
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Build and Deploy
      run: |
        docker build -t tetris-backend:${{ github.sha }} ./backend
        docker build -t tetris-frontend:${{ github.sha }} ./frontend
        # Push to registry and deploy
```

## 📈 Performance Optimization

### Frontend
- Enable gzip compression (configured in nginx.conf)
- Cache static assets
- Use CDN for global distribution

### Backend
- Horizontal pod autoscaling
- Connection pooling
- Caching strategies

### Database (if added)
- Read replicas
- Connection pooling
- Query optimization
