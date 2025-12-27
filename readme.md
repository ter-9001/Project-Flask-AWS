# 🚀 Flask API Deployment on Amazon EKS (Kubernetes)

  

This project demonstrates the deployment of a simple Flask API (simulating a Feed/Post service) on an Amazon Elastic Kubernetes Service (EKS) cluster, using Terraform to provision all the AWS infrastructure and Kubernetes manifests.

  

The architecture uses ECR to store the Docker image and a Load Balancer (ELB/ALB) to expose the service publicly.

  

---

  

## 🎯 Project Objective

  

1. Infrastructure as Code (IaC): Provision a VPC, an EKS Cluster, and a Node Group using Terraform.

  

2. Security: Use Kubernetes Secrets to inject sensitive environment variables into the Pod.

  

3. Deployment: Automate the application deployment and service exposure (Load Balancer type Service).

  

---

  

## 🏗️ Deployment Architecture

  

Terraform manages the following stack:

  

1.  **AWS VPC:** Isolated network with public subnets (for Load Balancer/NAT GW) and private subnets (for Workers).

  

2.  **AWS ECR:** Private repository to store the Docker image `flask-app-aws:latest`.

  

3.  **AWS EKS:** Kubernetes cluster (`flask-project-eks`).

  

4.  **EKS Node Group:** Two EC2 Workers (`t2.small`) in the private subnets.

  

5.  **Kubernetes Deployment:** Ensures that 2 replicas of the Flask container are always running.

  

6.  **Kubernetes Service (LoadBalancer):** Provisions an **AWS Load Balancer** that distributes external traffic on port 80 to port 5000 of the Pods. ---


## 🧪 Flask Application (Endpoints)

  

The Flask API is a simple microservice with two main endpoints:

  

| Endpoint | Method | Description | Security Requirement |

| :--- | :--- | :--- | :--- |

  
  

| `/post` | `POST` | Returns the post feed (simulated) | (N/A)

| :--- | :--- | :--- | :--- |

  
  

| `/feed` | `GET ` | Create a new post | Requires the Secret Token |

| :--- | :--- | :--- | :--- |


## 📋 Project Structure (Files and Folders) 

```bash
.
├── app
│ ├── app.py `Flask application core`
│ ├── posts.json `Post database`
│ └── templates `Template folder (feed and index)`
│ ├── feed.html `Feed page template`
│ └── index.html `Main page template`
├── deployment.yaml `File for deploying the Docker image on EKS`
├── Dockerfile `Standard Dockerfile for creating the Docker image with the project in the app folder`
├── ecr `Separate folder for creating the ECR (where Docker images will be stored)`
│ ├── ecr.tf `File to apply ECR via Terraform`
│ └── terraform.tfstate
├── eks.tf `File to create ECK via Terraform`
├── iam.tf `File to apply different functions to EKS via Terraform`
├── output.tf `File to check if EKS is working after running the (terraform apply) command`
├── readme.md
├── requirements.txt `Libraries to be automatically installed in Docker via the Dockerfile`
├── secret.yaml `File to apply secrets via kubectl`
├── service.yaml `File to apply services via kubectl (Public URL to access the application)`
├── terraform.tfstate
└── vpc.tf `File to apply VPC via Terraform`

```
  
  

## 🔒 The Kubernetes Secret (`kubernetes_secret_v1`)

  

The `/feed` endpoint is protected and requires an access token. This token is securely stored in EKS using a Secret called **`flask-project-token`**.

  

The Secret is injected directly into the container as an environment variable, ensuring that the sensitive value (`FEED_SECRET_TOKEN`) is never exposed in the code or deployment manifest.

  

---

  

## ⚙️ How to Run the Project

  

### Prerequisites

  

* AWS CLI configured (administrator credentials and permissions).

  

* Terraform (v1.0+) installed.

  

* Docker installed (to build and push the image to ECR).

  

* SSH key (`mykeys-2`) in the `us-east-1` region (referenced in `main.tf`).

  

### 1. Building and Deploying the Docker Image

  

Before running Terraform, you must build your Flask image and deploy it to the ECR:

  

```bash

# 1. Log in to the ECR (replace with your AWS account ID and region)

aws  ecr  get-login-password  --region  us-east-1 | docker  login  --username  AWS  --password-stdin  `YOUR_AWS_ACCOUNT_ID`.dkr.ecr.us-east-1.amazonaws.com

  

# 2. Build the image

docker  build  -t  flask-app-aws  .

  

# 3. Tag the image

docker  tag  flask-app-aws:latest [`YOUR_AWS_ACCOUNT_ID`.dkr.ecr.us-east-1.amazonaws.com/flask-app-aws:latest](https://`YOUR_AWS_ACCOUNT_ID`.dkr.ecr.us-east-1.amazonaws.com/flask-app-aws:latest)

  

# 4. Push to the ECR (the ECR is created in 'terraform apply')

docker  push [`YOUR_AWS_ACCOUNT_ID`.dkr.ecr.us-east-1.amazonaws.com/flask-app-aws:latest](https://`YOUR_AWS_ACCOUNT_ID`.dkr.ecr.us-east-1.amazonaws.com/flask-app-aws:latest)