# Phase 05 — Amazon ECR

## Overview

This phase implements the container image registry layer of the AWS Microservices DevSecOps platform using Amazon Elastic Container Registry (Amazon ECR).

The objective is to create isolated ECR repositories for the individual microservices and establish the foundation required for the CI pipeline to build, tag, scan, authenticate, and push container images.

The ECR repositories act as the central image registry between the Jenkins CI layer and the Amazon EKS deployment platform.

---

## Objectives

The main objectives of this phase are:

- Create ECR repositories for microservices.
- Maintain one repository per microservice.
- Configure repository-level image management.
- Authenticate Jenkins with Amazon ECR.
- Build Docker images from individual microservice source code.
- Apply unique image tags using Jenkins build numbers.
- Push images to ECR.
- Make container images available for Kubernetes deployments.
- Prepare the image flow required by the GitOps deployment process.

---

## Architecture

The image lifecycle implemented in this phase is:

```text
Microservice Source Code
        |
        v
     Jenkins
        |
        | Docker Build
        v
   Docker Image
        |
        | Tag
        v
 Amazon ECR Repository
        |
        | Image
        v
   Kubernetes / EKS



The complete CI/CD flow is:

Developer
   |
   v
GitHub Repository
   |
   v
Jenkins CI
   |
   +---- Build Docker Image
   |
   +---- Authenticate with ECR
   |
   +---- Tag Image
   |
   +---- Push Image
   |
   v
Amazon ECR
   |
   v
Kubernetes Deployment
   |
   v
Amazon EKS
ECR Repository Strategy

A separate ECR repository is maintained for each microservice.

Example:

Amazon ECR
│
├── adservice
├── cartservice
├── checkoutservice
├── currencyservice
├── emailservice
├── frontend
├── paymentservice
├── productcatalogservice
├── recommendationservice
├── shippingservice
└── shoppingassistantservice

The exact list of services should match the microservices implemented in the project.

This repository-per-service approach provides:

Service-level image isolation
Independent image versioning
Easier deployment management
Easier image lifecycle management
Clear ownership of container images
Simplified Kubernetes image references
ECR Image Naming

The standard ECR image format is:

ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/REPOSITORY:TAG

Example:

264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:10

Where:

264991295389

is the AWS account ID.

us-east-1

is the AWS region.

adservice

is the ECR repository.

10

is the image tag generated from the Jenkins build number.

Image Tagging Strategy

The project uses Jenkins build numbers as image tags.

Example:

adservice:1
adservice:2
adservice:3
adservice:4

The corresponding ECR image references become:

264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:1
264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:2
264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:3
264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:4

This provides traceability between:

Git Commit
    |
    v
Jenkins Build
    |
    v
Docker Image Tag
    |
    v
ECR Image
    |
    v
Kubernetes Deployment

Using unique build-based tags also avoids relying exclusively on the mutable latest tag.

Terraform ECR Configuration

ECR repositories can be provisioned using Terraform.

Example:

resource "aws_ecr_repository" "adservice" {
  name                 = "adservice"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "adservice"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

The same pattern can be used for the remaining microservices.

Repository Configuration

Each repository should define:

Repository Name
Image Tag Mutability
Image Scanning
Tags

Example:

Repository:
adservice

Tag Mutability:
MUTABLE

Scan on Push:
Enabled

Environment:
dev

ManagedBy:
Terraform
Image Scanning

ECR image scanning is enabled as part of the repository configuration.

Example:

image_scanning_configuration {
  scan_on_push = true
}

The purpose of image scanning is to identify vulnerabilities in container images after they are pushed to ECR.

The image security flow is:

Docker Build
     |
     v
ECR Push
     |
     v
Image Scan
     |
     v
Vulnerability Findings

This forms part of the DevSecOps security controls implemented in the project.

Jenkins → ECR Authentication

Jenkins requires permission to authenticate with Amazon ECR.

The authentication command used by the CI pipeline is:

aws ecr get-login-password --region us-east-1 \
  | docker login \
  --username AWS \
  --password-stdin 264991295389.dkr.ecr.us-east-1.amazonaws.com

Successful authentication should return:

Login Succeeded
Docker Image Build

The Jenkins pipeline builds the Docker image from the individual microservice directory.

Example:

docker build -t adservice .

The resulting local image is:

adservice:latest
Docker Image Tagging

Before pushing the image to ECR, Jenkins applies the build number as the image tag.

Example:

docker tag adservice:latest \
264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:${BUILD_NUMBER}

If the Jenkins build number is:

25

the resulting image is:

264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:25
Push Image to ECR

The tagged image is pushed using:

docker push \
264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:${BUILD_NUMBER}

The expected flow is:

Docker Build
     |
     v
adservice:latest
     |
     | docker tag
     v
ECR Image
     |
     | docker push
     v
Amazon ECR
Example Jenkins Image Pipeline

A simplified image build and push stage:

stage("Docker Image Build") {
    steps {
        script {
            dir('src/adservice') {
                sh 'docker build -t adservice .'
            }
        }
    }
}

stage("ECR Image Pushing") {
    steps {
        script {
            sh '''
                aws ecr get-login-password \
                  --region us-east-1 \
                  | docker login \
                  --username AWS \
                  --password-stdin \
                  264991295389.dkr.ecr.us-east-1.amazonaws.com

                docker tag adservice:latest \
                  264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:${BUILD_NUMBER}

                docker push \
                  264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:${BUILD_NUMBER}
            '''
        }
    }
}

The actual Jenkins implementation should use the repository and account configuration applicable to the environment.

IAM Permissions

The Jenkins execution environment requires permissions to interact with ECR.

Typical ECR actions required for image push include:

ecr:GetAuthorizationToken

ecr:BatchCheckLayerAvailability
ecr:CompleteLayerUpload
ecr:InitiateLayerUpload
ecr:PutImage
ecr:UploadLayerPart

The permissions should be attached to the IAM role used by the Jenkins host or provided through the appropriate AWS credential mechanism.

Validation

After provisioning the ECR repositories, verify them using AWS CLI.

List repositories:

aws ecr describe-repositories \
  --region us-east-1

List a specific repository:

aws ecr describe-repositories \
  --repository-names adservice \
  --region us-east-1
Verify ECR Images

After Jenkins pushes an image:

aws ecr list-images \
  --repository-name adservice \
  --region us-east-1

Example:

IMAGE TAG
---------
1
2
3

To inspect image details:

aws ecr describe-images \
  --repository-name adservice \
  --region us-east-1
Verify Docker Image Locally

On the Jenkins host:

docker images

Expected output should contain the service image:

adservice

Example:

REPOSITORY
adservice

TAG
latest

After tagging:

264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice
ECR to EKS Image Flow

The image created in this phase is consumed by Kubernetes in the next phases.

Example Kubernetes reference:

containers:
  - name: adservice
    image: 264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:25

The deployment flow becomes:

GitHub
   |
   v
Jenkins
   |
   | Docker Build
   v
Docker Image
   |
   | Push
   v
Amazon ECR
   |
   | Image Reference
   v
Kubernetes Deployment
   |
   v
EKS Pod
CI/CD Integration

ECR is the boundary between the CI and deployment stages.

The CI pipeline performs:

Source Checkout
      |
      v
Docker Build
      |
      v
Security Checks
      |
      v
Docker Image
      |
      v
ECR Push

The deployment pipeline consumes the image:

ECR Image
    |
    v
Kubernetes Manifest
    |
    v
GitOps Repository
    |
    v
Argo CD
    |
    v
EKS
Security Considerations

The following security practices are applied:

ECR repositories are managed through Terraform.
Image scanning is enabled on push.
Jenkins uses IAM-based AWS authentication.
Container images use versioned tags.
ECR repositories are separated by microservice.
AWS credentials should not be hardcoded in Jenkinsfiles.
Secrets should be stored using Jenkins Credentials or AWS IAM mechanisms.
Production environments should use stricter repository policies and lifecycle controls.
Evidence to Capture

The following evidence should be stored under:

evidence/05-ecr/

Recommended screenshots:

01-ecr-repositories.png
02-ecr-adservice-repository.png
03-ecr-image-list.png
04-ecr-image-details.png
05-jenkins-docker-build.png
06-jenkins-ecr-push.png
07-ecr-image-scan.png
08-aws-cli-ecr-validation.png

Evidence should demonstrate:

ECR repositories were created.
Individual microservice repositories exist.
Docker images were successfully pushed.
Images have versioned tags.
Image scanning is enabled.
Jenkins successfully authenticated with ECR.
Jenkins successfully pushed the container image.
AWS CLI can retrieve the repository and image information.
Validation Checklist

Use the following checklist to verify this phase:

[ ] ECR repositories created
[ ] One repository created per microservice
[ ] Repository names verified
[ ] Image scanning enabled
[ ] Jenkins has ECR permissions
[ ] Docker build successful
[ ] ECR authentication successful
[ ] Docker image tagged
[ ] Docker image pushed
[ ] Image visible in ECR
[ ] Image tag matches Jenkins build number
[ ] ECR image scan completed
[ ] Kubernetes can reference the ECR image
Expected Result

At the end of Phase 05:

                 GitHub
                    |
                    v
                 Jenkins
                    |
              Docker Build
                    |
                    v
             Docker Image
                    |
                    v
            Amazon ECR
             /    |    \
            /     |     \
       Service  Service  Service
       Repo     Repo     Repo
         |        |        |
         +--------+--------+
                  |
                  v
              Amazon EKS

The AWS environment should contain an ECR repository for each microservice, and Jenkins should be capable of building and pushing versioned Docker images into the corresponding repositories.

Phase Completion

Phase 05 is considered complete when:

All required ECR repositories are provisioned.
Jenkins can authenticate with ECR.
Microservice Docker images can be built successfully.
Images can be tagged using Jenkins build numbers.
Images can be pushed successfully to ECR.
Images are visible in the AWS ECR console.
Image scanning is enabled.
The resulting ECR image references are ready for Kubernetes deployment.

The next phase is:

Phase 06 — Jenkins CI