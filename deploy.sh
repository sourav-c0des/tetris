#!/bin/bash

# Tetris Game Kubernetes Deployment Script
set -e

echo "🎮 Deploying Tetris Game to Kubernetes..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Build Docker images
echo -e "${YELLOW}🔨 Building Docker images...${NC}"

echo "Building backend image..."
docker build -t tetris-backend:latest ./backend

echo "Building frontend image..."
docker build -t tetris-frontend:latest ./frontend

echo -e "${GREEN}✅ Docker images built successfully${NC}"

# Apply Kubernetes manifests
echo -e "${YELLOW}🚀 Deploying to Kubernetes...${NC}"

# Create namespace
kubectl apply -f k8s/namespace.yaml

# Deploy backend
kubectl apply -f k8s/backend-deployment.yaml

# Deploy frontend
kubectl apply -f k8s/frontend-deployment.yaml

# Deploy ingress
kubectl apply -f k8s/ingress.yaml

echo -e "${GREEN}✅ Kubernetes deployment completed${NC}"

# Wait for deployments to be ready
echo -e "${YELLOW}⏳ Waiting for deployments to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/tetris-backend -n tetris-game
kubectl wait --for=condition=available --timeout=300s deployment/tetris-frontend -n tetris-game

echo -e "${GREEN}✅ All deployments are ready!${NC}"

# Show status
echo -e "${YELLOW}📊 Deployment Status:${NC}"
kubectl get pods -n tetris-game
kubectl get services -n tetris-game
kubectl get ingress -n tetris-game

echo ""
echo -e "${GREEN}🎉 Tetris Game deployed successfully!${NC}"
echo ""
echo "To access the application:"
echo "1. Add 'tetris.local' to your /etc/hosts file pointing to your ingress IP"
echo "2. Or use port-forward: kubectl port-forward svc/tetris-frontend-service 3000:80 -n tetris-game"
echo "3. Then visit: http://localhost:3000"
echo ""
echo "To check logs:"
echo "  Backend:  kubectl logs -f deployment/tetris-backend -n tetris-game"
echo "  Frontend: kubectl logs -f deployment/tetris-frontend -n tetris-game"
