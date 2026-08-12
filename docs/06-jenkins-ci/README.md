# Phase 06 — Jenkins CI

## 1. Objective

This phase implements the **Continuous Integration (CI)** layer of the AWS Microservices DevSecOps platform using Jenkins.

The objective is to automate the microservice build and container image publishing workflow.

Jenkins is responsible for:

- Checking out source code from GitHub.
- Building microservice Docker images.
- Authenticating with Amazon ECR.
- Tagging images using Jenkins build numbers.
- Pushing images to Amazon ECR.
- Updating Kubernetes deployment manifests.
- Committing deployment changes back to GitHub.
- Providing the CI handoff to the GitOps deployment process.

The implementation also includes separate Jenkins pipelines for infrastructure automation and microservice CI workflows.

---

## 2. Key Outcomes

At the end of this phase, the following capabilities should be available:

- Jenkins installed and operational.
- Java 21 configured.
- Git configured.
- Docker available to Jenkins.
- AWS CLI available.
- Terraform available.
- GitHub repository connected.
- Infrastructure Terraform pipeline configured.
- Microservice CI pipelines configured.
- Docker images built automatically.
- Images authenticated and pushed to Amazon ECR.
- Images tagged using Jenkins build numbers.
- Kubernetes deployment manifests updated automatically.
- Git changes committed and pushed.
- CI workflow integrated with the GitOps process.

---

## 3. CI Architecture

The Jenkins CI architecture follows this model:

    GitHub
       |
       v
    Source Repository
       |
       v
    Jenkins
       |
       +--------------------------+
       |                          |
       v                          v
    Infrastructure CI        Microservice CI
       |                          |
       v                          v
    Terraform                 Docker Build
       |                          |
       v                          v
    AWS Infrastructure        ECR Push
                                  |
                                  v
                           Update Kubernetes
                              Manifest
                                  |
                                  v
                               GitHub
                                  |
                                  v
                              Argo CD
                                  |
                                  v
                              Amazon EKS

The deployment and synchronization responsibilities are handled by the GitOps layer in **Phase 08 — Argo CD GitOps**.

---

# 4. Jenkins Host

Jenkins is installed on the DevOps Jump Host created during Phase 03.

The Jump Host provides the tools required for the CI/CD implementation.

### Primary Tools

- Java 21
- Jenkins
- Git
- Docker
- Docker Compose
- Terraform
- Ansible
- Maven
- Node.js
- npm
- AWS CLI
- Vault
- Trivy
- MariaDB
- PostgreSQL

Verify Jenkins:

    sudo systemctl status jenkins

Verify Java:

    java --version

Verify Jenkins:

    jenkins --version

---

# 5. Jenkins Web Interface

After Jenkins installation, the Jenkins web interface should be accessible through the configured network endpoint.

The initial Jenkins administrator password can be retrieved using:

    sudo cat /var/lib/jenkins/secrets/initialAdminPassword

The exact Jenkins endpoint depends on the networking and access configuration implemented for the project.

---

# 6. Jenkins Workspace

Jenkins stores pipeline workspaces under:

    /var/lib/jenkins/workspace/

Each Jenkins pipeline receives its own workspace.

Example:

    /var/lib/jenkins/workspace/aws-eks-terraform

A typical project workspace may contain:

    workspace/
    └── project/
        ├── terraform/
        ├── kubernetes/
        ├── src/
        └── jenkinsfiles/

The workspace should be treated as temporary build storage.

The authoritative infrastructure state remains in the configured Terraform remote backend.

---

# 7. Jenkins Pipeline Types

The implementation uses multiple Jenkins pipelines.

The pipelines are logically divided into two major categories:

### Infrastructure Pipelines

    Infrastructure Pipelines
            |
            +-- EKS Terraform
            |
            +-- ECR Terraform
            |
            +-- ECS Terraform
            |
            +-- Other infrastructure automation

### Microservice Pipelines

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

The exact service list should match the microservices implemented in the project.

---

# 8. Infrastructure CI Pipeline

The Terraform pipeline automates infrastructure operations.

The pipeline supports:

- apply
- destroy

The required action can be selected when starting the Jenkins build.

Example Jenkins parameter:

    parameters {
        choice(
            name: 'ACTION',
            choices: ['apply', 'destroy'],
            description: 'Select Terraform action'
        )
    }

---

# 9. Terraform CI Flow

The Terraform CI workflow is:

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

The pipeline validates the Terraform configuration before performing infrastructure operations.

---

# 10. Terraform Initialization

The pipeline initializes Terraform using:

    terraform init --reconfigure

The `--reconfigure` option ensures that Terraform initializes using the configured backend settings.

Example Jenkins stage:

    stage('Terraform init') {
        steps {
            dir('aws-eks-terraform') {
                sh 'terraform init --reconfigure'
            }
        }
    }

The directory must match the actual Terraform configuration location in the repository.

---

# 11. Terraform Validation

The Terraform configuration is validated before execution.

Command:

    terraform validate

Example Jenkins stage:

    stage('Terraform validate') {
        steps {
            dir('aws-eks-terraform') {
                sh 'terraform validate'
            }
        }
    }

Validation should succeed before continuing to the planning or deployment stages.

---

# 12. Terraform Plan

Terraform generates an execution plan before infrastructure changes are applied.

Command:

    terraform plan

The plan identifies:

- Resources to create.
- Resources to modify.
- Resources to destroy.
- Configuration changes detected by Terraform.

The plan should be reviewed before applying infrastructure changes.

---

# 13. Terraform Apply

When the selected action is:

    apply

The pipeline executes:

    terraform apply -auto-approve

This provisions or updates the infrastructure managed by the corresponding Terraform configuration.

---

# 14. Terraform Destroy

When the selected action is:

    destroy

The pipeline executes:

    terraform destroy -auto-approve

This removes the infrastructure managed by the corresponding Terraform configuration.

Destroy operations should be carefully controlled because they can remove active infrastructure.

---

# 15. Microservice CI Pipeline

Each microservice has an independent Jenkins CI pipeline.

Example services include:

- adservice
- cartservice
- checkoutservice
- currencyservice
- emailservice
- frontend
- paymentservice
- productcatalogservice
- recommendationservice
- shippingservice
- shoppingassistantservice

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

---

# 16. Microservice Pipeline Example

A simplified Jenkins pipeline structure is:

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

The values shown above are examples and must be replaced with the actual repository, branch, AWS account, service, and environment configuration.

---

# 17. Workspace Cleanup

The pipeline cleans the workspace before starting a new build:

    stage('Cleaning Workspace') {
        steps {
            cleanWs()
        }
    }

This prevents artifacts from previous builds from affecting the current build.

---

# 18. Source Code Checkout

The Jenkins pipeline checks out the microservice source code from GitHub.

Example:

    git branch: 'main',
        url: 'https://github.com/your-user/aws-microservices-devsecops-platform'

The actual repository URL and branch must match the project configuration.

After checkout, Jenkins should have access to the required source directories.

Example:

    src/
    ├── adservice/
    ├── cartservice/
    ├── checkoutservice/
    ├── currencyservice/
    └── ...

---

# 19. Docker Image Build

The CI pipeline enters the individual microservice directory.

Example:

    cd src/adservice

The Docker image is built using:

    docker build -t adservice .

The resulting local image is:

    adservice:latest

The Docker build stage should complete successfully before the image is tagged or pushed.

---

# 20. ECR Authentication

Jenkins authenticates against Amazon ECR using the AWS CLI.

Example:

    aws ecr get-login-password \
      --region us-east-1 \
      | docker login \
      --username AWS \
      --password-stdin \
      ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

Expected result:

    Login Succeeded

The Jenkins execution environment must have sufficient IAM permissions to obtain the ECR authentication token.

---

# 21. Image Tagging

Jenkins uses the Jenkins build number as the Docker image tag.

Example:

    docker tag adservice:latest \
    ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/adservice:${BUILD_NUMBER}

If:

    BUILD_NUMBER=15

The resulting image becomes:

    ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/adservice:15

This provides traceability between:

    Jenkins Build
         |
         v
    Docker Image
         |
         v
    ECR Image

---

# 22. ECR Image Push

The tagged image is pushed to Amazon ECR.

Command:

    docker push \
    ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/adservice:${BUILD_NUMBER}

A successful pipeline should show the image layers being uploaded and the resulting image digest.

The image should then be visible in the corresponding ECR repository.

---

# 23. Kubernetes Manifest Update

After the Docker image is successfully pushed to ECR, Jenkins updates the corresponding Kubernetes deployment manifest.

Example:

    containers:
      - name: adservice
        image: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/adservice:15

The pipeline updates the image reference using:

    sed -i \
    "s#image:.*#image: ${REPO_URL}:${BUILD_NUMBER}#g" \
    ${YAML_FILE}

This changes the Kubernetes manifest to reference the newly created image version.

---

# 24. Git Commit

After updating the Kubernetes manifest, Jenkins commits the change.

Example:

    git add .

    git commit \
      -m "Update ${IMAGE_NAME} Image to version ${BUILD_NUMBER}"

Example commit message:

    Update adservice Image to version 15

This creates a traceable relationship between the Jenkins build and the Kubernetes deployment configuration.

---

# 25. Git Push

The updated Kubernetes manifest is pushed back to GitHub.

Example:

    git push \
    https://${git_token}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} \
    HEAD:main

The GitHub repository therefore contains the updated image version.

Git becomes the source of truth for the Kubernetes deployment configuration.

---

# 26. GitOps Handoff

After Jenkins updates the Kubernetes deployment manifest, the workflow becomes:

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

Jenkins is responsible for **Continuous Integration** and image creation.

Argo CD is responsible for **Continuous Delivery** and Kubernetes synchronization.

This separation is a core part of the DevSecOps architecture.

---

# 27. Jenkins Credentials

Sensitive credentials should never be hardcoded into Jenkinsfiles.

The Jenkins Credentials Store should be used for sensitive values such as:

- GitHub tokens.
- AWS credentials, where required.
- Other deployment credentials.

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

The credential is injected only during the required pipeline execution.

---

# 28. Jenkins AWS Authentication

The preferred authentication approach for Jenkins running on AWS is IAM-based authentication using the EC2 instance role.

The Jenkins host should receive an IAM role containing only the permissions required by the CI workflows.

For ECR operations, the role should provide the required ECR permissions.

For Terraform infrastructure pipelines, the Jenkins execution role requires permissions necessary to manage the target AWS resources.

Avoid embedding AWS access keys directly inside Jenkinsfiles.

Do not commit:

    AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY
    AWS_SESSION_TOKEN

or other sensitive credentials to Git.

---

# 29. Jenkins Pipeline Isolation

Each microservice pipeline operates independently.

Example:

    Jenkins
    |
    +-- adservice
    |
    +-- cartservice
    |
    +-- checkoutservice
    |
    +-- currencyservice
    |
    +-- emailservice
    |
    +-- frontend
    |
    +-- paymentservice
    |
    +-- productcatalogservice
    |
    +-- recommendationservice
    |
    +-- shippingservice
    |
    +-- shoppingassistantservice

This allows individual services to be built and published without rebuilding all microservices.

---

# 30. CI Trigger Model

Jenkins pipelines can be executed manually or integrated with a Git-based trigger mechanism.

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

---

# 31. Build Traceability

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

Example:

    Jenkins Build: 25
          |
          v
    ECR Image:
    adservice:25
          |
          v
    Kubernetes:
    adservice:25
          |
          v
    EKS:
    Pod running image version 25

This allows the project to identify which CI build produced a deployed container image.

---

# 32. Validation

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

---

# 33. Pipeline Validation

For each microservice pipeline, verify:

- [ ] Workspace cleaned successfully.
- [ ] Git repository checkout successful.
- [ ] Docker build successful.
- [ ] ECR authentication successful.
- [ ] Docker image tagged successfully.
- [ ] Docker image pushed successfully.
- [ ] Kubernetes YAML updated.
- [ ] Git commit created.
- [ ] Git push successful.
- [ ] Jenkins pipeline completed successfully.

---

# 34. Evidence to Capture

Store implementation evidence under:

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

- Jenkins is installed and operational.
- Jenkins can access the Git repository.
- Terraform pipelines execute successfully.
- Microservice pipelines execute successfully.
- Docker images are built.
- Images are pushed to ECR.
- Kubernetes manifests are updated.
- Changes are committed to Git.
- The final pipeline completes successfully.

---

# 35. Troubleshooting

## 35.1 Jenkins Service Not Found

Check:

    systemctl status jenkins

Verify the Jenkins package:

    dpkg -l | grep jenkins

Check the installation log:

    sudo tail -100 /var/log/install-tools.log

---

## 35.2 Java Not Found

Check:

    java --version

Verify installed Java versions:

    ls /usr/lib/jvm/

The configured Java runtime should be compatible with the installed Jenkins version.

For the project environment, Java 21 is expected.

---

## 35.3 Docker Permission Error

If Jenkins reports:

    permission denied while trying to connect to the Docker daemon

Check the Jenkins user's groups:

    groups jenkins

The Jenkins user should have Docker group access where this architecture requires it.

After changing group membership, restart Jenkins:

    sudo systemctl restart jenkins

Then verify:

    sudo -u jenkins docker --version

---

## 35.4 ECR Login Failure

Check the AWS identity:

    aws sts get-caller-identity

Check ECR access:

    aws ecr describe-repositories \
      --region us-east-1

Then retry authentication:

    aws ecr get-login-password \
      --region us-east-1 \
      | docker login \
      --username AWS \
      --password-stdin \
      ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

If authentication fails, verify:

- AWS region.
- AWS account.
- IAM permissions.
- ECR repository.
- Jenkins AWS authentication.

---

## 35.5 Docker Build Failure

Check the microservice directory:

    ls src/adservice

Verify the Dockerfile:

    ls src/adservice/Dockerfile

Run the build manually:

    cd src/adservice

    docker build -t adservice .

Review the Docker build output for missing files, dependencies, or incorrect build context.

---

## 35.6 Terraform "No Configuration Files"

If Jenkins reports:

    Error: No configuration files

Verify that the `dir()` path in the Jenkinsfile matches the actual repository structure.

Example:

    dir('aws-eks-terraform') {
        sh 'terraform init'
    }

The directory must contain the Terraform configuration files:

    *.tf

Do not use a different directory name between Terraform stages unless the repository actually contains that directory.

---

## 35.7 Git Branch Mismatch

Verify the repository branches:

    git branch -a

The Jenkinsfile must use the correct branch.

Example:

    git branch: 'main',
        url: 'https://github.com/your-user/aws-microservices-devsecops-platform'

---

# 36. Security Controls

The Jenkins CI implementation follows these security principles:

- IAM roles are preferred over hardcoded AWS access keys.
- GitHub tokens are stored in Jenkins Credentials.
- Docker images are pushed to private ECR repositories.
- ECR image scanning is enabled.
- Images use versioned build-number tags.
- Secrets are not committed to Git.
- Jenkins workspaces are treated as temporary.
- CI and CD responsibilities are separated.
- Jenkins is responsible for build automation.
- Argo CD is responsible for Kubernetes deployment synchronization.
- AWS permissions should follow least privilege.

---

# 37. CI/CD Responsibility Separation

The implementation clearly separates CI from CD.

    CI
     |
     v
    Jenkins
     |
     +----------------+
     |                |
     v                v
    Docker Build     ECR Push
                         |
                         v
                        Git
                         |
    ====================|====================
                         |
                         v
                        CD
                         |
                      Argo CD
                         |
                         v
                        EKS

Jenkins does not directly act as the Kubernetes deployment controller.

Instead:

    Jenkins
       |
       v
    Updates Git
       |
       v
    Argo CD detects change
       |
       v
    Argo CD synchronizes EKS

This provides a clear separation between image creation and Kubernetes deployment.

---

# 38. Expected Result

At the end of Phase 06, the complete CI/CD handoff should follow this architecture:

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
        +---- Source Checkout
        |
        +---- Docker Build
        |
        +---- ECR Authentication
        |
        +---- ECR Push
        |
        +---- Kubernetes Manifest Update
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

The Jenkins CI layer should be capable of independently building each microservice, publishing its container image to ECR, and updating the Git-managed Kubernetes deployment configuration.

---

# 39. Phase Completion Checklist

Before moving to the next phase, verify:

- [ ] Jenkins installed.
- [ ] Java 21 configured.
- [ ] Jenkins service running.
- [ ] Git configured.
- [ ] Docker available to Jenkins.
- [ ] AWS CLI configured.
- [ ] Terraform available.
- [ ] GitHub repository connected.
- [ ] Infrastructure pipeline created.
- [ ] ECR pipeline created.
- [ ] Microservice pipelines created.
- [ ] Docker image build successful.
- [ ] ECR authentication successful.
- [ ] Image push successful.
- [ ] Image version generated from Jenkins build number.
- [ ] Kubernetes manifest updated.
- [ ] Git commit successful.
- [ ] Git push successful.
- [ ] CI pipeline completed successfully.
- [ ] Evidence captured.

---

# 40. Phase Completion Criteria

Phase 06 is considered complete when:

1. Jenkins is successfully installed and operational.
2. Jenkins can access the project Git repository.
3. Infrastructure Terraform pipelines execute successfully.
4. Microservice CI pipelines execute successfully.
5. Docker images can be built successfully.
6. Jenkins can authenticate with Amazon ECR.
7. Versioned images can be pushed to ECR.
8. Jenkins build numbers are used as image tags.
9. Kubernetes deployment manifests are updated automatically.
10. Updated manifests are committed to GitHub.
11. GitHub contains the latest image version.
12. The CI workflow successfully hands off deployment configuration to the GitOps process.
13. Required implementation evidence has been captured.

---

# 41. Outcome

At the end of Phase 06, the project has a functional Jenkins Continuous Integration layer.

The resulting workflow is:

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

This phase establishes the automated CI foundation required for the remaining Kubernetes and GitOps stages.

The next phase is:

**Phase 07 — Kubernetes**