#!/bin/bash

# Deploy Tetris Application to EKS
# Run this after cloudshell-deploy.sh

set -e

echo "🚀 Deploying Tetris Application"
echo "==============================="

# Configuration
REGION="us-west-2"
CLUSTER_NAME="tetris-game-cluster"
ECR_REPO_BACKEND="tetris-backend"
ECR_REPO_FRONTEND="tetris-frontend"

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "📋 Account ID: $ACCOUNT_ID"

# Step 1: Login to ECR
echo ""
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Step 2: Build and push backend
echo ""
echo "🔨 Building backend image..."
docker build -t $ECR_REPO_BACKEND:latest ./backend
docker tag $ECR_REPO_BACKEND:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_BACKEND:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_BACKEND:latest

echo "✅ Backend image pushed"

# Step 3: Build and push frontend
echo ""
echo "🔨 Building frontend image..."
docker build -t $ECR_REPO_FRONTEND:latest ./frontend
docker tag $ECR_REPO_FRONTEND:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_FRONTEND:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_FRONTEND:latest

echo "✅ Frontend image pushed"

# Step 4: Update Kubernetes manifests
echo ""
echo "📝 Updating Kubernetes manifests..."

# Update backend deployment
sed "s|ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/tetris-backend:latest|$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_BACKEND:latest|g" k8s/aws-backend-deployment.yaml > k8s/backend-updated.yaml

# Update frontend deployment
sed "s|ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/tetris-frontend:latest|$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_FRONTEND:latest|g" k8s/aws-frontend-deployment.yaml > k8s/frontend-updated.yaml

echo "✅ Manifests updated"

# Step 5: Deploy to Kubernetes
echo ""
echo "☸️  Deploying to Kubernetes..."

# Create namespace
kubectl apply -f k8s/namespace.yaml

# Deploy backend
kubectl apply -f k8s/backend-updated.yaml

# Deploy frontend
kubectl apply -f k8s/frontend-updated.yaml

# Deploy ingress
kubectl apply -f k8s/aws-ingress.yaml

echo "✅ Application deployed"

# Step 6: Wait for deployments
echo ""
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/tetris-backend -n tetris-game
kubectl wait --for=condition=available --timeout=300s deployment/tetris-frontend -n tetris-game

echo "✅ All deployments ready!"

# Step 7: Get application URL
echo ""
echo "🌐 Getting application URL..."
echo "Waiting for load balancer to be ready..."

for i in {1..30}; do
    INGRESS_URL=$(kubectl get ingress tetris-ingress -n tetris-game -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ ! -z "$INGRESS_URL" ]; then
        break
    fi
    echo "Attempt $i/30: Load balancer not ready yet..."
    sleep 10
done

# Display results
echo ""
echo "🎉 Deployment Complete!"
echo "======================="
echo ""

if [ ! -z "$INGRESS_URL" ]; then
    echo "🌐 Application URL: http://$INGRESS_URL"
    echo "🔧 API URL: http://$INGRESS_URL/api"
else
    echo "⚠️  Load balancer URL not ready yet. Check in a few minutes:"
    echo "   kubectl get ingress tetris-ingress -n tetris-game"
fi

echo ""
echo "📊 Status Commands:"
echo "   kubectl get pods -n tetris-game"
echo "   kubectl get services -n tetris-game"
echo "   kubectl get ingress -n tetris-game"
echo ""
echo "📋 Logs:"
echo "   kubectl logs -f deployment/tetris-backend -n tetris-game"
echo "   kubectl logs -f deployment/tetris-frontend -n tetris-game"
echo ""
echo "🧹 Cleanup (when done):"
echo "   kubectl delete namespace tetris-game"
echo "   eksctl delete cluster --name $CLUSTER_NAME --region $REGION"
