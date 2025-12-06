# AWS EKS Deployment Script
# This demonstrates: Kubernetes + Cloud Deployment

param(
    [string]$Region = "us-west-2",
    [string]$ClusterName = "tetris-game-cluster"
)

Write-Host "🎮 AWS EKS Deployment for Tetris Game" -ForegroundColor Blue
Write-Host "Demonstrating: Kubernetes + Cloud Deployment" -ForegroundColor Yellow
Write-Host ""

# Get AWS account ID
$AccountId = aws sts get-caller-identity --query Account --output text
if (!$AccountId) {
    Write-Host "❌ Failed to get AWS account ID. Please configure AWS CLI." -ForegroundColor Red
    exit 1
}

Write-Host "📋 AWS Account ID: $AccountId" -ForegroundColor Blue
Write-Host "🌍 Region: $Region" -ForegroundColor Blue
Write-Host "☸️  Cluster: $ClusterName" -ForegroundColor Blue
Write-Host ""

# Step 1: Update Kubernetes manifests with actual ECR URLs
Write-Host "📝 Updating Kubernetes manifests with ECR image URLs..." -ForegroundColor Yellow

$BackendImage = "$AccountId.dkr.ecr.$Region.amazonaws.com/tetris-backend:latest"
$FrontendImage = "$AccountId.dkr.ecr.$Region.amazonaws.com/tetris-frontend:latest"

# Update backend deployment
$backendContent = Get-Content "k8s/aws-backend-deployment.yaml" -Raw
$backendContent = $backendContent -replace "ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/tetris-backend:latest", $BackendImage
$backendContent | Set-Content "k8s/aws-backend-deployment-updated.yaml"

# Update frontend deployment
$frontendContent = Get-Content "k8s/aws-frontend-deployment.yaml" -Raw
$frontendContent = $frontendContent -replace "ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/tetris-frontend:latest", $FrontendImage
$frontendContent | Set-Content "k8s/aws-frontend-deployment-updated.yaml"

Write-Host "✅ Manifests updated" -ForegroundColor Green

# Step 2: Deploy to Kubernetes
Write-Host "🚀 Deploying to EKS cluster..." -ForegroundColor Yellow

# Create namespace
kubectl apply -f k8s/namespace.yaml

# Deploy applications
kubectl apply -f k8s/aws-backend-deployment-updated.yaml
kubectl apply -f k8s/aws-frontend-deployment-updated.yaml

# Deploy ingress
kubectl apply -f k8s/aws-ingress.yaml

Write-Host "✅ Applications deployed" -ForegroundColor Green

# Step 3: Wait for deployments
Write-Host "⏳ Waiting for deployments to be ready..." -ForegroundColor Yellow

kubectl wait --for=condition=available --timeout=300s deployment/tetris-backend -n tetris-game
kubectl wait --for=condition=available --timeout=300s deployment/tetris-frontend -n tetris-game

Write-Host "✅ All deployments ready!" -ForegroundColor Green

# Step 4: Get ingress URL
Write-Host "🌐 Getting application URL..." -ForegroundColor Yellow

$IngressUrl = ""
$attempts = 0
while ($attempts -lt 30 -and !$IngressUrl) {
    $IngressUrl = kubectl get ingress tetris-ingress -n tetris-game -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
    if (!$IngressUrl) {
        Write-Host "Waiting for load balancer... ($attempts/30)" -ForegroundColor Gray
        Start-Sleep 10
        $attempts++
    }
}

# Step 5: Display results
Write-Host ""
Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Blue
Write-Host ""

# Application URLs
if ($IngressUrl) {
    Write-Host "🌐 Application URL: http://$IngressUrl" -ForegroundColor Green
    Write-Host "🔧 API URL: http://$IngressUrl/api" -ForegroundColor Green
} else {
    Write-Host "⚠️  Load balancer URL not ready yet. Check in a few minutes:" -ForegroundColor Yellow
    Write-Host "   kubectl get ingress tetris-ingress -n tetris-game" -ForegroundColor Gray
}



Write-Host ""
Write-Host "🔍 Useful Commands:" -ForegroundColor Yellow
Write-Host "   # Check pod status" -ForegroundColor Gray
Write-Host "   kubectl get pods -n tetris-game" -ForegroundColor Gray
Write-Host ""
Write-Host "   # View logs" -ForegroundColor Gray
Write-Host "   kubectl logs -f deployment/tetris-backend -n tetris-game" -ForegroundColor Gray
Write-Host "   kubectl logs -f deployment/tetris-frontend -n tetris-game" -ForegroundColor Gray
Write-Host ""
Write-Host "   # Scale applications" -ForegroundColor Gray
Write-Host "   kubectl scale deployment tetris-backend --replicas=3 -n tetris-game" -ForegroundColor Gray

Write-Host ""
Write-Host "💰 Cost Management:" -ForegroundColor Yellow
Write-Host "   # To save costs, scale down when not in use:" -ForegroundColor Gray
Write-Host "   kubectl scale deployment tetris-backend --replicas=1 -n tetris-game" -ForegroundColor Gray
Write-Host "   kubectl scale deployment tetris-frontend --replicas=1 -n tetris-game" -ForegroundColor Gray

Write-Host ""
Write-Host "🧹 Cleanup (when done):" -ForegroundColor Yellow
Write-Host "   # Delete applications" -ForegroundColor Gray
Write-Host "   kubectl delete namespace tetris-game" -ForegroundColor Gray
Write-Host "   # Delete cluster" -ForegroundColor Gray
Write-Host "   eksctl delete cluster --name $ClusterName --region $Region" -ForegroundColor Gray

Write-Host ""
Write-Host "🎯 Skills Demonstrated:" -ForegroundColor Blue
Write-Host "✅ Python application development" -ForegroundColor Green
Write-Host "✅ Kubernetes deployment and management" -ForegroundColor Green
Write-Host "✅ Cloud deployment (AWS EKS)" -ForegroundColor Green
Write-Host "✅ Container orchestration" -ForegroundColor Green
Write-Host "✅ Load balancing with AWS ALB" -ForegroundColor Green
