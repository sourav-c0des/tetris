# AWS EKS Deployment Script for Tetris Game (PowerShell)
# This script demonstrates cloud deployment skills for the interview

param(
    [string]$ClusterName = "tetris-game-cluster",
    [string]$Region = "us-west-2"
)

Write-Host "🚀 Deploying Tetris Game to AWS EKS" -ForegroundColor Blue
Write-Host "This demonstrates: Kubernetes + Cloud Deployment + Observability" -ForegroundColor Yellow
Write-Host ""

# Configuration
$NodeGroupName = "tetris-nodes"
$ECRRepoBackend = "tetris-backend"
$ECRRepoFrontend = "tetris-frontend"

# Check prerequisites
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow

if (!(Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "❌ AWS CLI not installed. Please install it first." -ForegroundColor Red
    exit 1
}

if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ kubectl not installed. Please install it first." -ForegroundColor Red
    exit 1
}

if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker not installed. Please install Docker first." -ForegroundColor Red
    exit 1
}

Write-Host "✅ All prerequisites met" -ForegroundColor Green

# Get AWS account ID
$AccountId = aws sts get-caller-identity --query Account --output text
Write-Host "📋 AWS Account ID: $AccountId" -ForegroundColor Blue

# Step 1: Create ECR repositories
Write-Host "📦 Creating ECR repositories..." -ForegroundColor Yellow

try {
    aws ecr create-repository --repository-name $ECRRepoBackend --region $Region 2>$null
} catch {
    Write-Host "Backend repo already exists"
}

try {
    aws ecr create-repository --repository-name $ECRRepoFrontend --region $Region 2>$null
} catch {
    Write-Host "Frontend repo already exists"
}

# Get ECR login
aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin "$AccountId.dkr.ecr.$Region.amazonaws.com"

Write-Host "✅ ECR repositories ready" -ForegroundColor Green

# Step 2: Build and push Docker images
Write-Host "🔨 Building and pushing Docker images..." -ForegroundColor Yellow

# Build backend
docker build -t "${ECRRepoBackend}:latest" ./backend
docker tag "${ECRRepoBackend}:latest" "$AccountId.dkr.ecr.$Region.amazonaws.com/${ECRRepoBackend}:latest"
docker push "$AccountId.dkr.ecr.$Region.amazonaws.com/${ECRRepoBackend}:latest"

# Build frontend  
docker build -t "${ECRRepoFrontend}:latest" ./frontend
docker tag "${ECRRepoFrontend}:latest" "$AccountId.dkr.ecr.$Region.amazonaws.com/${ECRRepoFrontend}:latest"
docker push "$AccountId.dkr.ecr.$Region.amazonaws.com/${ECRRepoFrontend}:latest"

Write-Host "✅ Docker images pushed to ECR" -ForegroundColor Green

# Step 3: Create EKS cluster (if eksctl is available)
if (Get-Command eksctl -ErrorAction SilentlyContinue) {
    Write-Host "☸️  Creating EKS cluster (this takes 10-15 minutes)..." -ForegroundColor Yellow
    
    eksctl create cluster `
      --name $ClusterName `
      --region $Region `
      --nodegroup-name $NodeGroupName `
      --node-type t3.medium `
      --nodes 2 `
      --nodes-min 1 `
      --nodes-max 3 `
      --managed `
      --with-oidc
      
    Write-Host "✅ EKS cluster created" -ForegroundColor Green
} else {
    Write-Host "⚠️  eksctl not found. Please install eksctl to create the cluster automatically." -ForegroundColor Yellow
    Write-Host "Or create the cluster manually in AWS Console." -ForegroundColor Yellow
}

Write-Host "🎉 AWS EKS setup complete!" -ForegroundColor Blue
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Update k8s manifests with ECR image URLs"
Write-Host "2. Deploy the application"
Write-Host "3. Set up observability"
Write-Host ""
Write-Host "Cluster info:" -ForegroundColor Green
Write-Host "Cluster name: $ClusterName"
Write-Host "Region: $Region"
Write-Host "Backend image: $AccountId.dkr.ecr.$Region.amazonaws.com/${ECRRepoBackend}:latest"
Write-Host "Frontend image: $AccountId.dkr.ecr.$Region.amazonaws.com/${ECRRepoFrontend}:latest"
