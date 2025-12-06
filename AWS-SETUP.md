# 🚀 AWS EKS Deployment Setup

## Prerequisites

### 1. Install AWS CLI
```powershell
# Download and install from: https://aws.amazon.com/cli/
# Or use chocolatey:
choco install awscli

# Verify installation
aws --version
```

### 2. Configure AWS Credentials
```powershell
aws configure
# Enter your:
# - AWS Access Key ID
# - AWS Secret Access Key  
# - Default region: us-west-2
# - Default output format: json
```

### 3. Install eksctl (optional)
```powershell
# Download from: https://github.com/weaveworks/eksctl/releases
# Or use chocolatey:
choco install eksctl
```

## Quick Deployment

### Option 1: Automated (Recommended)
```powershell
# 1. Setup ECR and build images
.\aws-deploy.ps1

# 2. Deploy to EKS
.\deploy-to-aws.ps1
```

### Option 2: Manual Steps

#### Step 1: Create ECR Repositories
```powershell
aws ecr create-repository --repository-name tetris-backend --region us-west-2
aws ecr create-repository --repository-name tetris-frontend --region us-west-2
```

#### Step 2: Build and Push Images
```powershell
# Get account ID
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text

# Login to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com"

# Build and push backend
docker build -t tetris-backend:latest ./backend
docker tag tetris-backend:latest "$ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/tetris-backend:latest"
docker push "$ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/tetris-backend:latest"

# Build and push frontend
docker build -t tetris-frontend:latest ./frontend
docker tag tetris-frontend:latest "$ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/tetris-frontend:latest"
docker push "$ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/tetris-frontend:latest"
```

#### Step 3: Create EKS Cluster
```powershell
# Using eksctl (easiest)
eksctl create cluster --name tetris-game-cluster --region us-west-2 --nodes 2

# Or use AWS Console to create cluster manually
```

#### Step 4: Deploy Application
```powershell
# Update image URLs in manifests
# Then deploy:
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/aws-backend-deployment.yaml
kubectl apply -f k8s/aws-frontend-deployment.yaml
kubectl apply -f k8s/aws-ingress.yaml
```

## Access the Application

```powershell
# Get load balancer URL
kubectl get ingress tetris-ingress -n tetris-game

# Or use port-forward for testing
kubectl port-forward svc/tetris-frontend-service 3000:80 -n tetris-game
```

## Cleanup (Important for Cost)

```powershell
# Delete applications
kubectl delete namespace tetris-game

# Delete cluster
eksctl delete cluster --name tetris-game-cluster --region us-west-2

# Delete ECR repositories
aws ecr delete-repository --repository-name tetris-backend --region us-west-2 --force
aws ecr delete-repository --repository-name tetris-frontend --region us-west-2 --force
```

## Cost Estimation

- **EKS Cluster**: ~$0.10/hour ($72/month)
- **EC2 Nodes**: 2 x t3.medium ~$0.08/hour each ($115/month)
- **Load Balancer**: ~$0.025/hour ($18/month)
- **Total**: ~$205/month

**For demo purposes, run for a few hours then cleanup to minimize costs.**

## Alternative: Free Deployment

If you want to avoid AWS costs, use:

```powershell
# Deploy to free services
# 1. Push to GitHub
git add .
git commit -m "Add AWS deployment"
git push origin main

# 2. Deploy frontend to Vercel (free)
# 3. Deploy backend to Railway (free)
```

This still demonstrates the same Kubernetes and cloud deployment skills!
