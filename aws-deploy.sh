#!/bin/bash

# AWS EKS Deployment Script for Tetris Game
# This script demonstrates cloud deployment skills for the interview

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deploying Tetris Game to AWS EKS${NC}"
echo -e "${YELLOW}This demonstrates: Kubernetes + Cloud Deployment + Observability${NC}"
echo ""

# Configuration
CLUSTER_NAME="tetris-game-cluster"
REGION="us-west-2"
NODE_GROUP_NAME="tetris-nodes"
ECR_REPO_BACKEND="tetris-backend"
ECR_REPO_FRONTEND="tetris-frontend"

# Check prerequisites
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not installed. Please install it first.${NC}"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not installed. Please install it first.${NC}"
    exit 1
fi

if ! command -v eksctl &> /dev/null; then
    echo -e "${RED}❌ eksctl not installed. Installing...${NC}"
    # Install eksctl
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not installed. Please install Docker first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites met${NC}"

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${BLUE}📋 AWS Account ID: ${ACCOUNT_ID}${NC}"

# Step 1: Create ECR repositories
echo -e "${YELLOW}📦 Creating ECR repositories...${NC}"

aws ecr create-repository --repository-name $ECR_REPO_BACKEND --region $REGION 2>/dev/null || echo "Backend repo already exists"
aws ecr create-repository --repository-name $ECR_REPO_FRONTEND --region $REGION 2>/dev/null || echo "Frontend repo already exists"

# Get ECR login
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

echo -e "${GREEN}✅ ECR repositories ready${NC}"

# Step 2: Build and push Docker images
echo -e "${YELLOW}🔨 Building and pushing Docker images...${NC}"

# Build backend
docker build -t $ECR_REPO_BACKEND:latest ./backend
docker tag $ECR_REPO_BACKEND:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_BACKEND:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_BACKEND:latest

# Build frontend
docker build -t $ECR_REPO_FRONTEND:latest ./frontend
docker tag $ECR_REPO_FRONTEND:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_FRONTEND:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_FRONTEND:latest

echo -e "${GREEN}✅ Docker images pushed to ECR${NC}"

# Step 3: Create EKS cluster
echo -e "${YELLOW}☸️  Creating EKS cluster (this takes 10-15 minutes)...${NC}"

eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --nodegroup-name $NODE_GROUP_NAME \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed \
  --with-oidc \
  --ssh-access \
  --ssh-public-key ~/.ssh/id_rsa.pub 2>/dev/null || true

echo -e "${GREEN}✅ EKS cluster created${NC}"

# Step 4: Update kubeconfig
kubectl config current-context

# Step 5: Install AWS Load Balancer Controller
echo -e "${YELLOW}🔧 Installing AWS Load Balancer Controller...${NC}"

# Create IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json

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
  --approve 2>/dev/null || echo "Service account already exists"

# Install controller
kubectl apply \
    --validate=false \
    -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml

kubectl apply -f https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.4.4/v2_4_4_full.yaml

kubectl patch deployment aws-load-balancer-controller \
    -n kube-system \
    -p '{"spec":{"template":{"spec":{"containers":[{"name":"controller","args":["--v=2","--cluster-name='$CLUSTER_NAME'","--ingress-class=alb","--aws-region='$REGION'"]}]}}}}'

echo -e "${GREEN}✅ AWS Load Balancer Controller installed${NC}"

echo -e "${BLUE}🎉 AWS EKS setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update k8s manifests with ECR image URLs"
echo "2. Deploy the application"
echo "3. Set up observability"
echo ""
echo -e "${GREEN}Cluster info:${NC}"
echo "Cluster name: $CLUSTER_NAME"
echo "Region: $REGION"
echo "Backend image: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_BACKEND:latest"
echo "Frontend image: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_FRONTEND:latest"
