#!/bin/bash

# AWS CloudShell Deployment Script for Tetris Game
# Run this in AWS CloudShell

set -e

echo "🎮 Deploying Tetris Game to AWS"
echo "================================"

# Configuration
REGION="us-west-2"
CLUSTER_NAME="tetris-game-cluster"
ECR_REPO_BACKEND="tetris-backend"
ECR_REPO_FRONTEND="tetris-frontend"

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "📋 AWS Account ID: $ACCOUNT_ID"
echo "🌍 Region: $REGION"

# Step 1: Create ECR repositories
echo ""
echo "📦 Creating ECR repositories..."
aws ecr create-repository --repository-name $ECR_REPO_BACKEND --region $REGION 2>/dev/null || echo "Backend repo already exists"
aws ecr create-repository --repository-name $ECR_REPO_FRONTEND --region $REGION 2>/dev/null || echo "Frontend repo already exists"

echo "✅ ECR repositories created"

# Step 2: Install kubectl
echo ""
echo "🔧 Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Step 3: Install eksctl
echo ""
echo "🔧 Installing eksctl..."
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

echo "✅ Tools installed"

# Step 4: Create EKS cluster
echo ""
echo "☸️  Creating EKS cluster (this takes 15-20 minutes)..."
eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --nodegroup-name tetris-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed

echo "✅ EKS cluster created"

# Step 5: Install AWS Load Balancer Controller
echo ""
echo "🔧 Installing AWS Load Balancer Controller..."

# Download IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json

# Create IAM policy
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json 2>/dev/null || echo "Policy already exists"

# Create service account
eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name "AmazonEKSLoadBalancerControllerRole" \
  --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Install cert-manager
kubectl apply \
    --validate=false \
    -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml

# Install AWS Load Balancer Controller
kubectl apply -f https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.4.4/v2_4_4_full.yaml

# Patch the deployment
kubectl patch deployment aws-load-balancer-controller \
    -n kube-system \
    -p '{"spec":{"template":{"spec":{"containers":[{"name":"controller","args":["--v=2","--cluster-name='$CLUSTER_NAME'","--ingress-class=alb","--aws-region='$REGION'"]}]}}}}'

echo "✅ AWS Load Balancer Controller installed"

echo ""
echo "🎉 Infrastructure setup complete!"
echo ""
echo "Next steps:"
echo "1. Upload your code to CloudShell"
echo "2. Build and push Docker images"
echo "3. Deploy the application"
echo ""
echo "Cluster info:"
echo "- Cluster name: $CLUSTER_NAME"
echo "- Region: $REGION"
echo "- Backend ECR: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_BACKEND"
echo "- Frontend ECR: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_FRONTEND"
