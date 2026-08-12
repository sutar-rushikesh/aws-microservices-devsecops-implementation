# Phase 05 — Amazon ECR

## 📌 Overview

Phase 05 implements the container image registry layer of the AWS Microservices DevSecOps platform using Amazon Elastic Container Registry (Amazon ECR).

The objective is to create isolated ECR repositories for the individual microservices and establish the foundation required for the CI pipeline to:

- Build container images
- Tag container images
- Authenticate with Amazon ECR
- Scan container images
- Push images to ECR
- Make images available for Kubernetes deployments

Amazon ECR acts as the central container image registry between the Jenkins CI layer and the Amazon EKS deployment platform.

---

# 🎯 Objectives

The main objectives of this phase are:

1. Create ECR repositories for microservices.
2. Maintain one repository per microservice.
3. Configure repository-level image management.
4. Authenticate Jenkins with Amazon ECR.
5. Build Docker images from individual microservice source code.
6. Apply unique image tags using Jenkins build numbers.
7. Push container images to ECR.
8. Enable image scanning.
9. Make container images available for Kubernetes deployments.
10. Prepare the image flow required by the GitOps deployment process.

---

# 🏗️ Architecture

The image lifecycle implemented in this phase is:

```text
Microservice Source Code
        │
        ▼
     Jenkins
        │
        │ Docker Build
        ▼
   Docker Image
        │
        │ Tag
        ▼
 Amazon ECR Repository
        │
        │ Image
        ▼
   Kubernetes / EKS
```

The complete CI/CD flow is:

```text
Developer
    │
    ▼
GitHub Repository
    │
    ▼
Jenkins CI
    │
    ├── Build Docker Image
    │
    ├── Authenticate with ECR
    │
    ├── Tag Image
    │
    └── Push Image
             │
             ▼
        Amazon ECR
             │
             ▼
     Kubernetes Deployment
             │
             ▼
         Amazon EKS
```

---

# 📦 ECR Repository Strategy

A separate ECR repository is maintained for each microservice.

Example:

```text
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
```

The exact list of services should match the microservices implemented in the project.

The repository-per-service approach provides:

- Service-level image isolation
- Independent image versioning
- Easier deployment management
- Easier image lifecycle management
- Clear ownership of container images
- Simplified Kubernetes image references

---

# 🏷️ ECR Image Naming

The standard ECR image format is:

```text
ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/REPOSITORY:TAG
```

Example:

```text
264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:10
```

Where:

| Value | Description |
|---|---|
| `264991295389` | AWS account ID |
| `us-east-1` | AWS region |
| `adservice` | ECR repository |
| `10` | Image tag generated from Jenkins build number |

---

# 🔖 Image Tagging Strategy

The project uses Jenkins build numbers as image tags.

Example:

```text
adservice:1
adservice:2
adservice:3
adservice:4
```

The corresponding ECR image references become:

```text
264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:1
264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:2
264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:3
264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:4
```

This provides traceability between:

```text
Git Commit
    │
    ▼
Jenkins Build
    │
    ▼
Docker Image Tag
    │
    ▼
ECR Image
    │
    ▼
Kubernetes Deployment
```

Using unique build-based tags also avoids relying exclusively on the mutable `latest` tag.

---

# 🏗️ Terraform ECR Configuration

ECR repositories can be provisioned using Terraform.

Example:

```hcl
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
```

The same pattern can be used for the remaining microservices.

---

# ⚙️ Repository Configuration

Each ECR repository should define:

- Repository name
- Image tag mutability
- Image scanning configuration
- Resource tags

Example:

```text
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
```

---

# 🔍 Image Scanning

ECR image scanning is enabled as part of the repository configuration.

Example:

```hcl
image_scanning_configuration {
  scan_on_push = true
}
```

The purpose of image scanning is to identify vulnerabilities in container images after they are pushed to ECR.

The image security flow is:

```text
Docker Build
     │
     ▼
ECR Push
     │
     ▼
Image Scan
     │
     ▼
Vulnerability Findings
```

This forms part of the DevSecOps security controls implemented in the project.

---

# 🔐 Jenkins → ECR Authentication

Jenkins requires permission to authenticate with Amazon ECR.

The authentication command used by the CI pipeline is:

```bash
aws ecr get-login-password --region us-east-1 \
  | docker login \
  --username AWS \
  --password-stdin 264991295389.dkr.ecr.us-east-1.amazonaws.com
```

Successful authentication should return:

```text
Login Succeeded
```

---

# 🐳 Docker Image Build

The Jenkins pipeline builds the Docker image from the individual microservice directory.

Example:

```bash
docker build -t adservice .
```

The resulting local image is:

```text
adservice:latest
```

---

# 🏷️ Docker Image Tagging

Before pushing the image to ECR, Jenkins applies the build number as the image tag.

Example:

```bash
docker tag adservice:latest \
  264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:${BUILD_NUMBER}
```

If the Jenkins build number is:

```text
25
```

the resulting image is:

```text
264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:25
```

---

# 📤 Push Image to ECR

The tagged image is pushed using:

```bash
docker push \
  264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:${BUILD_NUMBER}
```

The expected flow is:

```text
Docker Build
     │
     ▼
adservice:latest
     │
     │ docker tag
     ▼
ECR Image
     │
     │ docker push
     ▼
Amazon ECR
```

---

# 🔄 Jenkins Image Pipeline

A simplified image build and push pipeline is:

```groovy
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
```

The actual Jenkins implementation should use the repository and AWS account configuration applicable to the environment.

---

# 🔑 IAM Permissions

The Jenkins execution environment requires permissions to interact with ECR.

Typical ECR actions required for image push include:

```text
ecr:GetAuthorizationToken
ecr:BatchCheckLayerAvailability
ecr:CompleteLayerUpload
ecr:InitiateLayerUpload
ecr:PutImage
ecr:UploadLayerPart
```

These permissions should be attached to the IAM role used by the Jenkins host or provided through the appropriate AWS credential mechanism.

The permissions should be scoped according to the project's security requirements.

---

# 🔍 ECR Validation

After provisioning the ECR repositories, verify them using the AWS CLI.

---

## List ECR Repositories

Run:

```bash
aws ecr describe-repositories \
  --region us-east-1
```

The command should return the repositories provisioned for the microservices.

---

## List a Specific Repository

Run:

```bash
aws ecr describe-repositories \
  --repository-names adservice \
  --region us-east-1
```

Verify that the expected repository exists.

---

# 🖼️ Verify ECR Images

After Jenkins pushes an image:

```bash
aws ecr list-images \
  --repository-name adservice \
  --region us-east-1
```

Example:

```text
IMAGE TAG
---------
1
2
3
```

To inspect image details:

```bash
aws ecr describe-images \
  --repository-name adservice \
  --region us-east-1
```

This can be used to verify image tags and image metadata.

---

# 🐳 Verify Docker Image Locally

On the Jenkins host:

```bash
docker images
```

Expected output should contain the service image:

```text
adservice
```

Example:

```text
REPOSITORY
adservice

TAG
latest
```

After tagging:

```text
264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice
```

The tagged image should be available locally before the push operation.

---

# ☸️ ECR → EKS Image Flow

The image created in this phase is consumed by Kubernetes in the next phases.

Example Kubernetes reference:

```yaml
containers:
  - name: adservice
    image: 264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:25
```

The deployment flow becomes:

```text
GitHub
   │
   ▼
Jenkins
   │
   │ Docker Build
   ▼
Docker Image
   │
   │ Push
   ▼
Amazon ECR
   │
   │ Image Reference
   ▼
Kubernetes Deployment
   │
   ▼
EKS Pod
```

---

# 🔄 CI/CD Integration

ECR acts as the boundary between the CI and deployment stages.

The CI pipeline performs:

```text
Source Checkout
      │
      ▼
Docker Build
      │
      ▼
Security Checks
      │
      ▼
Docker Image
      │
      ▼
ECR Push
```

The deployment pipeline consumes the image:

```text
ECR Image
    │
    ▼
Kubernetes Manifest
    │
    ▼
GitOps Repository
    │
    ▼
Argo CD
    │
    ▼
EKS
```

This establishes the container image flow required for the later Kubernetes and GitOps phases.

---

# 🔒 Security Considerations

The following security practices are applied:

- ECR repositories are managed through Terraform.
- Image scanning is enabled on push.
- Jenkins uses IAM-based AWS authentication.
- Container images use versioned tags.
- ECR repositories are separated by microservice.
- AWS credentials should not be hardcoded in Jenkinsfiles.
- Secrets should be stored using Jenkins Credentials or AWS IAM mechanisms.
- Production environments should use stricter repository policies and lifecycle controls.

---

# 📸 Evidence Collection

Store implementation evidence under:

```text
evidence/05-ecr/
```

Recommended screenshots:

```text
evidence/05-ecr/
│
├── 01-ecr-repositories.png
├── 02-ecr-adservice-repository.png
├── 03-ecr-image-list.png
├── 04-ecr-image-details.png
├── 05-jenkins-docker-build.png
├── 06-jenkins-ecr-push.png
├── 07-ecr-image-scan.png
└── 08-aws-cli-ecr-validation.png
```

---

## Evidence Should Demonstrate

The captured evidence should demonstrate:

- ECR repositories were created.
- Individual microservice repositories exist.
- Docker images were successfully pushed.
- Images have versioned tags.
- Image scanning is enabled.
- Jenkins successfully authenticated with ECR.
- Jenkins successfully pushed the container image.
- AWS CLI can retrieve repository information.
- AWS CLI can retrieve image information.

---

# 🧪 Validation Checklist

Before moving to the next phase, verify:

- [ ] ECR repositories created
- [ ] One repository created per microservice
- [ ] Repository names verified
- [ ] Image scanning enabled
- [ ] Jenkins has ECR permissions
- [ ] Docker build successful
- [ ] ECR authentication successful
- [ ] Docker image tagged
- [ ] Docker image pushed
- [ ] Image visible in ECR
- [ ] Image tag matches Jenkins build number
- [ ] ECR image scan completed
- [ ] Kubernetes can reference the ECR image
- [ ] Evidence captured

---

# 📊 Expected Result

At the end of Phase 05, the container image architecture should follow this model:

```text
                         GitHub
                            │
                            ▼
                         Jenkins
                            │
                            │ Docker Build
                            ▼
                      Docker Image
                            │
                            ▼
                       Amazon ECR
                      /     |     \
                     /      |      \
                Service   Service   Service
                 Repo      Repo      Repo
                   │         │         │
                   └─────────┼─────────┘
                             │
                             ▼
                         Amazon EKS
```

The AWS environment should contain an ECR repository for each microservice.

Jenkins should be capable of:

```text
Build
  │
  ▼
Tag
  │
  ▼
Authenticate
  │
  ▼
Push
  │
  ▼
Amazon ECR
```

The resulting container images should be ready for consumption by Kubernetes deployments.

---

# 🏁 Phase Completion Criteria

Phase 05 is considered complete when:

- [ ] All required ECR repositories are provisioned.
- [ ] One repository exists for each required microservice.
- [ ] Repository configuration is verified.
- [ ] Image scanning is enabled.
- [ ] Jenkins can authenticate with ECR.
- [ ] Microservice Docker images can be built successfully.
- [ ] Images can be tagged using Jenkins build numbers.
- [ ] Images can be pushed successfully to ECR.
- [ ] Images are visible in the AWS ECR console.
- [ ] Image tags provide Jenkins build traceability.
- [ ] ECR image scanning is verified.
- [ ] The resulting ECR image references are ready for Kubernetes deployment.
- [ ] Required implementation evidence has been captured.

---

# 📝 Outcome

At the end of Phase 05, the project has a functional Amazon ECR-based container image registry layer.

The resulting DevSecOps image flow is:

```text
                    Microservice Source
                           │
                           ▼
                      GitHub
                           │
                           ▼
                       Jenkins
                           │
                    Docker Build
                           │
                           ▼
                     Docker Image
                           │
                    Security Scan
                           │
                           ▼
                      Amazon ECR
                           │
                    Versioned Image
                           │
                           ▼
                    Kubernetes / EKS
                           │
                           ▼
                      Microservices
```

Amazon ECR now provides the centralized image distribution layer between the CI pipeline and the Kubernetes deployment platform.

This prepares the project for the next phase, where Jenkins CI automation will be implemented.

---

# 📚 Related Phases

| Phase | Documentation |
|---|---|
| Phase 01 | [AWS Microservices DevSecOps Architecture](../01-architecture/) |
| Phase 02 | [Terraform State Management](../02-terraform-state/) |
| Phase 03 | [AWS Network & Jump Host](../03-aws-network/) |
| Phase 04 | [Amazon EKS Cluster](../04-eks/) |
| Phase 05 | **Amazon ECR** |
| Phase 06 | [Jenkins CI](../06-jenkins-ci/) |
| Phase 07 | [Kubernetes](../07-kubernetes/) |
| Phase 08 | [Argo CD GitOps](../08-argocd/) |

---

# 🚀 Next Phase

**Phase 06 — Jenkins CI**

The next phase will implement the Jenkins CI pipeline responsible for automating:

```text
Source Checkout
      │
      ▼
Build
      │
      ▼
Test
      │
      ▼
Security Checks
      │
      ▼
Docker Build
      │
      ▼
ECR Authentication
      │
      ▼
Image Push
```

---

**Phase 05 — Amazon ECR**

**Status:** Container Registry Layer Implemented

**Next:** Phase 06 — Jenkins CI