# Phase 12 — End-to-End Validation

## Overview

This phase validates the complete AWS microservices DevSecOps platform from infrastructure provisioning through application deployment, GitOps synchronization, DNS access, monitoring, and alerting.

The objective is to verify that all implemented phases work together as a complete platform.

The validation covers:

- AWS infrastructure
- Terraform
- Amazon EKS
- Amazon ECR
- Jenkins CI
- Docker image builds
- Kubernetes deployments
- Argo CD GitOps
- Route 53 DNS
- Application accessibility
- Prometheus monitoring
- Grafana dashboards
- Alertmanager alerting

This is the final validation phase of the implementation.

---

# 1. End-to-End Architecture

```text
                         Developer
                             |
                             v
                       Git Repository
                             |
              +--------------+--------------+
              |                             |
              v                             v
        Terraform Code                 Application Code
              |                             |
              v                             v
        Jenkins CI/CD                  Jenkins CI
              |                             |
              |                             v
              |                       Docker Build
              |                             |
              |                             v
              |                         Amazon ECR
              |                             |
              |                             v
              |                     Kubernetes Manifest
              |                       Git Repository
              |                             |
              |                             v
              |                         Argo CD
              |                             |
              |                             v
              |                       Amazon EKS
              |                             |
              +-----------------------------+
                            |
                            v
                       Microservices
                            |
                            v
                      Application UI
                            |
                            v
                       Route 53 DNS

                            |
                            v
                     Prometheus
                            |
                            v
                         Grafana
                            |
                            v
                      Alertmanager
                            |
                            v
                       Notifications
```

# 2. Validation Objectives

The final validation should confirm that:

AWS infrastructure is correctly provisioned.
Terraform state is functioning correctly.
The jump host is accessible.
Amazon EKS is healthy.
EKS worker nodes are ready.
Amazon ECR repositories are available.
Docker images are successfully pushed.
Jenkins pipelines execute successfully.
Kubernetes workloads are deployed.
Kubernetes services are available.
Argo CD applications are synchronized.
Application manifests are managed through GitOps.
Route 53 resolves the application domain.
The application is accessible through the domain.
Prometheus collects metrics.
Grafana displays metrics.
Alert rules are evaluated.
Alertmanager receives alerts.
End-to-end application delivery is validated.
Evidence is captured for the completed implementation.

# 3. Prerequisites

Before starting final validation, verify that the required components have been implemented.

Required components:

AWS account
Terraform
Amazon VPC
Jump host
Amazon EKS
Amazon ECR
Jenkins
Docker
Kubernetes
Argo CD
Route 53
Prometheus
Grafana
Alertmanager
Application microservices

# 4. Phase Validation

The final validation should cover all previous phases.

Phase 01  Architecture
Phase 02  Terraform State
Phase 03  AWS Network and Jump Host
Phase 04  EKS
Phase 05  ECR
Phase 06  Jenkins CI
Phase 07  Kubernetes
Phase 08  Argo CD GitOps
Phase 09  Route 53 DNS
Phase 10  Monitoring
Phase 11  Alerting
Phase 12  End-to-End Validation

# 5. AWS Account Validation

Verify the AWS identity:

```bash
aws sts get-caller-identity
```

Expected output should show the expected AWS account and identity.

Verify the configured AWS region:

```bash
aws configure get region
```

Example:

```text
us-east-1
```

# 6. VPC Validation

List VPCs:

```bash
aws ec2 describe-vpcs \
  --region us-east-1 \
  --output table
```

Verify the project VPC exists.

Check subnets:

```bash
aws ec2 describe-subnets \
  --region us-east-1 \
  --output table
```

Verify:

Public subnet
Private subnet
Correct availability zones
Correct VPC association

# 7. Jump Host Validation

Verify that the jump host EC2 instance is running.

```bash
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:Name,Values=twr*" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,PrivateIpAddress,PublicIpAddress]' \
  --output table
```

Connect to the jump host.

Verify AWS CLI:

```bash
aws --version
```

Verify Terraform:

```bash
terraform version
```

Verify Docker:

```bash
docker --version
```

Verify kubectl:

```bash
kubectl version --client
```

Verify Git:

```bash
git --version
```

Verify Java:

```bash
java --version
```

Verify Jenkins if installed on the jump host:

```bash
jenkins --version
```

# 8. Terraform Validation

Navigate to the Terraform implementation directory.

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

Review the Terraform plan:

```bash
terraform plan
```

The plan should be reviewed before applying infrastructure changes.

# 9. Terraform State Validation

Verify the configured backend.

Example:

```bash
terraform state list
```

The state should contain the expected resources when the infrastructure is managed by that Terraform state.

Verify that the backend state is available in the configured S3 bucket.

Do not expose:

AWS credentials
Terraform state containing sensitive values
Access keys
Secrets

in screenshots or Git repositories.

# 10. EKS Validation

Verify the EKS cluster:

```bash
aws eks describe-cluster \
  --region us-east-1 \
  --name twr-eks \
  --query 'cluster.status' \
  --output text
```

Expected:

```text
ACTIVE
```

Verify Kubernetes version:

```bash
aws eks describe-cluster \
  --region us-east-1 \
  --name twr-eks \
  --query 'cluster.version' \
  --output text
```

# 11. Configure kubectl

Update kubeconfig:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name twr-eks
```

Verify the current context:

```bash
kubectl config current-context
```

Expected context should reference the EKS cluster.

# 12. EKS Node Validation

List worker nodes:

```bash
kubectl get nodes
```

Expected:

```text
NAME                           STATUS   ROLES
<node-name>                    Ready    <none>
```

All expected worker nodes should be in:

```text
Ready
```

status.

Get additional information:

```bash
kubectl get nodes -o wide
```

# 13. Kubernetes System Validation

Check system namespaces:

```bash
kubectl get namespaces
```

Check system pods:

```bash
kubectl get pods -n kube-system
```

System components should be healthy.

Check all pods:

```bash
kubectl get pods -A
```

Investigate any pods that are:

Pending
CrashLoopBackOff
ImagePullBackOff
Error
ContainerCreating

# 14. ECR Validation

List ECR repositories:

```bash
aws ecr describe-repositories \
  --region us-east-1 \
  --output table
```

Verify that the expected microservice repositories exist.

Example:

```text
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
```

The actual repository list depends on the services implemented in the project.

# 15. ECR Image Validation

Verify images:

```bash
aws ecr describe-images \
  --repository-name <repository-name> \
  --region us-east-1 \
  --output table
```

Verify that the expected image tags exist.

Example:

```text
1
2
3
latest
```

depending on the CI/CD tagging strategy.

# 16. Jenkins Validation

Open Jenkins.

Verify that the required pipelines exist.

Expected pipeline categories:

Terraform pipelines
Microservice CI pipelines

Verify that the latest builds completed successfully.

Jenkins jobs should show:

```text
SUCCESS
```

for successful builds.

# 17. Jenkins Terraform Pipeline Validation

Verify the infrastructure pipeline.

Expected stages may include:

Checkout
Terraform Version
Terraform Init
Terraform Validate
Terraform Plan
Terraform Apply

For destroy workflows, the pipeline may include:

Terraform Destroy

Verify that Terraform operations complete without errors.

# 18. Jenkins Microservice Pipeline Validation

Each microservice CI pipeline should perform the required workflow.

Typical flow:

```text
Checkout
   |
   v
Docker Build
   |
   v
Docker Image
   |
   v
Amazon ECR
   |
   v
Update Kubernetes Manifest
   |
   v
Git Push
```

Verify the pipeline logs for each service.

# 19. Docker Image Validation

On the Jenkins host or appropriate build environment:

```bash
docker images
```

Verify that the required microservice images were successfully built.

Verify Docker authentication:

```bash
aws ecr get-login-password \
  --region us-east-1 | \
docker login \
  --username AWS \
  --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

Do not capture or store authentication credentials.

# 20. Kubernetes Namespace Validation

List namespaces:

```bash
kubectl get namespaces
```

Verify the application namespace.

Example:

```bash
kubectl get namespace <application-namespace>
```

# 21. Kubernetes Deployment Validation

List deployments:

```bash
kubectl get deployments -A
```

Check application deployments:

```bash
kubectl get deployments -n <application-namespace>
```

Verify:

READY
UP-TO-DATE
AVAILABLE

values are correct.

# 22. Kubernetes Pod Validation

List application pods:

```bash
kubectl get pods -n <application-namespace>
```

Expected:

```text
STATUS = Running
```

Verify the number of ready replicas.

Example:

```text
READY   STATUS
1/1     Running
```

# 23. Kubernetes Service Validation

List services:

```bash
kubectl get svc -n <application-namespace>
```

Verify that the expected services exist.

Check service details:

```bash
kubectl describe svc <service-name> \
  -n <application-namespace>
```

# 24. Kubernetes Application Validation

Check application endpoints:

```bash
kubectl get endpoints -n <application-namespace>
```

Verify that services have healthy endpoints.

If endpoints are missing, investigate:

```bash
kubectl get pods -n <application-namespace>
kubectl describe svc <service-name> -n <application-namespace>
```

# 25. Argo CD Validation

Verify Argo CD namespace:

```bash
kubectl get namespace argocd
```

Check Argo CD pods:

```bash
kubectl get pods -n argocd
```

All required Argo CD components should be healthy.

# 26. Argo CD Application Validation

List Argo CD applications:

```bash
kubectl get applications \
  -n argocd
```

The application should report a healthy and synchronized state.

Expected conceptual status:

```text
SYNC STATUS     HEALTH STATUS
Synced          Healthy
```

The exact output depends on the Argo CD version and application configuration.

# 27. GitOps Validation

Verify the GitOps flow:

```text
Developer
    |
    v
Application Code
    |
    v
Jenkins
    |
    v
Docker Image
    |
    v
Amazon ECR
    |
    v
Kubernetes Manifest Repository
    |
    v
Argo CD
    |
    v
Amazon EKS
```

Verify that a new image tag generated by Jenkins is reflected in the Kubernetes manifest.

Verify that Argo CD detects the manifest change.

Verify that Argo CD synchronizes the new configuration.

Verify that Kubernetes deploys the updated image.

# 28. Deployment Rollout Validation

Check rollout status:

```bash
kubectl rollout status deployment/<deployment-name> \
  -n <application-namespace>
```

Expected:

```text
deployment "<deployment-name>" successfully rolled out
```

Check rollout history:

```bash
kubectl rollout history deployment/<deployment-name> \
  -n <application-namespace>
```

# 29. Application Health Validation

Verify application pods:

```bash
kubectl get pods -n <application-namespace>
```

Verify services:

```bash
kubectl get svc -n <application-namespace>
```

Verify endpoints:

```bash
kubectl get endpoints -n <application-namespace>
```

Check application logs:

```bash
kubectl logs <pod-name> \
  -n <application-namespace>
```

The application should not show persistent:

ERROR
CrashLoopBackOff
ImagePullBackOff
Connection refused

conditions.

# 30. Route 53 Validation

Verify the hosted zone:

```bash
aws route53 list-hosted-zones \
  --output table
```

Verify DNS records:

```bash
aws route53 list-resource-record-sets \
  --hosted-zone-id <hosted-zone-id>
```

Verify that the application DNS record points to the correct endpoint.

# 31. DNS Validation

From a client machine:

```bash
nslookup pittylittle.shop
```

Verify the returned address.

For the www hostname:

```bash
nslookup www.pittylittle.shop
```

Verify that the DNS configuration resolves as expected.

DNS resolution should be consistent with the Route 53 configuration.

# 32. Application URL Validation

Open the application using the configured domain:

```text
http://pittylittle.shop
```

If the www hostname is configured:

```text
http://www.pittylittle.shop
```

Verify that the application UI loads successfully.

Validate:

DNS resolution
Load balancer connectivity
Kubernetes service
Application pods
Application functionality

# 33. Browser Validation

Perform the application validation from a browser.

Verify:

Application loads
Application UI renders
Static assets load
Backend services respond
No major browser errors

Open browser developer tools and inspect:

Console
Network

Check for:

HTTP 4xx
HTTP 5xx
Failed requests
CORS errors
Connection failures

# 34. Microservice Validation

Validate the individual microservices.

For each service verify:

Deployment
Pod
Service
Container image
ECR image
Logs
Endpoints

Example:

```bash
kubectl get deployment <service-name> -n <namespace>
kubectl get pods -n <namespace>
kubectl get svc <service-name> -n <namespace>
```

# 35. Image Update Validation

Perform an end-to-end CI/CD validation.

The workflow should be:

```text
1. Modify application
        |
        v
2. Push code to Git
        |
        v
3. Jenkins detects/builds change
        |
        v
4. Docker image is built
        |
        v
5. Image pushed to ECR
        |
        v
6. Kubernetes manifest updated
        |
        v
7. Argo CD detects change
        |
        v
8. Argo CD synchronizes
        |
        v
9. EKS deployment updated
        |
        v
10. Application serves new version
```

This is one of the most important validations of the platform.

# 36. Monitoring Validation

Verify monitoring namespace:

```bash
kubectl get pods -n monitoring
```

Verify Prometheus:

```bash
kubectl get pods -n monitoring | grep prometheus
```

Verify Grafana:

```bash
kubectl get pods -n monitoring | grep grafana
```

Verify Alertmanager:

```bash
kubectl get pods -n monitoring | grep alertmanager
```

# 37. Prometheus Validation

Verify Prometheus targets.

Open the Prometheus UI and navigate to:

```text
Status
    |
    +-- Targets
```

Verify that expected targets are healthy.

Run:

```text
up
```

The query should return metrics from available targets.

# 38. Grafana Validation

Open Grafana.

Verify:

Prometheus data source
Kubernetes dashboards
Node metrics
Pod metrics
Resource metrics

Verify that dashboards contain current data.

# 39. Alerting Validation

Verify Alertmanager:

```bash
kubectl get pods -n monitoring | grep alertmanager
```

Verify Prometheus alert rules:

```bash
kubectl get prometheusrule -n monitoring
```

Verify that alert rules are visible in Prometheus.

Perform a controlled alert test if required.

Verify:

```text
Prometheus
    |
    v
Alert Rule
    |
    v
Firing Alert
    |
    v
Alertmanager
    |
    v
Notification
```

# 40. Security Validation

Validate the security controls implemented in the platform.

Check that:

AWS credentials are not stored in Git.
Jenkins credentials are stored in Jenkins Credentials.
Kubernetes Secrets are not committed to Git.
Terraform state is stored securely.
IAM roles are used where appropriate.
EKS access is controlled.
Monitoring endpoints are not unnecessarily exposed.
Sensitive information is not present in logs or screenshots.

Search the repository for accidentally committed secrets before publishing the implementation.

# 41. Git Repository Validation

Verify repository status:

```bash
git status
```

Verify remote:

```bash
git remote -v
```

Verify branches:

```bash
git branch -a
```

Verify recent commits:

```bash
git log --oneline -10
```

Ensure that the repository does not contain:

AWS access keys
Private keys
Passwords
Tokens
Terraform state files
Kubernetes secrets
Jenkins secrets

# 42. Evidence Collection

Store final validation evidence under:

```text
evidence/12-end-to-end/
```

Recommended evidence:

```text
01-aws-account-validation.png
02-vpc-validation.png
03-jumphost-validation.png
04-terraform-validation.png
05-eks-cluster-active.png
06-eks-nodes-ready.png
07-ecr-repositories.png
08-ecr-images.png
09-jenkins-successful-build.png
10-docker-build.png
11-kubernetes-deployments.png
12-kubernetes-pods.png
13-kubernetes-services.png
14-argocd-applications.png
15-argocd-synced-healthy.png
16-route53-records.png
17-dns-resolution.png
18-application-ui.png
19-prometheus-targets.png
20-grafana-dashboard.png
21-alertmanager.png
22-alert-firing.png
23-end-to-end-cicd.png
24-final-platform.png
```

Do not capture secrets or credentials in evidence.

# 43. Final Validation Matrix

```text
Phase	Component	Validation	Status
01	Architecture	Architecture documented	Completed / Pending
02	Terraform State	Backend verified	Completed / Pending
03	AWS Network	VPC and jump host verified	Completed / Pending
04	EKS	Cluster and nodes healthy	Completed / Pending
05	ECR	Repositories and images verified	Completed / Pending
06	Jenkins	CI pipelines successful	Completed / Pending
07	Kubernetes	Workloads healthy	Completed / Pending
08	Argo CD	Applications synced	Completed / Pending
09	Route 53	DNS resolves correctly	Completed / Pending
10	Monitoring	Metrics and dashboards working	Completed / Pending
11	Alerting	Alerts and routing validated	Completed / Pending
12	E2E	Complete application flow validated	Completed / Pending
```

# 44. End-to-End Success Criteria

The implementation is considered successfully validated when the following flow works:

```text
Git Repository
      |
      v
Jenkins
      |
      v
Docker Build
      |
      v
Amazon ECR
      |
      v
Kubernetes Manifest
      |
      v
Argo CD
      |
      v
Amazon EKS
      |
      v
Microservices
      |
      v
AWS Load Balancer
      |
      v
Route 53
      |
      v
Application Domain
      |
      v
Application UI
```

At the same time:

```text
Amazon EKS
      |
      v
Prometheus
      |
      v
Grafana
      |
      v
Monitoring
```

and:

```text
Prometheus
      |
      v
Alert Rules
      |
      v
Alertmanager
      |
      v
Notifications
```

must operate successfully.

# 45. Final Platform Validation

The final platform should provide:

```text
Infrastructure as Code
        |
        v
AWS Infrastructure
        |
        v
Amazon EKS
        |
        +------------------+
        |                  |
        v                  v
    Amazon ECR          Jenkins
        |                  |
        +--------+---------+
                 |
                 v
            Kubernetes
                 |
                 v
             Argo CD
                 |
                 v
             GitOps
                 |
                 v
          Application UI
                 |
                 v
             Route 53
```

Operational visibility:

```text
Kubernetes
     |
     v
Prometheus
     |
     +----------> Grafana
     |
     +----------> Alertmanager
```

# 46. Disaster and Recovery Validation

Where applicable, verify that the platform can recover from common failures.

Examples:

Pod failure
Node failure
Application container failure
Deployment rollout failure
Image pull failure
Argo CD synchronization failure
Jenkins build failure

For a failed pod:

```bash
kubectl get pods -n <namespace>
```

Delete a test pod if appropriate:

```bash
kubectl delete pod <pod-name> -n <namespace>
```

Verify that the deployment recreates the pod:

```bash
kubectl get pods -n <namespace> -w
```

Do not perform destructive tests against production infrastructure unless explicitly authorized.

# 47. Rollback Validation

Verify that Kubernetes deployment rollback is possible.

View rollout history:

```bash
kubectl rollout history deployment/<deployment-name> \
  -n <namespace>
```

Rollback when required:

```bash
kubectl rollout undo deployment/<deployment-name> \
  -n <namespace>
```

Verify:

```bash
kubectl rollout status deployment/<deployment-name> \
  -n <namespace>
```

GitOps-managed environments should preferably perform configuration changes through Git and Argo CD rather than manually modifying the cluster.

# 48. Final Operational Checklist

Before considering the implementation complete:

```text
[ ] AWS infrastructure validated
[ ] Terraform configuration validated
[ ] Terraform state validated
[ ] Jump host validated
[ ] EKS cluster ACTIVE
[ ] EKS nodes READY
[ ] ECR repositories available
[ ] Docker images available
[ ] Jenkins pipelines successful
[ ] Kubernetes deployments available
[ ] Kubernetes pods Running
[ ] Kubernetes services available
[ ] Argo CD applications Synced
[ ] Argo CD applications Healthy
[ ] Route 53 DNS configured
[ ] Application domain resolves
[ ] Application UI accessible
[ ] Prometheus collecting metrics
[ ] Grafana dashboards working
[ ] Alert rules configured
[ ] Alertmanager working
[ ] Test alert validated
[ ] End-to-end CI/CD validated
[ ] Security checks completed
[ ] Evidence captured
[ ] Repository cleaned of secrets
```

# 49. Final Evidence Directory

The complete evidence structure should be:

```text
evidence/
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

Phase 12 evidence should contain the final proof that the complete platform operated successfully.

# 50. Final Project Outcome

The completed implementation demonstrates a complete AWS microservices DevSecOps platform using:

AWS
Terraform
Amazon VPC
EC2
Amazon EKS
Amazon ECR
Docker
Jenkins
Kubernetes
Argo CD
GitOps
Route 53
Prometheus
Grafana
Alertmanager

The platform implements the complete lifecycle:

```text
Infrastructure
      |
      v
Provisioning
      |
      v
CI
      |
      v
Containerization
      |
      v
Container Registry
      |
      v
GitOps
      |
      v
Kubernetes Deployment
      |
      v
Application Exposure
      |
      v
DNS
      |
      v
Monitoring
      |
      v
Alerting
      |
      v
Operational Validation
```

# 51. Project Completion

The project is considered complete after:

All infrastructure phases are validated.
CI pipelines successfully build and publish microservice images.
Kubernetes workloads are deployed successfully.
Argo CD maintains the desired application state.
Route 53 provides application DNS resolution.
The application is accessible through the configured domain.
Prometheus collects operational metrics.
Grafana provides monitoring dashboards.
Alertmanager processes configured alerts.
End-to-end CI/CD and GitOps workflows are validated.
Security checks are completed.
Evidence is organized under the project evidence directory.

The implementation can now be documented, demonstrated, and used as a reference DevSecOps platform implementation.