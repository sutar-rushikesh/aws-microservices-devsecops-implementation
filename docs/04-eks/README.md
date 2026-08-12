# Phase 04 — Amazon EKS Cluster

## 📌 Overview

Phase 04 implements the Amazon Elastic Kubernetes Service (EKS) platform that hosts the microservices application.

The objective is to provision a production-oriented Kubernetes control plane and worker infrastructure on AWS and establish secure connectivity from the DevOps Jump Host.

This phase builds the Kubernetes foundation required for the remaining microservices DevSecOps implementation.

---

# 🎯 Objectives

The objectives of Phase 04 are:

1. Provision the Amazon EKS cluster.
2. Configure the Kubernetes version.
3. Provision EKS worker nodes.
4. Deploy EKS inside the project VPC.
5. Place worker nodes inside private subnets.
6. Configure IAM permissions required for EKS administration.
7. Configure administrative access through the DevOps Jump Host.
8. Configure `kubectl` against the EKS cluster.
9. Validate EKS cluster health.
10. Validate worker node connectivity.
11. Verify Kubernetes system pods and EKS add-ons.
12. Prepare the cluster for microservices workloads.

---

# 🏗️ Architecture

The EKS architecture follows this general model:

```text
                         AWS Region
                          us-east-1
                              │
                              ▼
                    ┌─────────────────┐
                    │       VPC       │
                    │                 │
                    │  EKS Control    │
                    │     Plane       │
                    └────────┬────────┘
                             │
                 ┌───────────┴───────────┐
                 │                       │
                 ▼                       ▼
        ┌─────────────────┐     ┌─────────────────┐
        │ Private Subnet 1│     │ Private Subnet 2│
        │                 │     │                 │
        │  ┌───────────┐  │     │  ┌───────────┐  │
        │  │ Worker    │  │     │  │ Worker    │  │
        │  │ Node      │  │     │  │ Node      │  │
        │  └─────┬─────┘  │     │  └─────┬─────┘  │
        └────────┼────────┘     └────────┼────────┘
                 │                       │
                 └───────────┬───────────┘
                             │
                             ▼
                    Kubernetes Pods
                             │
                             ▼
                       Microservices
```

### Administrative Access

```text
Developer / Jenkins
        │
        ▼
  DevOps Jump Host
        │
        │ AWS IAM Role
        ▼
     EKS API
        │
        ▼
 Kubernetes Cluster
```

The EKS control plane is managed by AWS, while worker nodes are provisioned in the project's private subnets.

---

# 🧩 EKS Components

The implementation consists of the following major components:

| Component | Purpose |
|---|---|
| EKS Cluster | Managed Kubernetes control plane |
| EKS Node Group | Compute capacity for Kubernetes workloads |
| Worker Nodes | Run application pods |
| VPC | Network boundary for EKS |
| Private Subnets | Host worker nodes |
| Security Groups | Control network traffic |
| IAM Roles | Provide AWS permissions |
| Jump Host | Administrative access point |
| `kubectl` | Kubernetes CLI |
| AWS CLI | AWS resource management |

---

# 📋 Prerequisites

Before starting this phase, the following should already be available:

- AWS account
- AWS CLI
- Terraform
- Configured AWS credentials
- VPC
- Public and private subnets
- Internet/NAT connectivity as required
- DevOps Jump Host
- IAM roles and policies
- Terraform remote backend

---

## Verify AWS Authentication

Run:

```bash
aws sts get-caller-identity
```

Expected output should identify the AWS account and authenticated IAM principal.

---

## Verify AWS Region

Run:

```bash
aws configure get region
```

Example:

```text
us-east-1
```

---

## Verify Terraform

Run:

```bash
terraform version
```

---

# 📁 Terraform Structure

A typical Terraform structure for this phase is:

```text
terraform/
└── eks/
    ├── backend.tf
    ├── provider.tf
    ├── variables.tf
    ├── eks.tf
    ├── iam.tf
    ├── outputs.tf
    └── terraform.tfvars
```

The exact filenames can vary depending on the implementation.

---

# ⚙️ Provider Configuration

Terraform uses the AWS provider to create the EKS infrastructure.

Example:

```hcl
provider "aws" {
  region = var.aws_region
}
```

Example variable:

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
```

---

# ☸️ EKS Cluster

The EKS cluster represents the managed Kubernetes control plane.

Example configuration:

```hcl
resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids = var.private_subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}
```

Example variables:

```hcl
variable "cluster_name" {
  type    = string
  default = "twr-eks"
}

variable "eks_version" {
  type    = string
  default = "1.36"
}
```

The EKS version should be selected based on the Kubernetes versions supported by AWS at deployment time.

---

# 🔑 EKS IAM Role

The EKS control plane requires an IAM role.

Example:

```hcl
resource "aws_iam_role" "eks_cluster_role" {
  name = "twr-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "eks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}
```

Attach the required AWS managed policy:

```hcl
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
```

The role allows the Amazon EKS service to perform the required AWS operations for the managed control plane.

---

# 🖥️ EKS Worker Nodes

Worker nodes provide the compute capacity where microservices run.

A managed node group can be configured using:

```hcl
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "twr-eks-node-group"

  node_role_arn = aws_iam_role.eks_node_role.arn

  subnet_ids = var.private_subnet_ids

  instance_types = [
    "t3.medium"
  ]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy
  ]
}
```

The instance type and scaling configuration should be adjusted according to workload requirements.

---

# 🔐 Worker Node IAM Policies

Worker nodes require permissions to communicate with AWS services and the EKS control plane.

Common policies include:

```text
AmazonEKSWorkerNodePolicy
AmazonEKS_CNI_Policy
AmazonEC2ContainerRegistryReadOnly
```

Example:

```hcl
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
```

```hcl
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
```

```hcl
resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
```

The ECR permission allows worker nodes to pull private container images.

---

# 🌐 Network Configuration

The EKS cluster is deployed into the project VPC.

The worker nodes should be placed in private subnets.

Example:

```hcl
vpc_config {
  subnet_ids = var.private_subnet_ids
}
```

The private subnets should have appropriate routing and network connectivity.

For workloads that need outbound Internet access, the private subnet route table should normally use a NAT Gateway.

Expected traffic flow:

```text
Private Subnet
      │
      ▼
Route Table
      │
      ▼
NAT Gateway
      │
      ▼
Internet Gateway
      │
      ▼
Internet
```

---

# 🔒 Security Considerations

The EKS implementation should follow the principle of least privilege.

Important considerations:

- Worker nodes should not require public IP addresses.
- Kubernetes worker nodes should preferably reside in private subnets.
- Security groups should allow only required traffic.
- IAM roles should contain only required permissions.
- ECR access should be restricted to required repositories.
- Administrative access should occur through controlled infrastructure such as the Jump Host.
- Kubernetes RBAC should be used to control cluster-level access.

---

# 🚀 Terraform Deployment

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Format Terraform files:

```bash
terraform fmt -recursive
```

Create a plan:

```bash
terraform plan
```

Review the planned resources carefully.

Apply the configuration:

```bash
terraform apply
```

For automated CI/CD execution:

```bash
terraform apply -auto-approve
```

---

# 🔍 Verify EKS Cluster

After Terraform completes, verify the cluster status:

```bash
aws eks describe-cluster \
  --region us-east-1 \
  --name twr-eks \
  --query 'cluster.status'
```

Expected:

```text
"ACTIVE"
```

---

## Verify Kubernetes Version

Run:

```bash
aws eks describe-cluster \
  --region us-east-1 \
  --name twr-eks \
  --query 'cluster.version' \
  --output text
```

Example:

```text
1.36
```

The returned version should match the Kubernetes version configured for the cluster.

---

# 🔧 Configure kubectl

From the DevOps Jump Host:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name twr-eks
```

Expected output:

```text
Added new context arn:aws:eks:us-east-1:<ACCOUNT_ID>:cluster/twr-eks
```

---

## Verify Current Kubernetes Context

Run:

```bash
kubectl config current-context
```

Example:

```text
arn:aws:eks:us-east-1:<ACCOUNT_ID>:cluster/twr-eks
```

The current context should point to the expected EKS cluster.

---

# 🖥️ Verify Worker Nodes

Run:

```bash
kubectl get nodes
```

Expected result:

```text
NAME                         STATUS   ROLES    AGE   VERSION
ip-10-0-x-x.compute.internal Ready    <none>   ...   v1.xx.x
ip-10-0-x-x.compute.internal Ready    <none>   ...   v1.xx.x
```

All expected worker nodes should report:

```text
STATUS = Ready
```

---

## Detailed Node Information

Run:

```bash
kubectl get nodes -o wide
```

This provides additional information such as:

- Internal IP address
- External IP address, where applicable
- Operating system
- Kernel version
- Container runtime
- Kubernetes version

---

# 🔍 Verify Kubernetes System Pods

Check the system namespace:

```bash
kubectl get pods -n kube-system
```

Important components include:

```text
aws-node
coredns
kube-proxy
```

Verify all pods:

```bash
kubectl get pods -A
```

At this stage, the cluster should be healthy and ready to receive workloads.

---

# 🧩 Verify EKS Add-ons

List installed EKS add-ons:

```bash
aws eks list-addons \
  --cluster-name twr-eks \
  --region us-east-1
```

Describe an add-on:

```bash
aws eks describe-addon \
  --cluster-name twr-eks \
  --addon-name vpc-cni \
  --region us-east-1
```

EKS add-ons should report a healthy or active state where applicable.

---

# 🖥️ Jump Host Validation

The Jump Host acts as the administration point for the Kubernetes environment.

---

## Validate AWS Identity

Run:

```bash
aws sts get-caller-identity
```

Expected identity should correspond to the IAM role attached to the Jump Host.

Example:

```text
arn:aws:sts::<ACCOUNT_ID>:assumed-role/<JUMPHOST_ROLE>/<INSTANCE_ID>
```

---

## Verify AWS EKS Access

Run:

```bash
aws eks describe-cluster \
  --region us-east-1 \
  --name twr-eks \
  --query 'cluster.status'
```

Expected:

```text
"ACTIVE"
```

---

## Verify Kubernetes Access

Run:

```bash
kubectl get nodes
```

Successful output confirms Kubernetes API connectivity from the Jump Host.

The complete administrative path is:

```text
Jump Host
   │
   ▼
IAM Role
   │
   ▼
AWS EKS API
   │
   ▼
EKS Cluster
   │
   ▼
Worker Nodes
```

---

# 🐛 Troubleshooting

## Problem 1 — `kubectl` Command Not Found

Install the Kubernetes CLI on the Jump Host.

After installation:

```bash
kubectl version --client
```

Then configure the cluster:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name twr-eks
```

---

## Problem 2 — EKS Cluster Is Not ACTIVE

Check:

```bash
aws eks describe-cluster \
  --region us-east-1 \
  --name twr-eks \
  --query 'cluster.status'
```

Review Terraform output and AWS EKS events.

Verify that:

- Terraform deployment completed successfully.
- Required IAM permissions are available.
- Required subnets are available.
- The VPC configuration is correct.

---

## Problem 3 — Worker Nodes Are Not Ready

Check:

```bash
kubectl get nodes -o wide
```

Then:

```bash
kubectl get pods -n kube-system
```

Check the node group:

```bash
aws eks describe-nodegroup \
  --cluster-name twr-eks \
  --nodegroup-name twr-eks-node-group \
  --region us-east-1
```

Review the node group status and associated errors.

---

## Problem 4 — `kubectl Unauthorized`

Verify AWS identity:

```bash
aws sts get-caller-identity
```

Verify kubeconfig:

```bash
kubectl config current-context
```

Regenerate kubeconfig:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name twr-eks
```

Also verify that the authenticated IAM principal has appropriate EKS/Kubernetes access.

---

# 🧪 Validation Checklist

Before moving to the next phase, verify:

- [ ] EKS Terraform configuration created
- [ ] EKS IAM role configured
- [ ] Worker node IAM role configured
- [ ] EKS cluster created
- [ ] EKS node group created
- [ ] Worker nodes deployed into private subnets
- [ ] EKS cluster status verified as `ACTIVE`
- [ ] Kubernetes version verified
- [ ] `kubectl` installed
- [ ] kubeconfig configured
- [ ] Kubernetes context verified
- [ ] Worker nodes show `Ready`
- [ ] `kube-system` pods verified
- [ ] EKS add-ons verified
- [ ] Jump Host IAM access verified
- [ ] EKS API connectivity verified
- [ ] Evidence captured

---

# 📸 Evidence Collection

Store implementation evidence under:

```text
evidence/04-eks/
```

Recommended evidence:

```text
evidence/04-eks/
│
├── 01-eks-cluster-active.png
├── 02-eks-version.png
├── 03-eks-node-group.png
├── 04-kubectl-context.png
├── 05-kubectl-get-nodes.png
├── 06-kubectl-get-nodes-wide.png
├── 07-kube-system-pods.png
├── 08-all-kubernetes-pods.png
├── 09-eks-addons.png
└── 10-jumphost-iam-identity.png
```

---

## Useful Command Outputs

Capture the following outputs as implementation evidence where appropriate:

### EKS Cluster Status

```bash
aws eks describe-cluster \
  --region us-east-1 \
  --name twr-eks \
  --query 'cluster.status'
```

### EKS Kubernetes Version

```bash
aws eks describe-cluster \
  --region us-east-1 \
  --name twr-eks \
  --query 'cluster.version' \
  --output text
```

### Worker Nodes

```bash
kubectl get nodes -o wide
```

### Kubernetes System Pods

```bash
kubectl get pods -n kube-system
```

### All Kubernetes Pods

```bash
kubectl get pods -A
```

### AWS IAM Identity

```bash
aws sts get-caller-identity
```

---

# 🔒 Evidence Security

Do not capture or commit sensitive information such as:

- AWS access keys
- AWS secret keys
- SSH private keys
- IAM secret credentials
- Kubernetes tokens
- Jenkins credentials
- GitHub tokens
- Database passwords
- API tokens
- Other private credentials

Mask account IDs or other sensitive information in screenshots when appropriate.

---

# 📋 Phase Completion Criteria

Phase 04 is considered complete when:

- [ ] EKS Terraform configuration is implemented.
- [ ] EKS IAM role is configured.
- [ ] Worker node IAM role is configured.
- [ ] EKS cluster is successfully created.
- [ ] EKS node group is successfully created.
- [ ] Worker nodes are deployed in private subnets.
- [ ] EKS cluster status is `ACTIVE`.
- [ ] Kubernetes version is verified.
- [ ] `kubectl` is installed and configured.
- [ ] Kubernetes context points to the expected cluster.
- [ ] Worker nodes report `Ready`.
- [ ] Kubernetes system pods are healthy.
- [ ] EKS add-ons are verified.
- [ ] Jump Host IAM access is verified.
- [ ] EKS API connectivity is verified.
- [ ] Required implementation evidence is captured.

---

# 📝 Outcome

At the end of Phase 04, the project has a functional Amazon EKS environment ready to host the microservices platform.

The resulting infrastructure is:

```text
                         AWS
                          │
                          ▼
                ┌───────────────────┐
                │        VPC        │
                │                   │
                │   EKS Cluster     │
                │                   │
                │   ┌───────────┐   │
                │   │ Control   │   │
                │   │   Plane   │   │
                │   └─────┬─────┘   │
                │         │         │
                │    ┌────┴────┐    │
                │    │         │    │
                │  Node 1    Node 2 │
                │    │         │    │
                │    └────┬────┘    │
                │         │         │
                │   Kubernetes      │
                │    Workloads      │
                └─────────┬─────────┘
                          ▲
                          │
                    DevOps Jump Host
                          │
                    kubectl / AWS CLI
```

The EKS platform becomes the foundation for the next phases:

```text
Phase 04
Amazon EKS
    │
    ▼
Phase 05
Amazon ECR
    │
    ▼
Phase 06
Jenkins CI
    │
    ▼
Phase 07
Kubernetes
    │
    ▼
Phase 08
Argo CD GitOps
```

The EKS environment is now ready to receive containerized microservices workloads and support the project's CI/CD and GitOps workflows.

---

# 📚 Related Phases

| Phase | Documentation |
|---|---|
| Phase 01 | [AWS Microservices DevSecOps Architecture](../01-architecture/) |
| Phase 02 | [Terraform State Management](../02-terraform-state/) |
| Phase 03 | [AWS Network & Jump Host](../03-aws-network/) |
| Phase 04 | **Amazon EKS Cluster** |
| Phase 05 | [Amazon ECR](../05-ecr/) |
| Phase 06 | [Jenkins CI](../06-jenkins-ci/) |
| Phase 07 | [Kubernetes](../07-kubernetes/) |
| Phase 08 | [Argo CD GitOps](../08-argocd/) |

---

**Phase 04 — Amazon EKS Cluster**

**Next:** [Phase 05 — Amazon ECR →](../05-ecr/)