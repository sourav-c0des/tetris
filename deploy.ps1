# Tetris Game Kubernetes Deployment Script (PowerShell)
param(
    [switch]$SkipBuild
)

Write-Host "🎮 Deploying Tetris Game to Kubernetes..." -ForegroundColor Green

# Check if kubectl is installed
if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ kubectl is not installed. Please install kubectl first." -ForegroundColor Red
    exit 1
}

# Check if Docker is installed
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker is not installed. Please install Docker first." -ForegroundColor Red
    exit 1
}

if (!$SkipBuild) {
    # Build Docker images
    Write-Host "🔨 Building Docker images..." -ForegroundColor Yellow

    Write-Host "Building backend image..."
    docker build -t tetris-backend:latest ./backend
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to build backend image" -ForegroundColor Red
        exit 1
    }

    Write-Host "Building frontend image..."
    docker build -t tetris-frontend:latest ./frontend
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to build frontend image" -ForegroundColor Red
        exit 1
    }

    Write-Host "✅ Docker images built successfully" -ForegroundColor Green
}

# Apply Kubernetes manifests
Write-Host "🚀 Deploying to Kubernetes..." -ForegroundColor Yellow

# Create namespace
kubectl apply -f k8s/namespace.yaml

# Deploy backend
kubectl apply -f k8s/backend-deployment.yaml

# Deploy frontend
kubectl apply -f k8s/frontend-deployment.yaml

# Deploy ingress
kubectl apply -f k8s/ingress.yaml

Write-Host "✅ Kubernetes deployment completed" -ForegroundColor Green

# Wait for deployments to be ready
Write-Host "⏳ Waiting for deployments to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=300s deployment/tetris-backend -n tetris-game
kubectl wait --for=condition=available --timeout=300s deployment/tetris-frontend -n tetris-game

Write-Host "✅ All deployments are ready!" -ForegroundColor Green

# Show status
Write-Host "📊 Deployment Status:" -ForegroundColor Yellow
kubectl get pods -n tetris-game
kubectl get services -n tetris-game
kubectl get ingress -n tetris-game

Write-Host ""
Write-Host "🎉 Tetris Game deployed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "To access the application:"
Write-Host "1. Add 'tetris.local' to your hosts file pointing to your ingress IP"
Write-Host "2. Or use port-forward: kubectl port-forward svc/tetris-frontend-service 3000:80 -n tetris-game"
Write-Host "3. Then visit: http://localhost:3000"
Write-Host ""
Write-Host "To check logs:"
Write-Host "  Backend:  kubectl logs -f deployment/tetris-backend -n tetris-game"
Write-Host "  Frontend: kubectl logs -f deployment/tetris-frontend -n tetris-game"
