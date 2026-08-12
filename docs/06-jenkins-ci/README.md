# Phase 06 — Jenkins CI

## Overview

This phase implements the Continuous Integration (CI) layer of the AWS Microservices DevSecOps platform using Jenkins.

Jenkins is responsible for automating the microservice build process, creating Docker images, authenticating with Amazon ECR, pushing versioned images, and updating the Kubernetes deployment configuration with the newly generated image version.

The implementation uses separate Jenkins pipelines for the infrastructure and microservice workflows.

---

## Objectives

The main objectives of this phase are:

- Deploy Jenkins on the DevOps jump host.
- Configure Jenkins with the required DevOps tools.
- Connect Jenkins with GitHub.
- Create Terraform automation pipelines.
- Create individual CI pipelines for microservices.
- Build Docker images automatically.
- Authenticate Jenkins with Amazon ECR.
- Push versioned images to ECR.
- Update Kubernetes deployment manifests.
- Push deployment changes back to GitHub.
- Establish an automated CI workflow for the microservices.

---

# CI Architecture

The Jenkins CI architecture is:

```text
                         GitHub
                           |
                           |
                    Source Repository
                           |
                           v
                       Jenkins
                           |
              +------------+-------------+
              |                          |
              v                          v
       Infrastructure CI          Microservice CI
              |                          |
              v                          v
          Terraform                 Docker Build
              |                          |
              v                          v
          AWS Infra                  ECR Push
                                         |
                                         v
                                  Update Kubernetes
                                     Manifest
                                         |
                                         v
                                      GitHub


###

The deployment portion is handled by the GitOps layer in Phase 08.

Jenkins Host

Jenkins is installed on the DevOps jump host.

The jump host contains the tools required for the CI/CD implementation.

The primary tools include:

Java 21
Jenkins
Git
Docker
Docker Compose
Terraform
Ansible
Maven
Node.js
npm
AWS CLI
Vault
Trivy
MariaDB
PostgreSQL

The Jenkins service runs as:

jenkins.service

Verify Jenkins:

sudo systemctl status jenkins

Verify Java:

java --version

Verify Jenkins:

jenkins --version
Jenkins Web Interface

Jenkins is exposed through the configured AWS networking and load balancer configuration.

The Jenkins web interface should be accessible using the configured Jenkins endpoint.

After installation, the initial administrator password can be retrieved using:

sudo cat /var/lib/jenkins/secrets/initialAdminPassword
Jenkins Workspace

Jenkins stores build workspaces under:

/var/lib/jenkins/workspace/

Each Jenkins pipeline receives its own workspace.

Example:

/var/lib/jenkins/workspace/aws-eks-terraform

A typical workspace contains the repository checked out by Jenkins:

workspace/
└── project/
    ├── terraform/
    ├── kubernetes/
    ├── src/
    └── jenkinsfiles/
Jenkins Pipeline Types

The implementation uses multiple Jenkins pipelines.

The pipelines are logically separated into:

Infrastructure Pipelines
        |
        +-- EKS Terraform
        |
        +-- ECR Terraform
        |
        +-- ECS Terraform
        |
        +-- Other infrastructure automation

Microservice Pipelines
        |
        +-- adservice
        +-- cartservice
        +-- checkoutservice
        +-- currencyservice
        +-- emailservice
        +-- frontend
        +-- paymentservice
        +-- productcatalogservice
        +-- recommendationservice
        +-- shippingservice
        +-- shoppingassistantservice

The exact service list should match the services implemented in the project.

Infrastructure CI Pipeline

The Terraform pipeline automates infrastructure operations.

The pipeline supports:

apply
destroy

The user selects the required action when starting the Jenkins build.

Example parameter:

parameters {
    choice(
        name: 'ACTION',
        choices: ['apply', 'destroy'],
        description: 'Select Terraform action'
    )
}
Terraform Pipeline Flow

The Terraform CI process is:

GitHub
   |
   v
Jenkins
   |
   v
Checkout
   |
   v
Terraform Version
   |
   v
Terraform Init
   |
   v
Terraform Validate
   |
   v
Terraform Plan
   |
   +------------------+
   |                  |
   v                  v
 Apply              Destroy
   |                  |
   v                  v
 AWS Resources      AWS Resources
                    Deleted
Terraform Initialization

The pipeline initializes Terraform using:

terraform init --reconfigure

This ensures that Terraform initializes using the configured backend.

Example:

stage('Terraform init') {
    steps {
        dir('aws-eks-terraform') {
            sh 'terraform init --reconfigure'
        }
    }
}
Terraform Validation

The configuration is validated before execution.

terraform validate

Example:

stage('Terraform validate') {
    steps {
        dir('aws-eks-terraform') {
            sh 'terraform validate'
        }
    }
}
Terraform Plan

Terraform generates an execution plan before applying infrastructure changes.

terraform plan

The plan allows the CI pipeline to identify:

Resources to create
Resources to modify
Resources to destroy
Terraform Apply

When the selected action is:

apply

the pipeline executes:

terraform apply -auto-approve

This provisions or updates the infrastructure.

Terraform Destroy

When the selected action is:

destroy

the pipeline executes:

terraform destroy -auto-approve

This removes the infrastructure managed by the corresponding Terraform configuration.

Microservice CI Pipeline

Each microservice has an independent Jenkins pipeline.

Example:

adservice
cartservice
checkoutservice
currencyservice
emailservice
frontend
paymentservice
productcatalogservice
recommendationservice
shippingservice
shoppingassistantservice

Each pipeline performs the following operations:

Checkout Source
      |
      v
Build Docker Image
      |
      v
Authenticate with ECR
      |
      v
Tag Image
      |
      v
Push Image to ECR
      |
      v
Update Kubernetes YAML
      |
      v
Commit Change
      |
      v
Push Change to GitHub
Microservice Pipeline Example

The pipeline structure is:

pipeline {
    agent any

    environment {
        GIT_REPO_NAME = "aws-microservices-devsecops-platform"
        GIT_EMAIL = "your-email"
        GIT_USER_NAME = "your-github-user"
        IMAGE_NAME = "adservice"
        REPO_URL = "ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/adservice"
        YAML_FILE = "adservice.yaml"
    }

    stages {

        stage('Cleaning Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/your-user/aws-microservices-devsecops-platform'
            }
        }

        stage('Docker Image Build') {
            steps {
                script {
                    dir('src/adservice') {
                        sh 'docker build -t adservice .'
                    }
                }
            }
        }

        stage('ECR Image Pushing') {
            steps {
                script {
                    sh '''
                        aws ecr get-login-password \
                          --region us-east-1 \
                          | docker login \
                          --username AWS \
                          --password-stdin \
                          ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

                        docker tag adservice:latest \
                          ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/adservice:${BUILD_NUMBER}

                        docker push \
                          ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/adservice:${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Update Deployment File') {
            steps {
                dir('kubernetes-files') {
                    withCredentials([
                        string(
                            credentialsId: 'github',
                            variable: 'git_token'
                        )
                    ]) {
                        sh '''
                            git config user.email "${GIT_EMAIL}"
                            git config user.name "${GIT_USER_NAME}"

                            sed -i \
                              "s#image:.*#image: ${REPO_URL}:${BUILD_NUMBER}#g" \
                              ${YAML_FILE}

                            git add .
                            git commit \
                              -m "Update ${IMAGE_NAME} Image to version ${BUILD_NUMBER}"

                            git push \
                              https://${git_token}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} \
                              HEAD:main
                        '''
                    }
                }
            }
        }
    }
}

The values shown above are examples and should be replaced with the actual repository, branch, account, and service configuration.

Docker Build

The CI pipeline enters the individual microservice directory.

Example:

cd src/adservice

The Docker image is built using:

docker build -t adservice .

The resulting local image is:

adservice:latest
ECR Authentication

Jenkins authenticates against Amazon ECR using AWS CLI:

aws ecr get-login-password \
  --region us-east-1 \
  | docker login \
  --username AWS \
  --password-stdin \
  ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

Expected result:

Login Succeeded
Image Tagging

Jenkins uses the Jenkins build number as the Docker image tag.

Example:

docker tag adservice:latest \
ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/adservice:${BUILD_NUMBER}

If:

BUILD_NUMBER=15

the resulting image becomes:

ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/adservice:15

This provides traceability between:

Jenkins Build
      |
      v
Docker Image
      |
      v
ECR Image
ECR Push

The tagged image is pushed to Amazon ECR:

docker push \
ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/adservice:${BUILD_NUMBER}

A successful pipeline should show the image layers being uploaded and the image digest being generated.

Kubernetes Manifest Update

After successfully pushing the image, the pipeline updates the corresponding Kubernetes deployment file.

Example:

containers:
  - name: adservice
    image: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/adservice:15

The pipeline updates the image using:

sed -i \
"s#image:.*#image: ${REPO_URL}:${BUILD_NUMBER}#g" \
${YAML_FILE}
Git Commit

The updated Kubernetes manifest is committed:

git add .
git commit \
  -m "Update ${IMAGE_NAME} Image to version ${BUILD_NUMBER}"

Example commit:

Update adservice Image to version 15
Git Push

The updated manifest is pushed back to GitHub.

Example:

git push \
https://${git_token}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} \
HEAD:main

The GitHub repository therefore becomes the source of truth for the new image version.

GitOps Handoff

After Jenkins updates the Kubernetes manifest:

Jenkins
   |
   | Update image tag
   v
GitHub
   |
   v
Kubernetes Manifest
   |
   v
Argo CD
   |
   v
Amazon EKS

Jenkins is responsible for CI and image creation.

Argo CD is responsible for CD and synchronization.

This separation is an important part of the DevSecOps architecture.

Jenkins Credentials

Sensitive credentials should not be hardcoded into Jenkinsfiles.

The Jenkins Credentials Store should be used for sensitive values such as:

GitHub token
AWS credentials, if required
Other deployment credentials

Example:

withCredentials([
    string(
        credentialsId: 'github',
        variable: 'git_token'
    )
]) {
    sh '''
        ...
    '''
}

The token is therefore injected only during the required pipeline execution.

Jenkins AWS Authentication

The preferred approach for Jenkins running on AWS is IAM-based authentication using the EC2 instance role.

The Jenkins host should receive an IAM role with the minimum required permissions.

For ECR operations, permissions should include the required ECR actions.

For infrastructure pipelines, the Jenkins execution role requires the permissions necessary to perform the Terraform operations for the target AWS resources.

Avoid embedding AWS access keys directly in Jenkinsfiles.

Workspace Cleanup

The pipelines clean the workspace before starting a new build:

stage('Cleaning Workspace') {
    steps {
        cleanWs()
    }
}

This prevents previous build artifacts from affecting the current build.

Jenkins Pipeline Isolation

Each microservice pipeline operates independently.

For example:

Jenkins
│
├── adservice
│
├── cartservice
│
├── checkoutservice
│
├── currencyservice
│
├── emailservice
│
├── frontend
│
├── paymentservice
│
├── productcatalogservice
│
├── recommendationservice
│
├── shippingservice
│
└── shoppingassistantservice

This allows individual services to be built and deployed without rebuilding all services.

CI Trigger Model

The Jenkins pipelines can be executed manually or integrated with a Git-based trigger mechanism.

A typical workflow is:

Developer Push
      |
      v
GitHub
      |
      v
Jenkins Pipeline
      |
      v
Docker Build
      |
      v
ECR

For production environments, webhook-based triggering can be used to reduce manual intervention.

Build Traceability

The CI implementation provides traceability across multiple layers:

Git Commit
    |
    v
Jenkins Build Number
    |
    v
Docker Image Tag
    |
    v
ECR Image
    |
    v
Kubernetes Manifest
    |
    v
Argo CD Deployment
    |
    v
EKS Pod

For example:

Jenkins Build: 25

        ↓

ECR Image:

adservice:25

        ↓

Kubernetes:

adservice:25

        ↓

EKS:

Pod running image version 25

This makes it possible to identify which CI build produced a deployed container image.

Validation

Verify Jenkins:

sudo systemctl status jenkins

Verify Java:

java --version

Verify Docker:

docker --version

Verify Terraform:

terraform version

Verify AWS CLI:

aws --version

Verify Jenkins can execute Docker:

sudo -u jenkins docker --version

Verify AWS identity:

aws sts get-caller-identity

Verify ECR repositories:

aws ecr describe-repositories \
  --region us-east-1
Pipeline Validation

For each microservice pipeline, verify:

[ ] Workspace cleaned
[ ] Git repository checkout successful
[ ] Docker build successful
[ ] ECR authentication successful
[ ] Docker image tagged
[ ] Docker image pushed
[ ] Kubernetes YAML updated
[ ] Git commit created
[ ] Git push successful
Evidence to Capture

Store evidence for this phase under:

evidence/06-jenkins/

Recommended evidence:

01-jenkins-dashboard.png
02-jenkins-tools.png
03-jenkins-terraform-pipeline.png
04-terraform-pipeline-success.png
05-microservice-pipeline-list.png
06-adservice-build.png
07-docker-build-success.png
08-ecr-login-success.png
09-ecr-push-success.png
10-image-tag.png
11-kubernetes-manifest-update.png
12-git-commit.png
13-github-updated-manifest.png
14-microservice-pipeline-success.png

Evidence should demonstrate:

Jenkins is installed and operational.
Jenkins can access the Git repository.
Terraform pipelines execute successfully.
Microservice pipelines execute successfully.
Docker images are built.
Images are pushed to ECR.
Kubernetes manifests are updated.
Changes are committed to Git.
The final pipeline completes successfully.
Troubleshooting
Jenkins Service Not Found

Check:

systemctl status jenkins

If the service does not exist, verify the Jenkins package:

dpkg -l | grep jenkins

Check the installation log:

sudo tail -f /var/log/install-tools.log
Java Not Found

Check:

java --version

For Jenkins installations requiring Java 21, verify:

ls /usr/lib/jvm/

The configured Java runtime should be compatible with the Jenkins version.

Docker Permission Error

If Jenkins receives:

permission denied while trying to connect to the Docker daemon

verify:

groups jenkins

The Jenkins user should have Docker group access where this architecture requires it.

Restart Jenkins after changing group membership:

sudo systemctl restart jenkins
ECR Login Failure

Check AWS identity:

aws sts get-caller-identity

Check ECR permissions and region:

aws ecr describe-repositories \
  --region us-east-1

Then retry:

aws ecr get-login-password \
  --region us-east-1 \
  | docker login \
  --username AWS \
  --password-stdin \
  ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
Docker Build Failure

Check the service directory:

ls src/adservice

Verify that the directory contains the required Dockerfile:

ls src/adservice/Dockerfile

Run the build manually:

cd src/adservice
docker build -t adservice .
Terraform "No Configuration Files"

If Jenkins reports:

Error: No configuration files

verify that the dir() path in the Jenkinsfile matches the actual repository structure.

For example:

dir('aws-eks-terraform') {
    sh 'terraform init'
}

must point to the directory containing:

*.tf

Do not use different directory names between Terraform stages unless the repository actually contains those directories.

Git Branch Mismatch

Verify the repository branch:

git branch -a

The Jenkinsfile should use the correct branch.

Example:

git branch: 'main',
    url: 'https://github.com/your-user/aws-microservices-devsecops-platform'
Security Controls

The Jenkins CI implementation follows these security principles:

IAM roles are preferred over hardcoded AWS access keys.
GitHub tokens are stored in Jenkins Credentials.
Docker images are pushed to private ECR repositories.
ECR image scanning is enabled.
Image versions are immutable from the deployment perspective through build-number tags.
Secrets are not committed to Git.
CI and CD responsibilities are separated.
Jenkins is used for build automation.
Argo CD is used for Kubernetes deployment synchronization.
CI/CD Responsibility Separation

The implementation separates CI from CD:

                CI
                |
                v
             Jenkins
                |
        +-------+-------+
        |               |
   Docker Build      ECR Push
                        |
                        v
                      Git
                        |
========================|========================
                        |
                        v
                       CD
                        |
                     Argo CD
                        |
                        v
                       EKS

Jenkins does not directly become the Kubernetes deployment controller.

Instead, Jenkins updates the Git-managed deployment configuration, and Argo CD detects and synchronizes the change.

Expected Result

At the end of Phase 06:

Developer
    |
    v
GitHub
    |
    v
Jenkins
    |
    +---- Terraform Automation
    |
    +---- Docker Build
    |
    +---- ECR Push
    |
    +---- Kubernetes Manifest Update
    |
    v
GitHub
    |
    v
Argo CD
    |
    v
Amazon EKS

The Jenkins CI layer should be capable of independently building each microservice, publishing its container image to ECR, and updating the Git-managed Kubernetes deployment configuration.

Phase Completion Checklist
[ ] Jenkins installed
[ ] Java 21 configured
[ ] Jenkins service running
[ ] Git configured
[ ] Docker available to Jenkins
[ ] AWS CLI configured
[ ] Terraform available
[ ] GitHub repository connected
[ ] Infrastructure pipeline created
[ ] ECR pipeline created
[ ] Microservice pipelines created
[ ] Docker image build successful
[ ] ECR authentication successful
[ ] Image push successful
[ ] Image version generated from Jenkins build number
[ ] Kubernetes manifest updated
[ ] Git commit successful
[ ] Git push successful
[ ] CI pipeline completed successfully
[ ] Evidence captured
Phase 06 Completion

Phase 06 is complete when the Jenkins CI layer successfully automates the build and image publishing workflow for the microservices.

The completed flow is:

GitHub
   |
   v
Jenkins
   |
   +---- Checkout
   |
   +---- Build
   |
   +---- Docker Image
   |
   +---- ECR Authentication
   |
   +---- ECR Push
   |
   +---- Update Kubernetes YAML
   |
   +---- Git Commit
   |
   +---- Git Push
   |
   v
GitHub
   |
   v
Argo CD
   |
   v
Amazon EKS

The next phase is:

Phase 07 — Kubernetes