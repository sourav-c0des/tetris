# 🚀 Complete AWS Deployment Guide

## Option 1: AWS CloudShell (Recommended - No local setup needed)

### Step 1: Access AWS CloudShell
1. Go to https://console.aws.amazon.com/
2. Sign in with your Amazon account
3. Click the **CloudShell icon** (terminal icon) in the top navigation bar
4. Wait for CloudShell to initialize (takes 1-2 minutes)

### Step 2: Upload Your Code
1. In CloudShell, click **Actions** → **Upload file**
2. Create a zip file of your `drw-tetris` folder
3. Upload the zip file
4. Extract it: `unzip drw-tetris.zip && cd drw-tetris`

### Step 3: Run Deployment Scripts
```bash
# Make scripts executable
chmod +x cloudshell-deploy.sh cloudshell-app-deploy.sh

# Step 1: Setup infrastructure (15-20 minutes)
./cloudshell-deploy.sh

# Step 2: Deploy application (5-10 minutes)
./cloudshell-app-deploy.sh
```

### Step 4: Access Your Application
- The script will output your application URL
- Visit the URL to see your Tetris game live!

---

## Option 2: Local Deployment (If AWS CLI works)

### Step 1: Configure AWS CLI
```powershell
# Restart PowerShell first, then:
aws configure
# Enter your:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region: us-west-2
# - Default output format: json
```

### Step 2: Run Local Scripts
```powershell
# Setup ECR and build images
.\aws-deploy.ps1

# Deploy to EKS
.\deploy-to-aws.ps1
```

---

## Option 3: Free Alternative (No AWS costs)

If you want to avoid AWS costs for now:

### Frontend: Vercel
1. Push your code to GitHub
2. Go to https://vercel.com/
3. Connect your GitHub repository
4. Set environment variable: `VITE_API_BASE_URL=https://your-backend-url.railway.app`
5. Deploy automatically

### Backend: Railway
1. Go to https://railway.app/
2. Connect your GitHub repository
3. Select the `backend` folder as root
4. Deploy automatically

---

## 💰 Cost Estimation (AWS)

**Hourly costs:**
- EKS Cluster: $0.10/hour
- EC2 Nodes (2x t3.medium): $0.16/hour
- Load Balancer: $0.025/hour
- **Total: ~$0.285/hour**

**For a 4-hour demo: ~$1.14**

**Important:** Remember to cleanup resources when done!

---

## 🧹 Cleanup (Important!)

### AWS CloudShell:
```bash
# Delete applications
kubectl delete namespace tetris-game

# Delete cluster (saves most costs)
eksctl delete cluster --name tetris-game-cluster --region us-west-2

# Delete ECR repositories
aws ecr delete-repository --repository-name tetris-backend --region us-west-2 --force
aws ecr delete-repository --repository-name tetris-frontend --region us-west-2 --force
```

### Local:
```powershell
# Use the cleanup commands from the deployment script output
```

---

## 🎯 What This Demonstrates

✅ **Python Development** - FastAPI backend with game logic
✅ **Kubernetes** - Production deployments, services, ingress
✅ **Cloud Deployment** - AWS EKS, ECR, ALB
✅ **Container Orchestration** - Docker, multi-stage builds
✅ **Infrastructure as Code** - Automated deployment scripts
✅ **Networking** - Load balancing, ingress configuration

---

## 🚨 Troubleshooting

### If deployment fails:
```bash
# Check pod status
kubectl get pods -n tetris-game

# Check logs
kubectl logs deployment/tetris-backend -n tetris-game
kubectl logs deployment/tetris-frontend -n tetris-game

# Check ingress
kubectl describe ingress tetris-ingress -n tetris-game
```

### If load balancer takes too long:
```bash
# Use port-forward for testing
kubectl port-forward svc/tetris-frontend-service 8080:80 -n tetris-game
# Then access: http://localhost:8080
```

---

## 📞 Next Steps

1. **Choose your deployment method** (CloudShell recommended)
2. **Follow the steps** for your chosen method
3. **Test your application** 
4. **Cleanup resources** when done
5. **Document your experience** for the interview

**The application will be live on the internet, demonstrating your cloud deployment skills!**
