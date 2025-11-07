# CI/CD Pipeline for E-Commerce Platform with Docker

**Production-ready containerized e-commerce application demonstrating modern DevOps practices**

- **Cloud-Native Architecture**: Dockerized application with AWS container orchestration
- **Complete CI/CD Pipeline**: Automated GitHub to AWS deployment workflow  
- **Container Management**: ECR registry with automated Docker image builds
- **AWS Integration**: CodePipeline, CodeBuild, CodeDeploy with EC2 deployment
- **Infrastructure as Code**: Automated deployment scripts and configuration management

## 🎯 Project Overview
This project demonstrates a complete CI/CD pipeline for an e-commerce platform using Docker containers deployed to AWS EC2. The pipeline automatically builds Docker images, tests them, and deploys containerized applications from GitHub to EC2 instances.

## 🏗️ Architecture

![Application Screenshot](Screentshot%20of%20website.png)

**CI/CD Pipeline Flow:**
```
GitHub Repository → CodePipeline → CodeBuild → CodeDeploy → EC2 (Docker Containers)
       ↓                ↓              ↓              ↓
   Source Code    Build Docker    Test Container   Deploy Container
                     Image                         to Production
```

## 🛠️ Technologies Used
- **Docker**: Containerization platform
- **GitHub**: Source code repository and version control
- **AWS CodePipeline**: Orchestrates the CI/CD workflow
- **AWS CodeBuild**: Builds and tests Docker containers
- **AWS CodeDeploy**: Deploys Docker containers to EC2 instances
- **Amazon EC2**: Hosts the containerized e-commerce application
- **AWS IAM**: Manages permissions and security
- **Application Load Balancer**: Distributes traffic across instances

## 📁 Project Structure
```
cicd-ecommerce-pipeline/
├── README.md
├── aws-console-guide.md          # Complete setup guide with Docker
├── Dockerfile                    # Docker container configuration
├── src/
│   ├── ecommerce-app/
│   │   ├── index.html
│   │   ├── styles.css
│   │   ├── script.js
│   │   └── products.json
│   └── config/
│       └── nginx.conf
├── buildspec.yml                 # CodeBuild configuration
├── appspec.yml                   # CodeDeploy configuration
├── deployment/
│   ├── before_install.sh
│   ├── application_start.sh
│   ├── application_stop.sh
│   └── validate_service.sh
└── scripts/
    ├── setup.sh                  # Automated AWS setup
    └── cleanup.sh                # Resource cleanup
```

## 🚀 Quick Start
1. **Follow the complete guide**: `aws-console-guide.md` contains everything you need
2. **Test Docker locally**: Instructions included in the guide
3. **Deploy to AWS**: Step-by-step AWS setup with Docker deployment
4. **Test CI/CD**: Make code changes and watch automatic deployment

## 📊 E-Commerce Application Features
- **Product Catalog**: Browse available products
- **Shopping Cart**: Add/remove items from cart
- **Responsive Design**: Mobile-friendly interface
- **Search Functionality**: Find products quickly
- **Order Summary**: Review items before checkout
- **Dockerized Deployment**: Containerized for consistent deployment

## 🎓 Learning Outcomes
- Docker containerization and deployment
- CI/CD pipeline design and implementation
- AWS CodePipeline orchestration
- CodeBuild for automated building and testing
- CodeDeploy for automated deployments
- EC2 instance configuration and management
- IAM roles and security best practices

## 💰 Cost Estimation
- EC2 instances: $20-40/month (2 t2.micro instances)
- CodePipeline: $1/month per active pipeline
- CodeBuild: $0.005/minute (pay per use)
- CodeDeploy: Free for EC2 deployments
- Application Load Balancer: $16-25/month
- **Total**: $37-66/month for moderate usage
