# Phase 01 — AWS Microservices DevSecOps Architecture

## 📌 Overview

Phase 01 defines the overall architecture of the **AWS Microservices DevSecOps platform**.

The objective is to establish a production-oriented architecture that supports:

* Microservices-based application deployment
* Infrastructure as Code using Terraform
* Container image management using Amazon ECR
* Continuous Integration using Jenkins
* Kubernetes orchestration using Amazon EKS
* GitOps-based deployment using Argo CD
* DNS management using Amazon Route 53
* Application monitoring and alerting
* Secure and repeatable deployments
* Automated infrastructure lifecycle management

The architecture separates infrastructure provisioning, application build, deployment, configuration, monitoring, and DNS responsibilities into clearly defined layers.

---

## 🎯 Architecture Goals

The platform is designed around the following principles.

### 1. Infrastructure as Code

Terraform is used to provision and manage AWS infrastructure.

Key objectives:

* Provision AWS infrastructure using Terraform.
* Maintain infrastructure configuration in Git.
* Store Terraform state remotely in Amazon S3.
* Make infrastructure provisioning repeatable and automated.

### 2. Secure CI/CD

Jenkins provides the Continuous Integration layer.

The CI workflow is responsible for:

* Building individual microservices.
* Creating Docker container images.
* Performing security and quality checks.
* Pushing images to Amazon ECR.
* Updating deployment manifests.

### 3. Kubernetes Application Platform

Amazon EKS provides the managed Kubernetes platform for running microservices.

The Kubernetes layer uses:

* Deployments
* Services
* Namespaces
* ConfigMaps
* Secrets
* Application workloads

### 4. GitOps Deployment

Argo CD provides the Continuous Delivery and GitOps layer.

Git remains the source of truth for the desired Kubernetes deployment configuration.

Argo CD continuously compares the desired state stored in Git with the current state of the EKS cluster.

### 5. Observability

The platform includes an observability stack based on:

* Prometheus
* Grafana
* Alertmanager
* Prometheus alert rules

Prometheus collects metrics, Grafana provides visualization, and Alertmanager handles alert processing and notification routing.

### 6. DNS and Application Access

Amazon Route 53 provides DNS management for the application.

The application domain is mapped to the Kubernetes application endpoint so users can access the application through a domain name.

---

# 🏗️ High-Level Architecture

```text
                         ┌───────────────────────┐
                         │       Developer       │
                         │                       │
                         │   Git Push / PR       │
                         └───────────┬───────────┘
                                     │
                                     ▼
                         ┌───────────────────────┐
                         │       GitHub          │
                         │                       │
                         │ Application Source    │
                         │ Terraform             │
                         │ Kubernetes Manifests  │
                         └───────────┬───────────┘
                                     │
                    ┌────────────────┴────────────────┐
                    │                                 │
                    ▼                                 ▼
          ┌───────────────────┐             ┌───────────────────┐
          │      Jenkins      │             │     Terraform     │
          │        CI         │             │ Infrastructure    │
          └─────────┬─────────┘             └─────────┬─────────┘
                    │                                 │
                    │ Build                           │ Provision
                    ▼                                 ▼
          ┌───────────────────┐             ┌───────────────────┐
          │    Docker Build   │             │        AWS        │
          │   Microservices   │             │   Infrastructure  │
          └─────────┬─────────┘             └─────────┬─────────┘
                    │                                 │
                    ▼                                 ▼
          ┌───────────────────┐             ┌───────────────────┐
          │    Amazon ECR     │             │       VPC         │
          │ Container Images  │             │                   │
          └─────────┬─────────┘             │ Public / Private  │
                    │                       │ Subnets           │
                    │                       └─────────┬─────────┘
                    │                                 │
                    │                                 ▼
                    │                       ┌───────────────────┐
                    │                       │    Amazon EKS     │
                    │                       │                   │
                    └──────────────────────►│ Kubernetes        │
                                            │ Cluster           │
                                            └─────────┬─────────┘
                                                      │
                                                      ▼
                                            ┌───────────────────┐
                                            │   Microservices   │
                                            │                   │
                                            │ Deployments       │
                                            │ Services          │
                                            └─────────┬─────────┘
                                                      │
                                                      ▼
                                            ┌───────────────────┐
                                            │   Application     │
                                            │    Endpoint       │
                                            └─────────┬─────────┘
                                                      │
                                                      ▼
                                            ┌───────────────────┐
                                            │   Route 53 DNS    │
                                            │                   │
                                            │ Application       │
                                            │ Domain            │
                                            └───────────────────┘
```

---

# 🔄 GitOps Deployment Flow

```text
GitHub
   │
   ▼
Argo CD
   │
   │ Sync
   ▼
Amazon EKS
   │
   ▼
Kubernetes Pods
```

GitHub contains the desired Kubernetes deployment state.

Argo CD monitors the repository and synchronizes the desired state with the EKS cluster.

---

# 📊 Monitoring Architecture

```text
             EKS / Kubernetes Workloads
                         │
                         ▼
                    Prometheus
                         │
                 ┌───────┴───────┐
                 ▼               ▼
              Grafana       Alertmanager
                 │               │
                 ▼               ▼
             Dashboards         Alerts
```

### Monitoring Components

| Component    | Responsibility                            |
| ------------ | ----------------------------------------- |
| Prometheus   | Metrics collection                        |
| Grafana      | Metrics visualization and dashboards      |
| Alertmanager | Alert processing and notification routing |
| Alert Rules  | Define monitoring conditions              |

---

# 🧩 Architecture Components

## 1. GitHub

GitHub acts as the central source-control platform.

The repository contains:

* Terraform configurations
* Jenkins pipelines
* Kubernetes manifests
* Argo CD application definitions
* Monitoring configurations
* Deployment configuration
* Documentation

Git provides version control and traceability for infrastructure and application changes.

---

## 2. Terraform

Terraform is responsible for provisioning AWS infrastructure.

The infrastructure layer includes resources such as:

* VPC
* Subnets
* Internet Gateway
* Route Tables
* Security Groups
* IAM Roles
* IAM Policies
* EC2 Jump Host
* Amazon EKS
* Amazon ECR
* Supporting AWS resources

Terraform uses a remote backend to store state in Amazon S3.

Remote state allows infrastructure state to be persisted independently from the local development machine.

---

## 3. AWS VPC

The application platform runs inside an isolated AWS VPC.

The VPC provides:

* Network isolation
* Public subnets
* Private subnets
* Route tables
* Internet connectivity
* Security boundaries

The architecture separates externally accessible resources from internal workloads.

```text
                       AWS VPC
                          │
              ┌───────────┴───────────┐
              │                       │
              ▼                       ▼
       Public Subnets          Private Subnets
              │                       │
              ▼                       ▼
       Jump Host /              EKS Worker
       Public Access            Workloads
```

---

## 4. EC2 Jump Host

A dedicated EC2 instance is used as the administrative jump host.

The jump host provides a controlled environment for:

* AWS CLI
* kubectl
* Terraform
* Docker
* Jenkins administration
* Kubernetes administration
* Ansible
* Maven
* Node.js
* Security tools
* Troubleshooting

The jump host is provisioned through Terraform and configured automatically using a bootstrap script.

The bootstrap process installs the required DevOps tooling.

---

## 5. Amazon EKS

Amazon Elastic Kubernetes Service provides the managed Kubernetes control plane.

EKS is responsible for running the microservices application platform.

The Kubernetes layer contains:

* Kubernetes cluster
* Worker nodes
* Namespaces
* Deployments
* Services
* ConfigMaps
* Secrets
* Application workloads

The cluster is provisioned through Terraform.

---

## 6. Amazon ECR

Amazon Elastic Container Registry stores Docker images generated by the CI pipelines.

Each microservice can have its own ECR repository.

Example repository structure:

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
└── shippingservice
```

The CI pipeline builds the corresponding Docker image and pushes it to the appropriate ECR repository.

Example image:

```text
<aws-account-id>.dkr.ecr.<region>.amazonaws.com/adservice:<BUILD_NUMBER>
```

Versioned image tags allow deployments to reference specific application builds.

---

## 7. Jenkins CI

Jenkins provides the Continuous Integration layer.

A separate pipeline can be created for each microservice.

### Typical CI Pipeline

```text
GitHub
   │
   ▼
Checkout Source
   │
   ▼
Docker Build
   │
   ▼
Security / Quality Checks
   │
   ▼
Amazon ECR Login
   │
   ▼
Docker Image Push
   │
   ▼
Update Kubernetes Manifest
   │
   ▼
Git Push
```

The Jenkins pipeline builds the application container and pushes the image to Amazon ECR.

The deployment manifest is then updated with the new image version.

Argo CD subsequently handles deployment synchronization with the Kubernetes cluster.

---

## 8. Docker

Docker is used to package each microservice into a container image.

Each service contains its own Dockerfile and build context.

Example:

```text
src/
│
├── adservice/
│   └── Dockerfile
│
├── cartservice/
│   └── Dockerfile
│
├── checkoutservice/
│   └── Dockerfile
│
└── frontend/
    └── Dockerfile
```

Jenkins builds the image and pushes it to Amazon ECR.

---

## 9. Kubernetes

Kubernetes manages the application workloads running on Amazon EKS.

The Kubernetes configuration is organized into logical components.

```text
kubernetes/
│
├── namespace/
│
├── deployments/
│
├── services/
│
└── config/
```

### Kubernetes Resources

| Resource   | Purpose                               |
| ---------- | ------------------------------------- |
| Namespace  | Workload isolation                    |
| Deployment | Defines desired application workloads |
| Service    | Provides network access to workloads  |
| ConfigMap  | Provides application configuration    |
| Secret     | Provides sensitive application values |

---

## 10. Argo CD

Argo CD provides the GitOps Continuous Delivery layer.

The desired Kubernetes state is stored in Git.

```text
Git Desired State
       │
       ▼
    Argo CD
       │
       ▼
Current EKS State
```

If a difference is detected, Argo CD can synchronize the Kubernetes resources.

### GitOps Benefits

* Git-based deployment management
* Deployment history
* Drift detection
* Automated synchronization
* Centralized application visibility
* Declarative deployments

---

# 🔁 GitOps Deployment Model

The project follows the GitOps model.

```text
Developer
    │
    ▼
Application Code
    │
    ▼
GitHub
    │
    ▼
Jenkins
    │
    ├── Build Image
    │
    ├── Push Image to ECR
    │
    └── Update Kubernetes Manifest
              │
              ▼
           Git Commit
              │
              ▼
           Argo CD
              │
              ▼
           Amazon EKS
              │
              ▼
         Running Pods
```

The Git repository becomes the source of truth for the desired Kubernetes deployment state.

---

## 11. Route 53

Amazon Route 53 provides DNS management for the application.

The application domain is configured through a Route 53 hosted zone.

```text
Application Domain
       │
       ▼
   Route 53
       │
       ▼
Application Endpoint
       │
       ▼
   Amazon EKS
```

DNS configuration allows users to access the application using a domain name instead of directly accessing the Kubernetes load balancer endpoint.

---

## 12. Monitoring

The monitoring layer provides visibility into the Kubernetes platform.

The monitoring architecture contains:

```text
Amazon EKS
    │
    ▼
Prometheus
    │
    ├───────────────┐
    ▼               ▼
 Grafana       Alertmanager
    │               │
    ▼               ▼
Dashboards        Alerts
```

### Responsibilities

**Prometheus**

* Collects metrics.
* Evaluates alert rules.

**Grafana**

* Provides visualization.
* Provides monitoring dashboards.

**Alertmanager**

* Processes alerts.
* Handles alert routing and notification.

---

# 🔐 Security Architecture

Security is implemented across multiple layers.

## Infrastructure Security

The infrastructure layer uses:

* IAM roles
* IAM policies
* Security groups
* Private subnets
* Controlled network access

## CI Security

The CI layer can integrate security and quality tools such as:

* SonarQube
* Trivy
* Terraform security scanning
* Secret scanning
* Dependency scanning

## Container Security

Container images can be scanned before deployment.

## Kubernetes Security

Kubernetes security controls include:

* Namespaces
* RBAC
* Service accounts
* Secrets
* Network controls
* Least-privilege access

---

# ☁️ Infrastructure Provisioning Flow

The infrastructure provisioning flow is:

```text
Terraform Code
      │
      ▼
Terraform Init
      │
      ▼
Terraform Plan
      │
      ▼
Terraform Apply
      │
      ▼
AWS Infrastructure
      │
      ├── VPC
      ├── Subnets
      ├── IAM
      ├── Jump Host
      ├── EKS
      └── ECR
```

Terraform state is stored remotely to provide centralized state management.

---

# 🚀 Application Delivery Flow

The application delivery flow is:

```text
Developer
    │
    ▼
GitHub
    │
    ▼
Jenkins
    │
    ├── Checkout
    ├── Build
    ├── Test
    ├── Security Scan
    ├── Docker Build
    └── Push Image
              │
              ▼
             ECR
              │
              ▼
      Kubernetes Manifest
         updated in Git
              │
              ▼
           Argo CD
              │
              ▼
             EKS
              │
              ▼
       Microservice Pods
```

---

# 🌍 Environment Separation

The architecture can be extended to support multiple environments.

Environment separation can be achieved using:

* Different Terraform state locations
* Different AWS resources
* Different Kubernetes namespaces
* Different ECR repositories
* Different Git branches or repositories
* Different configuration files

Example:

```text
Environment
│
├── Development
│
├── Staging
│
└── Production
```

---

# 📁 Repository Architecture

The implementation repository follows this structure:

```text
aws-microservices-devsecops-implementation/
│
├── README.md
├── .gitignore
│
├── docs/
│   ├── 01-architecture/
│   │   └── README.md
│   │
│   ├── 02-terraform-state/
│   │   └── README.md
│   │
│   ├── 03-aws-network-and-jumphost/
│   │   └── README.md
│   │
│   ├── 04-eks/
│   │   └── README.md
│   │
│   ├── 05-ecr/
│   │   └── README.md
│   │
│   ├── 06-jenkins-ci/
│   │   └── README.md
│   │
│   ├── 07-kubernetes/
│   │   └── README.md
│   │
│   ├── 08-argocd-gitops/
│   │   └── README.md
│   │
│   ├── 09-route53-dns/
│   │   └── README.md
│   │
│   ├── 10-monitoring/
│   │   └── README.md
│   │
│   ├── 11-alerting/
│   │   └── README.md
│   │
│   └── 12-end-to-end-validation/
│       └── README.md
│
├── terraform/
│   ├── backend/
│   ├── network/
│   ├── eks/
│   └── ecr/
│
├── jenkins/
│   ├── terraform/
│   └── microservices/
│
├── kubernetes/
│   ├── namespace/
│   ├── deployments/
│   ├── services/
│   └── config/
│
├── argocd/
│   └── applications/
│
├── monitoring/
│   ├── prometheus/
│   ├── grafana/
│   ├── alertmanager/
│   └── alert-rules/
│
├── scripts/
│
└── evidence/
    ├── 01-architecture/
    ├── 02-terraform/
    ├── 03-aws-network/
    ├── 04-eks/
    ├── 05-ecr/
    ├── 06-jenkins/
    ├── 07-kubernetes/
    ├── 08-argocd/
    ├── 09-route53/
    ├── 10-monitoring/
    ├── 11-alerting/
    └── 12-end-to-end/
```

---

# 🧱 Design Principles

The architecture follows these core DevOps principles.

### Infrastructure as Code

AWS infrastructure is defined using Terraform instead of manual provisioning.

### Automation

Infrastructure, image builds, and deployment workflows are automated.

### GitOps

Git represents the desired application deployment state.

### Immutable Artifacts

Container images are versioned and stored in Amazon ECR.

### Separation of Responsibilities

Each platform component has a clearly defined responsibility:

```text
Terraform
   │
   └── AWS Infrastructure

Jenkins
   │
   └── Continuous Integration

Amazon ECR
   │
   └── Container Registry

Argo CD
   │
   └── Continuous Delivery

Amazon EKS
   │
   └── Application Runtime

Prometheus / Grafana / Alertmanager
   │
   └── Observability
```

---

# 🔐 Security by Design

Security controls are incorporated across:

* AWS infrastructure
* IAM
* Network configuration
* CI pipelines
* Container images
* Kubernetes
* GitOps workflows

The architecture is designed to support secure, repeatable, and controlled application delivery.

---

# 🎯 Expected End State

After completing all project phases, the platform should provide the following end-to-end workflow:

```text
                    ┌─────────────┐
                    │  Developer  │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   GitHub    │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Jenkins   │
                    │     CI      │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │     ECR     │
                    │ Docker Img  │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │ Kubernetes  │
                    │  Manifests  │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Argo CD   │
                    │    GitOps   │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │    EKS      │
                    └──────┬──────┘
                           │
                ┌──────────┴──────────┐
                │                     │
                ▼                     ▼
         ┌─────────────┐       ┌─────────────┐
         │Microservices│       │ Monitoring  │
         │  Workloads  │       │ Prometheus  │
         └──────┬──────┘       │ Grafana     │
                │              │ Alertmanager│
                │              └─────────────┘
                ▼
         ┌─────────────┐
         │ Application │
         │    Access   │
         └──────┬──────┘
                │
                ▼
         ┌─────────────┐
         │  Route 53   │
         │    DNS      │
         └─────────────┘
```

---

# 🔗 Phase Dependencies

The implementation phases are intentionally ordered to build the platform progressively.

```text
01 — Architecture
        │
        ▼
02 — Terraform State
        │
        ▼
03 — AWS Network & Jump Host
        │
        ▼
04 — Amazon EKS
        │
        ▼
05 — Amazon ECR
        │
        ▼
06 — Jenkins CI
        │
        ▼
07 — Kubernetes
        │
        ▼
08 — Argo CD GitOps
        │
        ▼
09 — Route 53 DNS
        │
        ▼
10 — Monitoring
        │
        ▼
11 — Alerting
        │
        ▼
12 — End-to-End Validation
```

Each phase builds on the infrastructure and configuration established by the previous phase.

---

# 📸 Evidence Collection

Evidence for Phase 01 should demonstrate the architecture and major platform components.

Recommended evidence structure:

```text
evidence/01-architecture/
│
├── architecture-diagram.png
├── repository-structure.png
├── aws-services-overview.png
└── deployment-flow.png
```

### 🔒 Sensitive Information

Evidence must not expose sensitive information such as:

* AWS access keys
* AWS secret keys
* GitHub tokens
* Kubernetes secrets
* Passwords
* Private credentials
* Sensitive account information

---

# ✅ Phase 01 Completion Checklist

* [ ] Overall AWS architecture defined
* [ ] DevSecOps workflow defined
* [ ] Terraform infrastructure layer identified
* [ ] AWS networking layer identified
* [ ] Jump Host layer identified
* [ ] Amazon EKS platform identified
* [ ] Amazon ECR container registry identified
* [ ] Jenkins CI workflow defined
* [ ] Docker containerization layer identified
* [ ] Kubernetes deployment layer identified
* [ ] Argo CD GitOps workflow defined
* [ ] Route 53 DNS layer identified
* [ ] Monitoring architecture defined
* [ ] Alerting architecture defined
* [ ] Evidence structure defined

---

# 📌 Phase Status

| Area                | Status      |
| ------------------- | ----------- |
| Architecture Design | ✅ Completed |
| DevSecOps Workflow  | ✅ Defined   |
| Terraform Layer     | ✅ Defined   |
| AWS Networking      | ✅ Defined   |
| Jump Host           | ✅ Defined   |
| Amazon EKS          | ✅ Defined   |
| Amazon ECR          | ✅ Defined   |
| Jenkins CI          | ✅ Defined   |
| Docker              | ✅ Defined   |
| Kubernetes          | ✅ Defined   |
| Argo CD GitOps      | ✅ Defined   |
| Route 53            | ✅ Defined   |
| Monitoring          | ✅ Defined   |
| Alerting            | ✅ Defined   |
| Evidence Structure  | ✅ Defined   |

---

# 📝 Conclusion

Phase 01 establishes the architectural foundation for the **AWS Microservices DevSecOps platform**.

The platform follows a clear separation of responsibilities:

```text
Terraform
   │
   └── AWS Infrastructure

Jenkins
   │
   └── Continuous Integration

Amazon ECR
   │
   └── Container Image Registry

Amazon EKS
   │
   └── Kubernetes Application Runtime

Argo CD
   │
   └── GitOps Continuous Delivery

Route 53
   │
   └── DNS

Prometheus / Grafana / Alertmanager
   │
   └── Observability and Alerting
```

The resulting architecture provides a foundation for automating the application lifecycle from source-code change through container image creation, GitOps deployment, application access, monitoring, and alerting.

---

**Next Phase:** [Phase 02 — Terraform State](../02-terraform-state/)
