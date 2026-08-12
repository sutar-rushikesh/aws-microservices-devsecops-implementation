# Phase 01 — AWS Microservices DevSecOps Architecture

## Overview

This phase defines the overall architecture of the AWS Microservices DevSecOps platform.

The objective is to design a production-oriented architecture that supports:

- Microservices-based application deployment
- Infrastructure as Code using Terraform
- Container image management using Amazon ECR
- Continuous Integration using Jenkins
- Kubernetes orchestration using Amazon EKS
- GitOps-based deployment using Argo CD
- DNS management using Amazon Route 53
- Application monitoring and alerting
- Secure and repeatable deployments
- Automated infrastructure lifecycle management

This architecture separates infrastructure provisioning, application build, deployment, configuration, monitoring, and DNS responsibilities into clearly defined layers.

---

# Architecture Goals

The platform is designed with the following goals:

1. **Infrastructure as Code**
   - Provision AWS infrastructure using Terraform.
   - Maintain infrastructure configuration in Git.
   - Use remote Terraform state stored in Amazon S3.

2. **Secure CI/CD**
   - Use Jenkins for continuous integration.
   - Build container images for individual microservices.
   - Push images to Amazon ECR.
   - Automate deployment manifest updates.

3. **Kubernetes-based Application Platform**
   - Run microservices on Amazon EKS.
   - Use Kubernetes Deployments and Services.
   - Isolate application workloads using Kubernetes namespaces.

4. **GitOps Deployment**
   - Use Argo CD to continuously synchronize Kubernetes manifests.
   - Git remains the source of truth for application deployment configuration.

5. **Observability**
   - Monitor Kubernetes workloads and infrastructure.
   - Collect metrics using Prometheus.
   - Visualize metrics using Grafana.
   - Configure alerting through Alertmanager and Prometheus alert rules.

6. **DNS and Application Access**
   - Use Amazon Route 53 for DNS management.
   - Map the application domain to the Kubernetes application endpoint.

---

# High-Level Architecture

```text
                         ┌───────────────────────┐
                         │       Developer       │
                         │                       │
                         │  Git Push / PR        │
                         └───────────┬───────────┘
                                     │
                                     ▼
                         ┌───────────────────────┐
                         │       GitHub          │
                         │                       │
                         │ Application Source   │
                         │ Terraform             │
                         │ Kubernetes Manifests  │
                         └───────────┬───────────┘
                                     │
                    ┌────────────────┴────────────────┐
                    │                                 │
                    ▼                                 ▼
          ┌───────────────────┐             ┌───────────────────┐
          │     Jenkins       │             │     Terraform     │
          │       CI          │             │ Infrastructure    │
          └─────────┬─────────┘             └─────────┬─────────┘
                    │                                 │
                    │ Build                           │ Provision
                    ▼                                 ▼
          ┌───────────────────┐             ┌───────────────────┐
          │    Docker Build   │             │       AWS         │
          │   Microservices   │             │   Infrastructure  │
          └─────────┬─────────┘             └─────────┬─────────┘
                    │                                 │
                    ▼                                 │
          ┌───────────────────┐                       │
          │    Amazon ECR     │                       │
          │ Container Images  │                       │
          └─────────┬─────────┘                       │
                    │                                 │
                    │ Image                           │
                    │                                 ▼
                    │                       ┌───────────────────┐
                    │                       │       VPC         │
                    │                       │                   │
                    │                       │ Public / Private  │
                    │                       │ Subnets           │
                    │                       └─────────┬─────────┘
                    │                                 │
                    │                                 ▼
                    │                       ┌───────────────────┐
                    │                       │     Amazon EKS    │
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


                     GitOps Deployment Flow

          GitHub ───────────────► Argo CD
                                    │
                                    │ Sync
                                    ▼
                              Amazon EKS
                                    │
                                    ▼
                             Kubernetes Pods


                     Monitoring Flow

             EKS / Kubernetes Workloads
                       │
                       ▼
                  Prometheus
                       │
              ┌────────┴────────┐
              ▼                 ▼
           Grafana          Alertmanager
              │                 │
              ▼                 ▼
         Dashboards          Alerts




### 
Architecture Components
1. GitHub

GitHub acts as the central source-control platform.

The repository contains:

Terraform configurations
Jenkins pipelines
Kubernetes manifests
Argo CD application definitions
Monitoring configurations
Deployment configuration
Documentation

Git provides version control and traceability for infrastructure and application changes.

2. Terraform

Terraform is responsible for provisioning AWS infrastructure.

The infrastructure layer includes resources such as:

VPC
Subnets
Internet Gateway
Route Tables
Security Groups
IAM Roles
IAM Policies
EC2 Jump Host
Amazon EKS
Amazon ECR
Supporting AWS resources

Terraform uses a remote backend to store state in Amazon S3.

Remote state allows infrastructure state to be persisted independently from the local development machine.

3. AWS VPC

The application platform runs inside an isolated AWS VPC.

The VPC provides:

Network isolation
Public subnets
Private subnets
Route tables
Internet connectivity
Security boundaries

A typical architecture separates externally accessible resources from internal workloads.

                         AWS VPC
                            |
              +-------------+-------------+
              |                           |
              v                           v
       Public Subnets              Private Subnets
              |                           |
              |                           |
        Jump Host /                 EKS Worker
        Public Access               Workloads
4. Jump Host

A dedicated EC2 instance is used as the administrative jump host.

The jump host provides a controlled environment for:

AWS CLI
kubectl
Terraform
Docker
Jenkins administration
Kubernetes administration
Ansible
Maven
Node.js
Security tools
Troubleshooting

The jump host is provisioned through Terraform and configured automatically using a bootstrap script.

The bootstrap process installs the required DevOps tooling.

5. Amazon EKS

Amazon Elastic Kubernetes Service provides the managed Kubernetes control plane.

EKS is responsible for running the microservices application platform.

The Kubernetes layer contains:

Kubernetes cluster
Worker nodes
Namespaces
Deployments
Services
ConfigMaps
Secrets
Application workloads

The cluster is provisioned through Terraform.

6. Amazon ECR

Amazon Elastic Container Registry stores Docker images generated by the CI pipelines.

Each microservice can have its own ECR repository.

Example:

Amazon ECR
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

The CI pipeline builds the corresponding Docker image and pushes it to the appropriate ECR repository.

Example image:

<aws-account-id>.dkr.ecr.<region>.amazonaws.com/adservice:<BUILD_NUMBER>

Using versioned image tags allows deployments to reference specific application builds.

7. Jenkins CI

Jenkins provides the Continuous Integration layer.

A separate pipeline can be created for each microservice.

Typical pipeline flow:

GitHub
   |
   v
Checkout Source
   |
   v
Docker Build
   |
   v
Security / Quality Checks
   |
   v
Amazon ECR Login
   |
   v
Docker Image Push
   |
   v
Update Kubernetes Manifest
   |
   v
Git Push

The Jenkins pipeline builds the application container and pushes the image to Amazon ECR.

The deployment manifest is then updated with the new image version.

Argo CD subsequently handles deployment synchronization with the Kubernetes cluster.

8. Docker

Docker is used to package each microservice into a container image.

Each service contains its own Dockerfile and build context.

Example:

src/
|
+-- adservice/
|   +-- Dockerfile
|
+-- cartservice/
|   +-- Dockerfile
|
+-- checkoutservice/
|   +-- Dockerfile
|
+-- frontend/
    +-- Dockerfile

Jenkins builds the image and pushes it to Amazon ECR.

9. Kubernetes

Kubernetes manages the application workloads running on Amazon EKS.

The Kubernetes configuration is organized into logical components.

kubernetes/
|
+-- namespace/
|
+-- deployments/
|
+-- services/
|
+-- config/

Deployments define the desired application workloads.

Services provide network access to the workloads.

ConfigMaps and Secrets provide configuration and sensitive application values where required.

10. Argo CD

Argo CD provides the GitOps continuous delivery layer.

The desired Kubernetes state is stored in Git.

Argo CD continuously compares:

Git Desired State
        |
        v
     Argo CD
        |
        v
Current EKS State

If a difference is detected, Argo CD can synchronize the Kubernetes resources.

This provides:

Git-based deployment management
Deployment history
Drift detection
Automated synchronization
Centralized application visibility
Declarative deployments
11. GitOps Deployment Model

The project follows the GitOps model.

Developer
    |
    v
Application Code
    |
    v
GitHub
    |
    v
Jenkins
    |
    +-- Build Image
    |
    +-- Push Image to ECR
    |
    +-- Update Kubernetes Manifest
             |
             v
         Git Commit
             |
             v
          Argo CD
             |
             v
          Amazon EKS
             |
             v
        Running Pods

The Git repository therefore becomes the source of truth for the desired Kubernetes deployment state.

12. Route 53

Amazon Route 53 provides DNS management for the application.

The application domain is configured through a Route 53 hosted zone.

Example:

Application Domain
        |
        v
    Route 53
        |
        v
Application Endpoint
        |
        v
     Amazon EKS

DNS configuration allows users to access the application using a domain name instead of directly accessing the Kubernetes load balancer endpoint.

13. Monitoring

The monitoring layer provides visibility into the Kubernetes platform.

The monitoring architecture contains:

Amazon EKS
    |
    v
Prometheus
    |
    +------------------+
    |                  |
    v                  v
 Grafana          Alertmanager
    |                  |
    v                  v
Dashboards           Alerts

Prometheus collects metrics.

Grafana provides visualization and dashboards.

Alertmanager handles alert routing and notification.

14. Security Architecture

Security is implemented across multiple layers.

Infrastructure Security
IAM roles
IAM policies
Security groups
Private subnets
Controlled network access
CI Security

The CI layer can integrate security and quality tools such as:

SonarQube
Trivy
Terraform security scanning
Secret scanning
Dependency scanning
Container Security

Container images can be scanned before deployment.

Kubernetes Security

Kubernetes security controls include:

Namespaces
RBAC
Service accounts
Secrets
Network controls
Least-privilege access
Infrastructure Flow

The infrastructure provisioning flow is:

Terraform Code
      |
      v
Terraform Init
      |
      v
Terraform Plan
      |
      v
Terraform Apply
      |
      v
AWS Infrastructure
      |
      +-- VPC
      +-- Subnets
      +-- IAM
      +-- Jump Host
      +-- EKS
      +-- ECR

Terraform state is stored remotely to provide centralized state management.

Application Delivery Flow

The application delivery flow is:

Developer
    |
    v
GitHub
    |
    v
Jenkins
    |
    +-- Checkout
    |
    +-- Build
    |
    +-- Test
    |
    +-- Security Scan
    |
    +-- Docker Build
    |
    +-- Push Image
              |
              v
            ECR
              |
              v
      Kubernetes Manifest
          updated in Git
              |
              v
            Argo CD
              |
              v
             EKS
              |
              v
        Microservice Pods
Environment Separation

The architecture can be extended to support multiple environments.

Environment separation can be achieved using:

Different Terraform state locations
Different AWS resources
Different Kubernetes namespaces
Different ECR repositories
Different Git branches or repositories
Different configuration files

Example:

Environment
|
+-- Development
|
+-- Staging
|
+-- Production
Repository Architecture

The implementation repository follows this structure:

aws-microservices-devsecops-implementation/
|
+-- README.md
+-- .gitignore
|
+-- docs/
|   |
|   +-- 01-architecture/
|   |   +-- README.md
|   |
|   +-- 02-terraform-state/
|   |   +-- README.md
|   |
|   +-- 03-aws-network-and-jumphost/
|   |   +-- README.md
|   |
|   +-- 04-eks/
|   |   +-- README.md
|   |
|   +-- 05-ecr/
|   |   +-- README.md
|   |
|   +-- 06-jenkins-ci/
|   |   +-- README.md
|   |
|   +-- 07-kubernetes/
|   |   +-- README.md
|   |
|   +-- 08-argocd-gitops/
|   |   +-- README.md
|   |
|   +-- 09-route53-dns/
|   |   +-- README.md
|   |
|   +-- 10-monitoring/
|   |   +-- README.md
|   |
|   +-- 11-alerting/
|   |   +-- README.md
|   |
|   +-- 12-end-to-end-validation/
|       +-- README.md
|
+-- terraform/
|   |
|   +-- backend/
|   +-- network/
|   +-- eks/
|   +-- ecr/
|
+-- jenkins/
|   |
|   +-- terraform/
|   +-- microservices/
|
+-- kubernetes/
|   |
|   +-- namespace/
|   +-- deployments/
|   +-- services/
|   +-- config/
|
+-- argocd/
|   |
|   +-- applications/
|
+-- monitoring/
|   |
|   +-- prometheus/
|   +-- grafana/
|   +-- alertmanager/
|   +-- alert-rules/
|
+-- scripts/
|
+-- evidence/
    |
    +-- 01-architecture/
    +-- 02-terraform/
    +-- 03-aws-network/
    +-- 04-eks/
    +-- 05-ecr/
    +-- 06-jenkins/
    +-- 07-kubernetes/
    +-- 08-argocd/
    +-- 09-route53/
    +-- 10-monitoring/
    +-- 11-alerting/
    +-- 12-end-to-end/
Design Principles

The architecture follows these core DevOps principles.

Infrastructure as Code

AWS infrastructure is defined using Terraform instead of manual provisioning.

Automation

Infrastructure, image builds, and deployment workflows are automated.

GitOps

Git represents the desired application deployment state.

Immutable Artifacts

Container images are versioned and stored in Amazon ECR.

Separation of Responsibilities

The platform separates responsibilities as follows:

Terraform
   |
   +-- AWS Infrastructure


Jenkins
   |
   +-- Continuous Integration


ECR
   |
   +-- Container Registry


Argo CD
   |
   +-- Continuous Delivery


EKS
   |
   +-- Application Runtime


Prometheus / Grafana / Alertmanager
   |
   +-- Observability
Security by Design

Security controls are incorporated into infrastructure, CI, containers, and Kubernetes.

Expected End State

After completing all phases, the platform should provide the following end-to-end workflow:

                    +-------------+
                    |  Developer  |
                    +------+------+
                           |
                           v
                    +-------------+
                    |   GitHub    |
                    +------+------+
                           |
                           v
                    +-------------+
                    |   Jenkins   |
                    |     CI      |
                    +------+------+
                           |
                           v
                    +-------------+
                    |     ECR     |
                    | Docker Img  |
                    +------+------+
                           |
                           v
                    +-------------+
                    | Kubernetes  |
                    |  Manifests  |
                    +------+------+
                           |
                           v
                    +-------------+
                    |   Argo CD   |
                    |    GitOps   |
                    +------+------+
                           |
                           v
                    +-------------+
                    |    EKS      |
                    +------+------+
                           |
              +------------+------------+
              |                         |
              v                         v
       +-------------+          +-------------+
       |Microservices|          | Monitoring  |
       | Workloads   |          | Prometheus  |
       +------+------+          | Grafana     |
              |                 | Alertmanager|
              |                 +-------------+
              v
       +-------------+
       | Application |
       |   Access    |
       +------+------+
              |
              v
       +-------------+
       |  Route 53   |
       |    DNS      |
       +-------------+
Phase Dependencies

The implementation phases are intentionally ordered to build the platform progressively.

01 Architecture
       |
       v
02 Terraform State
       |
       v
03 AWS Network & Jump Host
       |
       v
04 EKS
       |
       v
05 ECR
       |
       v
06 Jenkins CI
       |
       v
07 Kubernetes
       |
       v
08 Argo CD GitOps
       |
       v
09 Route 53 DNS
       |
       v
10 Monitoring
       |
       v
11 Alerting
       |
       v
12 End-to-End Validation

Each phase builds on the infrastructure and configuration established by the previous phase.

Evidence Collection

Evidence for this phase should demonstrate the architecture and major platform components.

Recommended evidence:

evidence/01-architecture/
|
+-- architecture-diagram.png
+-- repository-structure.png
+-- aws-services-overview.png
+-- deployment-flow.png

Evidence should avoid exposing:

AWS access keys
AWS secret keys
GitHub tokens
Kubernetes secrets
Passwords
Private credentials
Sensitive account information
Phase 01 Completion Checklist
 Overall AWS architecture defined
 DevSecOps workflow defined
 Terraform infrastructure layer identified
 AWS networking layer identified
 Jump Host layer identified
 EKS platform identified
 ECR container registry identified
 Jenkins CI workflow defined
 Docker containerization layer identified
 Kubernetes deployment layer identified
 Argo CD GitOps workflow defined
 Route 53 DNS layer identified
 Monitoring architecture defined
 Alerting architecture defined
 Evidence structure defined
Conclusion

Phase 01 establishes the architectural foundation for the AWS Microservices DevSecOps platform.

The platform follows a clear separation of concerns:

Terraform
    |
    +-- AWS Infrastructure


Jenkins
    |
    +-- Continuous Integration


Amazon ECR
    |
    +-- Container Image Registry


Amazon EKS
    |
    +-- Kubernetes Application Runtime


Argo CD
    |
    +-- GitOps Continuous Delivery


Route 53
    |
    +-- DNS


Prometheus / Grafana / Alertmanager
    |
    +-- Observability and Alerting

The resulting architecture provides a foundation for automating the application lifecycle from source-code change through container image creation, GitOps deployment, application access, monitoring, and alerting.