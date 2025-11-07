# 🚀 Simple CI/CD Pipeline with Docker & ECR - Beginner's Guide

## 👋 Welcome to Simple DevOps!

This guide will teach you how to build a **simple CI/CD pipeline** that automatically deploys a Docker container from ECR (Elastic Container Registry) to EC2. Much simpler than the complex version!

## 🎯 What You'll Learn

By the end of this guide, you'll have:
- ✅ A real e-commerce website running on AWS
- ✅ Docker images stored in AWS ECR
- ✅ Automatic deployments when you change code
- ✅ Simple DevOps skills

## 🏗️ Simple Architecture

```
Your Code → GitHub → CodePipeline → CodeBuild → ECR → CodeDeploy → EC2
    ↓           ↓           ↓           ↓        ↓          ↓
Make Changes  Trigger   Build Image  Store   Deploy    Run Container
```

## 📁 Project Structure

```
cicd-ecommerce-pipeline/
├── 📄 README.md                     # Project documentation
├── 📄 aws-console-guide.md          # This guide
├── 🐳 Dockerfile                    # Docker container recipe
├── 📁 src/                          # Your website files
│   ├── 📁 ecommerce-app/           # Main website
│   │   ├── 🌐 index.html           # Main webpage
│   │   ├── 🎨 styles.css           # Styling
│   │   ├── ⚡ script.js            # JavaScript
│   │   └── 📊 products.json        # Product data
│   └── 📁 config/
│       └── ⚙️ nginx.conf           # Web server config
├── 🔧 buildspec.yml                # Build instructions (simple)
├── 📋 appspec.yml                  # Deploy instructions (simple)
└── 📁 deployment/                   # Deployment scripts
    ├── 🔄 before_install.sh       # Setup Docker
    ├── ▶️ application_start.sh     # Pull & run container
    ├── ⏹️ application_stop.sh      # Stop container
    └── ✅ validate_service.sh      # Check it works
```

## 💡 Prerequisites

- **AWS Account** (free tier)
- **GitHub Account** (free)
- **30 minutes of time**

---

## 🧪 Step 1: Test Docker Locally

```bash
# Navigate to your project
cd /path/to/cicd-ecommerce-pipeline

# Build and test
docker build -t ecommerce-app:latest .
docker run -d -p 8080:80 --name test ecommerce-app:latest

# Check it works
curl http://localhost:8080
# Should see your website!

# Clean up
docker stop test && docker rm test
```

---

## 🔐 Step 2: Create Simple IAM Roles

### 2.1 Create CodeBuild Role

1. **IAM Console** → Roles → Create role
2. **Trusted entity**: AWS service → CodeBuild
3. **Permissions**: Add these policies:
   - `CloudWatchLogsFullAccess`
   - `AmazonEC2ContainerRegistryPowerUser`
4. **Role name**: `CodeBuild-ECR-Role`
5. **Create role**

### 2.2 Create CodeDeploy Role

1. **Create role** → AWS service → CodeDeploy
2. **Use case**: CodeDeploy
3. **Permissions**: `AWSCodeDeployRole` (auto-selected)
4. **Role name**: `CodeDeploy-Simple-Role`

### 2.3 Create CodePipeline Role (Manual)

Since CodePipeline isn't in the service list, we'll create it manually:

1. **Create role** → AWS service → EC2 (we'll change this)
2. **Skip permissions** → Next
3. **Role name**: `CodePipeline-Simple-Role`
4. **Create role**

5. **Edit the trust policy**:
   - Click on your new role
   - **Trust relationships** tab → Edit trust policy
   - Replace with:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

6. **Add permissions**:
   - **Permissions** tab → Add permissions → Attach policies
   - Add these policies:
     - `AWSCodePipelineServiceRole`
     - `AWSCodeBuildDeveloperAccess`
     - `AWSCodeDeployFullAccess`
     - `AmazonS3FullAccess`

### 2.4 Create EC2 Role

1. **Create role** → AWS service → EC2
2. **Permissions**:
   - `AmazonEC2RoleforAWSCodeDeploy`
   - `AmazonEC2ContainerRegistryReadOnly`
3. **Role name**: `EC2-Simple-Role`

---

## 📦 Step 3: Create ECR Repository

1. **Search "ECR"** in AWS Console → Elastic Container Registry
2. **Create repository**
3. **Repository name**: `ecommerce-app`
4. **Visibility**: Private
5. **Create repository**

**✅ Success**: You should see your repository with a URI like:
`123456789.dkr.ecr.us-east-1.amazonaws.com/ecommerce-app`

---

## 🖥️ Step 4: Create EC2 Instance

1. **EC2 Console** → Launch instance
2. **Name**: `Ecommerce-Simple-Server`
3. **AMI**: Amazon Linux 2023
4. **Instance type**: t2.micro
5. **Key pair**: Create or select existing
6. **Security group**: Create new
   - **Name**: `Ecommerce-Simple-SG`
   - **Rules**: SSH (22) from your IP, HTTP (80) from anywhere
7. **IAM instance profile**: `EC2-Simple-Role`
8. **User data**:

```bash
#!/bin/bash
yum update -y
yum install -y docker ruby wget

# Start Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install CodeDeploy agent
cd /home/ec2-user
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
./install auto
systemctl start codedeploy-agent
systemctl enable codedeploy-agent

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
```

9. **Launch instance**

---

## 🔧 Step 5: Create CodeDeploy Application

1. **CodeDeploy Console** → Applications → Create application
2. **Application name**: `Ecommerce-Simple-App`
3. **Compute platform**: EC2/On-premises
4. **Create application**

5. **Create deployment group**:
   - **Deployment group name**: `Ecommerce-Simple-DG`
   - **Service role**: `CodeDeploy-Simple-Role`
   - **Deployment type**: In-place
   - **Environment**: Amazon EC2 instances
   - **Tag**: Key=`Name`, Value=`Ecommerce-Simple-Server`
   - **Create deployment group**

---

## 🏗️ Step 6: Create CodeBuild Project

1. **CodeBuild Console** → Create build project
2. **Project name**: `Ecommerce-Simple-Build`
3. **Source**: GitHub → Connect to your repository
4. **Environment**:
   - **Managed image**
   - **Operating system**: Amazon Linux 2
   - **Runtime**: Standard
   - **Image**: `aws/codebuild/amazonlinux2-x86_64-standard:5.0`
   - **Privileged**: ✅ **Enable** (for Docker)
   - **Service role**: `CodeBuild-ECR-Role`
5. **Environment variables**:
   - `AWS_DEFAULT_REGION` = `us-east-1` (or your region)
   - `AWS_ACCOUNT_ID` = `123456789` (your account ID)
   - `IMAGE_REPO_NAME` = `ecommerce-app`
   - `IMAGE_TAG` = `latest`
6. **Buildspec**: Use a buildspec file → `buildspec.yml`
7. **Create build project**

---

## 🔄 Step 7: Create CodePipeline

1. **CodePipeline Console** → Create pipeline
2. **Pipeline name**: `Ecommerce-Simple-Pipeline`
3. **Service role**: `CodePipeline-Simple-Role`
4. **Source stage**:
   - **GitHub (Version 2)** → Connect to GitHub
   - **Repository**: Your repository
   - **Branch**: `main`
5. **Build stage**:
   - **CodeBuild** → `Ecommerce-Simple-Build`
6. **Deploy stage**:
   - **CodeDeploy** → `Ecommerce-Simple-App` → `Ecommerce-Simple-DG`
7. **Create pipeline**

---

## 🧪 Step 8: Test Your Pipeline

### 8.1 Watch First Deployment

1. **Pipeline should start automatically**
2. **Watch stages**: Source → Build → Deploy
3. **Check your EC2 public IP** - should see your website!

### 8.2 Test Auto-Deployment

1. **Edit** `src/ecommerce-app/index.html`
2. **Change title** to include "v3.0"
3. **Commit and push** to GitHub
4. **Watch pipeline trigger** automatically
5. **Check website** - should see changes!

---

## 🔍 Step 9: Troubleshooting

**Build fails**:
- Check CodeBuild logs
- Ensure "Privileged" is enabled
- Verify environment variables

**Deploy fails**:
```bash
# SSH to EC2 and check:
sudo systemctl status codedeploy-agent
sudo docker ps
aws ecr get-login-password --region us-east-1
```

**Website not accessible**:
- Check security group allows port 80
- Verify container is running: `sudo docker ps`

---

## 🧹 Step 10: Cleanup

1. **Delete CodePipeline**: `Ecommerce-Simple-Pipeline`
2. **Delete CodeBuild**: `Ecommerce-Simple-Build`
3. **Delete CodeDeploy**: `Ecommerce-Simple-App`
4. **Delete ECR repository**: `ecommerce-app`
5. **Terminate EC2**: `Ecommerce-Simple-Server`
6. **Delete IAM roles**: All 4 roles

---

## 💰 Simple Cost Estimate

- **EC2 t2.micro**: ~$8/month (Free tier: $0)
- **ECR storage**: ~$1/month for images
- **CodePipeline**: $1/month
- **CodeBuild**: $0.005/minute (very cheap)

**Total**: ~$10/month (or ~$2 with free tier)

---

## 🎉 Success!

You now have a **simple CI/CD pipeline** that:
- ✅ Builds Docker images automatically
- ✅ Stores them in ECR
- ✅ Deploys to EC2 on code changes
- ✅ Uses industry-standard tools

**Next steps**: Add monitoring, multiple environments, or learn Kubernetes!

This is exactly how many companies deploy applications - you've learned real DevOps skills! 🚀

---

## 🧪 Step 1: Test Docker Locally First (Important!)

**Why test locally?** Always test your application locally before deploying to AWS. This saves time and money!

### 1.1 Install Docker

**On Windows:**
1. Download Docker Desktop from docker.com
2. Install and restart your computer
3. Open Command Prompt or PowerShell

**On Mac:**
1. Download Docker Desktop from docker.com
2. Install and start Docker Desktop

**On Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install docker.io
sudo systemctl start docker
sudo usermod -aG docker $USER
# Log out and log back in
```

**On Amazon Linux/CentOS:**
```bash
sudo yum install docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
```

### 1.2 Test Your E-commerce Application

```bash
# 1. Navigate to your project folder
cd /path/to/cicd-ecommerce-pipeline

# 2. Build the Docker image (this creates your container)
docker build -t ecommerce-app:latest .

# 3. Run the container (this starts your website)
docker run -d -p 8080:80 --name ecommerce-test ecommerce-app:latest

# 4. Test it works
# Open your browser and go to: http://localhost:8080
# You should see your e-commerce website!

# 5. Clean up when done testing
docker stop ecommerce-test
docker rm ecommerce-test
```

**🎉 Success Check**: You should see "CloudMart - Docker E-Commerce Platform v2.0" in your browser.

**❌ If it doesn't work**: Check Docker is running, and make sure you're in the right folder with the Dockerfile.

**✅ Only proceed to AWS if local testing works!**

---

## 🔐 Step 2: Create IAM Roles (Security Setup)

**What are IAM Roles?** Think of them as "permission slips" that allow AWS services to work together securely.

**Why do we need them?** Each AWS service needs permission to talk to other services. We'll create 4 roles:

1. **EC2 Role**: Allows servers to receive deployments
2. **CodeDeploy Role**: Allows CodeDeploy to deploy to servers
3. **CodeBuild Role**: Allows CodeBuild to build and test code
4. **CodePipeline Role**: Allows CodePipeline to orchestrate everything

### 2.1 Create EC2 Instance Role

**Step-by-step:**

1. **Open AWS Console** → Search "IAM" → Click IAM
2. **In left sidebar** → Click "Roles"
3. **Click "Create role"**
4. **Select trusted entity**:
   - Choose "AWS service"
   - Choose "EC2"
   - Click "Next"
5. **Add permissions** (search for each and check the box):
   - `AmazonEC2RoleforAWSCodeDeploy`
   - `CloudWatchAgentServerPolicy`
6. **Click "Next"**
7. **Role details**:
   - **Role name**: `EC2-CodeDeploy-Role`
   - **Description**: `Allows EC2 instances to work with CodeDeploy`
8. **Click "Create role"**

**✅ Success**: You should see "Role EC2-CodeDeploy-Role created successfully"

### 2.2 Create CodeDeploy Service Role

1. **Click "Create role"** (in IAM Roles page)
2. **Select trusted entity**:
   - Choose "AWS service"
   - Choose "CodeDeploy"
   - Select "CodeDeploy" (not CodeDeploy for ECS)
   - Click "Next"
3. **Permissions**: `AWSCodeDeployRole` should be automatically selected
4. **Click "Next"**
5. **Role details**:
   - **Role name**: `CodeDeploy-Service-Role`
   - **Description**: `Allows CodeDeploy to deploy applications`
6. **Click "Create role"**

### 2.3 Create CodeBuild Service Role

1. **Click "Create role"**
2. **Select trusted entity**:
   - Choose "AWS service"
   - Choose "CodeBuild"
   - Click "Next"
3. **Add permissions** (search and select both):
   - `CloudWatchLogsFullAccess`
   - `AmazonS3ReadOnlyAccess`
4. **Click "Next"**
5. **Role details**:
   - **Role name**: `CodeBuild-Service-Role`
   - **Description**: `Allows CodeBuild to build and test applications`
6. **Click "Create role"**

### 2.4 Create CodePipeline Service Role

1. **Click "Create role"**
2. **Select trusted entity**:
   - Choose "AWS service"
   - Choose "CodePipeline"
   - Click "Next"
3. **Permissions**: `AWSCodePipelineServiceRole` should be automatically selected
4. **Click "Next"**
5. **Role details**:
   - **Role name**: `CodePipeline-Service-Role`
   - **Description**: `Allows CodePipeline to orchestrate CI/CD pipeline`
6. **Click "Create role"**

7. **Add more permissions** (this role needs extra permissions):
   - Find your newly created `CodePipeline-Service-Role` and click on it
   - Click "Add permissions" → "Attach policies"
   - Search and attach these policies:
     - `AWSCodeBuildDeveloperAccess`
     - `AWSCodeDeployFullAccess`
     - `AmazonS3FullAccess`

**🎯 Quick Check**: You should now have 4 roles in your IAM Roles list:
- EC2-CodeDeploy-Role
- CodeDeploy-Service-Role  
- CodeBuild-Service-Role
- CodePipeline-Service-Role

---

## 🖥️ Step 3: Set Up EC2 Instances (Your Servers)

**What are EC2 instances?** Virtual computers in the cloud that will run your website.

**Why do we need them?** These servers will host your Docker containers and serve your website to users.

### 3.1 Launch Your First Server

1. **Open AWS Console** → Search "EC2" → Click EC2
2. **Click "Launch instance"** (big orange button)

3. **Name and tags**:
   - **Name**: `Ecommerce-Docker-Server-1`

4. **Application and OS Images**:
   - **Amazon Machine Image (AMI)**: Select "Amazon Linux 2023 AMI" (should be first option)
   - **Architecture**: 64-bit (x86)

5. **Instance type**:
   - **Instance type**: `t2.micro` (Free tier eligible)

6. **Key pair (login)**:
   - If you have a key pair: Select it
   - If you don't: Click "Create new key pair"
     - **Key pair name**: `ecommerce-key`
     - **Key pair type**: RSA
     - **Private key file format**: .pem
     - Click "Create key pair" (this downloads a file - keep it safe!)

7. **Network settings** (Click "Edit"):
   - **Create security group**: Yes
   - **Security group name**: `Ecommerce-Docker-SG`
   - **Description**: `Security group for ecommerce Docker servers`
   - **Inbound security group rules**:
     - **Rule 1**: SSH, Port 22, Source: My IP (for you to connect)
     - **Rule 2**: HTTP, Port 80, Source: Anywhere (0.0.0.0/0) (for users to access website)
     - **Rule 3**: HTTPS, Port 443, Source: Anywhere (0.0.0.0/0) (for secure access)

8. **Configure storage**:
   - **Size**: 8 GiB (default is fine)
   - **Volume type**: gp3 (default)

9. **Advanced details** (Click to expand):
   - **IAM instance profile**: Select `EC2-CodeDeploy-Role`
   - **User data** (copy and paste this script):

```bash
#!/bin/bash
# This script runs when the server starts up

# Update the system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install CodeDeploy agent (needed for deployments)
yum install -y ruby wget
cd /home/ec2-user
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
./install auto
systemctl start codedeploy-agent
systemctl enable codedeploy-agent

# Create directory for our application
mkdir -p /opt/ecommerce-app
chown ec2-user:ec2-user /opt/ecommerce-app

echo "Server setup completed!" > /home/ec2-user/setup-complete.txt
```

10. **Summary**: Review everything looks correct
11. **Click "Launch instance"**

**✅ Success**: You should see "Successfully initiated launch of instance"

### 3.2 Launch Your Second Server (Optional but Recommended)

**Why a second server?** For high availability - if one server fails, the other keeps your website running.

Repeat the exact same process as above, but change:
- **Name**: `Ecommerce-Docker-Server-2`
- **Security group**: Select existing `Ecommerce-Docker-SG` (don't create new)

### 3.3 Wait for Servers to Start

1. **Go to EC2 Dashboard** → Click "Instances"
2. **Wait for both instances** to show:
   - **Instance State**: Running ✅
   - **Status Check**: 2/2 checks passed ✅

**⏱️ This usually takes 2-3 minutes**

### 3.4 Create Load Balancer (Traffic Director)

**What's a Load Balancer?** It distributes website traffic between your servers and checks if they're healthy.

1. **In EC2 Console** → Click "Load Balancers" (left sidebar)
2. **Click "Create Load Balancer"**
3. **Choose "Application Load Balancer"** → Click "Create"

4. **Basic configuration**:
   - **Load balancer name**: `Ecommerce-Docker-ALB`
   - **Scheme**: Internet-facing
   - **IP address type**: IPv4

5. **Network mapping**:
   - **VPC**: Default VPC (should be pre-selected)
   - **Mappings**: Check at least 2 availability zones (different locations)

6. **Security groups**:
   - **Create new security group**: `ALB-SG`
   - **Description**: `Security group for Application Load Balancer`
   - **Rules**:
     - HTTP (80) from Anywhere (0.0.0.0/0)
     - HTTPS (443) from Anywhere (0.0.0.0/0)

7. **Listeners and routing**:
   - **Create target group**: Click "Create target group"
   
   **In new tab (Target Group creation)**:
   - **Target type**: Instances
   - **Target group name**: `Ecommerce-Docker-TG`
   - **Protocol**: HTTP, **Port**: 80
   - **VPC**: Default VPC
   - **Health check path**: `/`
   - **Click "Next"**
   - **Register targets**: Select both your EC2 instances
   - **Click "Create target group"**
   
   **Back to Load Balancer tab**:
   - **Refresh** and select your new target group: `Ecommerce-Docker-TG`

8. **Click "Create load balancer"**

**✅ Success**: Load balancer will take 2-3 minutes to become active.

**🎯 Quick Check**: 
- 2 EC2 instances running ✅
- 1 Load balancer active ✅
- 1 Target group with 2 targets ✅

---

## 🔧 Step 4: Set Up CodeDeploy (Deployment Service)

**What is CodeDeploy?** The service that automatically deploys your Docker containers to your EC2 servers.

### 4.1 Create CodeDeploy Application

1. **Open AWS Console** → Search "CodeDeploy" → Click CodeDeploy
2. **Click "Applications"** (left sidebar)
3. **Click "Create application"**

4. **Application configuration**:
   - **Application name**: `Ecommerce-Docker-App`
   - **Compute platform**: EC2/On-premises
5. **Click "Create application"**

**✅ Success**: You should see "Application Ecommerce-Docker-App created successfully"

### 4.2 Create Deployment Group

**What's a Deployment Group?** It tells CodeDeploy which servers to deploy to and how.

1. **In your application page** → Click "Create deployment group"

2. **Deployment group configuration**:
   - **Deployment group name**: `Ecommerce-Docker-DG`
   - **Service role**: Select `CodeDeploy-Service-Role`

3. **Deployment type**:
   - Select **"In-place deployment"** (updates existing servers)

4. **Environment configuration**:
   - Select **"Amazon EC2 instances"**
   - **Tag group 1**:
     - **Key**: `Name`
     - **Value**: `Ecommerce-Docker-Server-1`
   - **Click "Add tag group"** (if you have a second server):
     - **Key**: `Name`
     - **Value**: `Ecommerce-Docker-Server-2`

5. **Install AWS CodeDeploy Agent**: 
   - Select **"Now and schedule updates"** (agent auto-updates)

6. **Deployment settings**:
   - **Deployment configuration**: CodeDeployDefault.AllAtOnce

7. **Load balancer**:
   - **Enable load balancing**: ✅ Check this box
   - **Choose a target group**: Select `Ecommerce-Docker-TG`

8. **Click "Create deployment group"**

**✅ Success**: You should see "Deployment group Ecommerce-Docker-DG created successfully"

---

## 🏗️ Step 5: Set Up CodeBuild (Build Service)

**What is CodeBuild?** The service that builds your Docker container and runs tests.

### 5.1 Create CodeBuild Project

1. **Open AWS Console** → Search "CodeBuild" → Click CodeBuild
2. **Click "Create build project"**

3. **Project configuration**:
   - **Project name**: `Ecommerce-Docker-Build`
   - **Description**: `Builds and tests Docker container for ecommerce application`

4. **Source**:
   - **Source provider**: GitHub
   - **Repository**: Connect to your GitHub repository
     - Click "Connect to GitHub" → Authorize AWS CodeBuild
     - **Repository URL**: Paste your GitHub repository URL
     - **Source version**: refs/heads/main (or master)

5. **Environment**:
   - **Environment image**: Managed image
   - **Operating system**: Amazon Linux 2
   - **Runtime(s)**: Standard
   - **Image**: `aws/codebuild/amazonlinux2-x86_64-standard:5.0`
   - **Image version**: Always use the latest
   - **Environment type**: Linux
   - **Privileged**: ✅ **IMPORTANT: Check this box** (required for Docker)
   - **Service role**: Select `CodeBuild-Service-Role`

6. **Buildspec**:
   - **Build specifications**: Use a buildspec file
   - **Buildspec name**: `buildspec.yml` (this file is in your project)

7. **Artifacts**:
   - **Type**: No artifacts (CodePipeline will handle this)

8. **Logs**:
   - **CloudWatch logs**: Enable (helps with debugging)
   - **Group name**: `/aws/codebuild/Ecommerce-Docker-Build`

9. **Click "Create build project"**

**✅ Success**: You should see "Build project Ecommerce-Docker-Build created successfully"

**🔍 Understanding buildspec.yml**: This file in your project tells CodeBuild how to:
- Install Docker
- Build your Docker image
- Test the container works
- Package everything for deployment

---

## 🔄 Step 6: Create CodePipeline (The Orchestrator)

**What is CodePipeline?** The "conductor" that orchestrates everything - it watches GitHub for changes and triggers the entire deployment process.

### 6.1 Create Your Pipeline

1. **Open AWS Console** → Search "CodePipeline" → Click CodePipeline
2. **Click "Create pipeline"**

3. **Pipeline settings**:
   - **Pipeline name**: `Ecommerce-Docker-Pipeline`
   - **Service role**: Select `CodePipeline-Service-Role`
   - **Artifact store**: Default location (S3 bucket will be created automatically)
   - **Click "Next"**

4. **Add source stage**:
   - **Source provider**: GitHub (Version 2)
   - **Connection**: Click "Connect to GitHub"
     - **Connection name**: `GitHub-Connection`
     - Click "Connect to GitHub" → Authorize in popup
     - Click "Create connection"
   - **Repository name**: Select your repository from dropdown
   - **Branch name**: `main` (or `master` if that's your default branch)
   - **Output artifacts**: `SourceOutput` (default)
   - **Click "Next"**

5. **Add build stage**:
   - **Build provider**: AWS CodeBuild
   - **Region**: Same as your other resources
   - **Project name**: Select `Ecommerce-Docker-Build`
   - **Input artifacts**: `SourceOutput`
   - **Output artifacts**: `BuildOutput`
   - **Click "Next"**

6. **Add deploy stage**:
   - **Deploy provider**: AWS CodeDeploy
   - **Region**: Same as your other resources
   - **Application name**: Select `Ecommerce-Docker-App`
   - **Deployment group**: Select `Ecommerce-Docker-DG`
   - **Input artifacts**: `BuildOutput`
   - **Click "Next"**

7. **Review**:
   - **Review all settings** - make sure everything looks correct
   - **Click "Create pipeline"**

**✅ Success**: Your pipeline will be created and should start running automatically!

### 6.2 Understanding Your Pipeline Flow

```
📁 GitHub (Source) → 🏗️ CodeBuild (Build) → 🚀 CodeDeploy (Deploy)
       ↓                      ↓                      ↓
   Code Changes         Build Docker Image      Deploy to EC2
   Trigger Pipeline     Run Tests               Update Website
```

**What happens when you push code to GitHub:**
1. **Source Stage**: CodePipeline detects the change and downloads your code
2. **Build Stage**: CodeBuild builds your Docker image and runs tests
3. **Deploy Stage**: CodeDeploy deploys the new container to your EC2 servers
4. **Result**: Your website is updated automatically!

---

## 🧪 Step 7: Test Your Pipeline

### 7.1 Watch Your First Deployment

1. **Go to CodePipeline Console** → Click your pipeline `Ecommerce-Docker-Pipeline`
2. **Watch the stages execute**:
   - **Source**: Should complete quickly (green checkmark)
   - **Build**: Takes 2-5 minutes (watch the progress)
   - **Deploy**: Takes 2-3 minutes (deploys to your servers)

3. **If any stage fails** (red X):
   - Click on the failed stage
   - Click "Details" to see error logs
   - Common issues and solutions are in the troubleshooting section below

### 7.2 Check Your Live Website

1. **Get your Load Balancer URL**:
   - Go to EC2 Console → Load Balancers
   - Click on `Ecommerce-Docker-ALB`
   - Copy the **DNS name** (looks like: ecommerce-docker-alb-123456789.us-east-1.elb.amazonaws.com)

2. **Open in browser**: Paste the DNS name in your browser
3. **You should see**: "CloudMart - Docker E-Commerce Platform v2.0"

**🎉 Congratulations!** Your e-commerce website is now live on AWS!

### 7.3 Test Automatic Deployment

**Now for the magic** - let's test that changes automatically deploy:

1. **Edit your website**:
   - Open `src/ecommerce-app/index.html` in a text editor
   - Find the line: `<title>CloudMart - Docker E-Commerce Platform v2.0</title>`
   - Change it to: `<title>CloudMart - Docker E-Commerce Platform v3.0 - Auto Deploy Works!</title>`

2. **Commit and push to GitHub**:
```bash
git add .
git commit -m "Test automatic deployment - update to v3.0"
git push origin main
```

3. **Watch the magic happen**:
   - Go back to your CodePipeline console
   - You should see the pipeline start automatically
   - Wait for all stages to complete (about 5-8 minutes)

4. **Check your website**:
   - Refresh your browser with the Load Balancer URL
   - You should see the updated title!

**🎉 Amazing!** You've just experienced professional DevOps automation!

---

## 🔍 Step 8: Monitoring and Troubleshooting

### 8.1 How to Check if Everything is Working

**Check Your Servers:**
```bash
# SSH into your EC2 instance (replace with your key and IP)
ssh -i your-key.pem ec2-user@your-instance-public-ip

# Check if Docker is running
sudo systemctl status docker

# Check if your container is running
sudo docker ps

# Check container logs
sudo docker logs ecommerce-app

# Test the website locally on the server
curl http://localhost/
```

**Check Load Balancer Health:**
1. Go to EC2 Console → Target Groups
2. Click on `Ecommerce-Docker-TG`
3. Check "Targets" tab - should show "healthy" for both instances

**Check Pipeline Logs:**
1. **CodeBuild logs**: CodeBuild Console → Build History → Click on a build → View logs
2. **CodeDeploy logs**: CodeDeploy Console → Deployments → Click deployment → View events

### 8.2 Common Issues and Solutions

**❌ Problem**: Pipeline fails at Build stage with "Docker permission denied"
**✅ Solution**: 
- Go to CodeBuild project settings
- Make sure "Privileged" is enabled in Environment settings
- This allows CodeBuild to run Docker commands

**❌ Problem**: Deployment fails with "CodeDeploy agent not found"
**✅ Solution**:
```bash
# SSH to your EC2 instance and run:
sudo systemctl status codedeploy-agent
sudo systemctl start codedeploy-agent
sudo systemctl enable codedeploy-agent
```

**❌ Problem**: Website shows "This site can't be reached"
**✅ Solution**:
- Check security groups allow HTTP (port 80) from anywhere
- Verify Load Balancer targets are healthy
- Make sure Docker container is running on port 80

**❌ Problem**: Container won't start
**✅ Solution**:
```bash
# Check Docker daemon
sudo systemctl status docker
sudo systemctl start docker

# Check for port conflicts
sudo netstat -tlnp | grep :80

# Check container logs for errors
sudo docker logs ecommerce-app
```

**❌ Problem**: Pipeline doesn't trigger on GitHub push
**✅ Solution**:
- Check GitHub connection in CodePipeline source settings
- Verify you're pushing to the correct branch (main/master)
- Check webhook is created in your GitHub repository settings

### 8.3 Useful Debugging Commands

```bash
# Check EC2 instance status
aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`]'

# Check CodeDeploy deployments
aws deploy list-deployments --application-name Ecommerce-Docker-App

# Check CodeBuild builds
aws codebuild list-builds-for-project --project-name Ecommerce-Docker-Build

# Check Load Balancer health
aws elbv2 describe-target-health --target-group-arn YOUR_TARGET_GROUP_ARN
```

---

## 🎯 Step 9: Success Checklist

### 9.1 Verify Everything Works

- [ ] **Local Docker test**: ✅ Application runs on http://localhost:8080
- [ ] **IAM roles created**: ✅ All 4 roles exist with correct permissions
- [ ] **EC2 instances running**: ✅ Both servers show "running" status
- [ ] **Load balancer active**: ✅ ALB shows "active" status
- [ ] **Target group healthy**: ✅ Both targets show "healthy"
- [ ] **CodeBuild project**: ✅ Builds complete successfully
- [ ] **CodeDeploy application**: ✅ Deployments succeed
- [ ] **CodePipeline**: ✅ All stages execute successfully
- [ ] **Website accessible**: ✅ Load balancer URL shows your website
- [ ] **Auto-deployment**: ✅ Code changes trigger pipeline and update website

### 9.2 Test Scenarios to Try

1. **Make a visual change**: Edit CSS in `src/ecommerce-app/styles.css`
2. **Add a new product**: Edit `src/ecommerce-app/products.json`
3. **Update the homepage**: Modify `src/ecommerce-app/index.html`
4. **Test error handling**: Introduce a syntax error and see pipeline catch it

Each change should automatically deploy within 5-8 minutes!

---

## 🧹 Step 10: Cleanup (Important - Avoid Charges!)

**⚠️ Important**: AWS charges for running resources. Clean up when you're done learning!

### 10.1 Delete Resources in This Order

1. **Delete CodePipeline**:
   - CodePipeline Console → Select `Ecommerce-Docker-Pipeline` → Delete

2. **Delete CodeBuild Project**:
   - CodeBuild Console → Select `Ecommerce-Docker-Build` → Delete

3. **Delete CodeDeploy Application**:
   - CodeDeploy Console → Select `Ecommerce-Docker-App` → Delete

4. **Delete Load Balancer**:
   - EC2 Console → Load Balancers → Select `Ecommerce-Docker-ALB` → Delete

5. **Delete Target Group**:
   - EC2 Console → Target Groups → Select `Ecommerce-Docker-TG` → Delete

6. **Terminate EC2 Instances**:
   - EC2 Console → Instances → Select both instances → Instance State → Terminate

7. **Delete Security Groups**:
   - EC2 Console → Security Groups → Delete `Ecommerce-Docker-SG` and `ALB-SG`

8. **Delete IAM Roles**:
   - IAM Console → Roles → Delete all 4 roles you created

### 10.2 Verify Cleanup

```bash
# Check no instances are running
aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`]'

# Should return empty list: []
```

**💰 Cost after cleanup**: $0 (everything deleted)

---

## 💰 Cost Breakdown (While Running)

**Monthly costs in US East region**:
- **EC2 t2.micro (2 instances)**: ~$16-20 (Free tier: $0 for first 12 months)
- **Application Load Balancer**: ~$16-25
- **CodePipeline**: $1 per active pipeline
- **CodeBuild**: $0.005 per build minute (very cheap for testing)
- **CodeDeploy**: Free for EC2 deployments
- **S3 storage**: ~$1-2 for artifacts

**Total while learning**: ~$34-48/month (or ~$18-28 with free tier)
**Total after cleanup**: $0

---

## 🎉 Congratulations! You're Now a DevOps Engineer!

### What You've Accomplished

You've built a **production-grade CI/CD pipeline** that:
- ✅ Automatically deploys code changes
- ✅ Uses Docker containers for consistency
- ✅ Includes automated testing
- ✅ Has high availability with load balancing
- ✅ Follows security best practices
- ✅ Scales to handle real traffic

### Skills You've Learned

- **Docker**: Containerization technology used by Netflix, Uber, Airbnb
- **CI/CD**: Automation practices used by Google, Facebook, Amazon
- **AWS**: Cloud platform powering millions of websites
- **Infrastructure as Code**: Modern way to manage infrastructure
- **DevOps**: Culture and practices that speed up software delivery

### Next Steps

1. **Add more features** to your e-commerce site
2. **Learn Kubernetes** for container orchestration
3. **Add monitoring** with CloudWatch
4. **Implement blue-green deployments**
5. **Add automated testing** with unit tests
6. **Learn Terraform** for infrastructure as code

### Share Your Success! 🚀

You've just built something that many companies pay DevOps engineers $80,000-150,000+ per year to create and maintain. That's impressive!

**Remember**: The skills you've learned here are in high demand. Keep practicing and building on this foundation.

---

## 🆘 Need Help?

**If you get stuck**:
1. **Check the troubleshooting section** above
2. **Look at CloudWatch logs** for detailed error messages
3. **Verify all IAM permissions** are correctly set
4. **Test Docker locally first** before deploying to AWS
5. **Make sure all services are in the same AWS region**

**Pro tip**: The AWS documentation is excellent. When in doubt, search for the specific service + "AWS documentation".

**You've got this!** 💪
