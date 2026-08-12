Phase 04 — Amazon EKS Cluster
1. Objective

This phase implements the Amazon Elastic Kubernetes Service (EKS) platform that hosts the microservices application.

The objective is to provision a production-oriented Kubernetes control plane and worker infrastructure on AWS and establish secure connectivity from the DevOps jump host.

Key outcomes
EKS cluster provisioned in AWS
Kubernetes version configured
Worker nodes provisioned
EKS deployed inside the project VPC
Private subnets used for worker nodes
Jump host used for administrative access
IAM permissions configured for EKS administration
kubectl configured against the EKS cluster
Cluster health and node connectivity validated
2. Architecture

The EKS architecture follows this general model:

                         AWS Region
                        us-east-1
                            |
                            |
                    +---------------+
                    |     VPC       |
                    |               |
                    |   EKS Control |
                    |     Plane     |
                    +-------+-------+
                            |
                  ----------------------
                  |                    |
            Private Subnet 1      Private Subnet 2
                  |                    |
             +---------+          +---------+
             | Worker  |          | Worker  |
             | Node    |          | Node    |
             +----+----+          +----+----+
                  |                    |
                  +---------+----------+
                            |
                      Kubernetes Pods
                            |
                     Microservices

Administrative access:

Developer / Jenkins
        |
        v
   DevOps Jump Host
        |
        | AWS IAM Role
        v
      EKS API
        |
        v
   Kubernetes Cluster
3. EKS Components

The implementation consists of the following major components.

Component	Purpose
EKS Cluster	Managed Kubernetes control plane
EKS Node Group	Compute capacity for Kubernetes workloads
Worker Nodes	Run application pods
VPC	Network boundary for EKS
Private Subnets	Host worker nodes
Security Groups	Control network traffic
IAM Roles	Provide AWS permissions
Jump Host	Administrative access point
kubectl	Kubernetes CLI
AWS CLI	AWS resource management
4. Prerequisites

Before starting this phase, the following should already be available:

AWS account
AWS CLI
Terraform
Configured AWS credentials
VPC
Public and private subnets
Internet/NAT connectivity as required
DevOps jump host
IAM roles and policies
Terraform remote backend

Verify AWS authentication:

aws sts get-caller-identity

Expected output should identify the AWS account and authenticated IAM principal.

Verify the AWS region:

aws configure get region

Example:

us-east-1

Verify Terraform:

terraform version
5. EKS Terraform Structure

A typical Terraform structure for this phase is:

terraform/
└── eks/
    ├── backend.tf
    ├── provider.tf
    ├── variables.tf
    ├── eks.tf
    ├── iam.tf
    ├── outputs.tf
    └── terraform.tfvars

The exact filenames can vary depending on the implementation.

6. Provider Configuration

Terraform uses the AWS provider to create the EKS infrastructure.

Example:

provider "aws" {
  region = var.aws_region
}

Example variable:

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
7. EKS Cluster

The EKS cluster represents the managed Kubernetes control plane.

Example configuration:

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

Example variables:

variable "cluster_name" {
  type    = string
  default = "twr-eks"
}

variable "eks_version" {
  type    = string
  default = "1.36"
}

The EKS version should be selected based on the Kubernetes versions supported by AWS at deployment time.

8. EKS IAM Role

The EKS control plane requires an IAM role.

Example:

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

Attach the required AWS managed policy:

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
9. EKS Worker Nodes

Worker nodes provide the compute capacity where microservices run.

A managed node group can be configured using:

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

The instance type and scaling configuration should be adjusted according to workload requirements.

10. Worker Node IAM Policies

Worker nodes require permissions to communicate with AWS services and the EKS control plane.

Common policies include:

AmazonEKSWorkerNodePolicy
AmazonEKS_CNI_Policy
AmazonEC2ContainerRegistryReadOnly

Example:

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

The ECR permission allows worker nodes to pull private container images.

11. Network Configuration

The EKS cluster is deployed into the project VPC.

The worker nodes should be placed in private subnets.

Example:

vpc_config {
  subnet_ids = var.private_subnet_ids
}

The private subnets should have appropriate routing and network connectivity.

For workloads that need outbound internet access, the private subnet route table should normally use a NAT Gateway.

Private Subnet
      |
      v
 Route Table
      |
      v
 NAT Gateway
      |
      v
 Internet Gateway
      |
   Internet
12. Security Considerations

The EKS implementation should follow the principle of least privilege.

Important considerations:

Worker nodes should not require public IP addresses.
Kubernetes worker nodes should preferably reside in private subnets.
Security groups should allow only required traffic.
IAM roles should contain only required permissions.
ECR access should be restricted to required repositories.
Administrative access should occur through controlled infrastructure such as the jump host.
Kubernetes RBAC should be used to control cluster-level access.
13. Terraform Deployment

Initialize Terraform:

terraform init

Validate the configuration:

terraform validate

Format Terraform files:

terraform fmt -recursive

Create a plan:

terraform plan

Review the planned resources carefully.

Apply the configuration:

terraform apply

For automated CI/CD execution:

terraform apply -auto-approve
14. Verify EKS Cluster

After Terraform completes, verify the cluster:

aws eks describe-cluster \
  --region us-east-1 \
  --name twr-eks \
  --query 'cluster.status'

Expected:

"ACTIVE"

Verify the Kubernetes version:

aws eks describe-cluster \
  --region us-east-1 \
  --name twr-eks \
  --query 'cluster.version' \
  --output text

Example:

1.36
15. Configure kubectl

From the DevOps jump host:

aws eks update-kubeconfig \
  --region us-east-1 \
  --name twr-eks

Expected output:

Added new context arn:aws:eks:us-east-1:<ACCOUNT_ID>:cluster/twr-eks

Verify the current Kubernetes context:

kubectl config current-context

Example:

arn:aws:eks:us-east-1:<ACCOUNT_ID>:cluster/twr-eks
16. Verify Worker Nodes

Run:

kubectl get nodes

Expected result:

NAME                          STATUS   ROLES    AGE   VERSION
ip-10-0-x-x.compute.internal Ready    <none>   ...   v1.xx.x
ip-10-0-x-x.compute.internal Ready    <none>   ...   v1.xx.x

All expected worker nodes should report:

STATUS = Ready

Detailed information:

kubectl get nodes -o wide
17. Verify Kubernetes System Pods

Check the system namespace:

kubectl get pods -n kube-system

Important components include:

aws-node
coredns
kube-proxy

Verify all pods:

kubectl get pods -A

At this stage, the cluster should be healthy and ready to receive workloads.

18. Verify EKS Add-ons

List installed EKS add-ons:

aws eks list-addons \
  --cluster-name twr-eks \
  --region us-east-1

Describe an add-on:

aws eks describe-addon \
  --cluster-name twr-eks \
  --addon-name vpc-cni \
  --region us-east-1

EKS add-ons should report a healthy/active state where applicable.

19. Jump Host Validation

The jump host acts as the administration point for the Kubernetes environment.

Validate AWS identity:

aws sts get-caller-identity

Expected identity should correspond to the IAM role attached to the jump host.

Example:

arn:aws:sts::<ACCOUNT_ID>:assumed-role/<JUMPHOST_ROLE>/<INSTANCE_ID>

Verify AWS EKS access:

aws eks describe-cluster \
  --region us-east-1 \
  --name twr-eks \
  --query 'cluster.status'

Verify Kubernetes access:

kubectl get nodes

This confirms the complete path:

Jump Host
   |
   v
IAM Role
   |
   v
AWS EKS API
   |
   v
EKS Cluster
   |
   v
Worker Nodes
20. Troubleshooting
kubectl command not found

Install the Kubernetes CLI on the jump host.

After installation:

kubectl version --client

Then configure the cluster:

aws eks update-kubeconfig \
  --region us-east-1 \
  --name twr-eks
EKS cluster is not ACTIVE

Check:

aws eks describe-cluster \
  --region us-east-1 \
  --name twr-eks \
  --query 'cluster.status'

Review Terraform output and AWS EKS events.

Worker nodes are not Ready

Check:

kubectl get nodes -o wide

Then:

kubectl get pods -n kube-system

Check the node group:

aws eks describe-nodegroup \
  --cluster-name twr-eks \
  --nodegroup-name twr-eks-node-group \
  --region us-east-1
kubectl Unauthorized

Verify AWS identity:

aws sts get-caller-identity

Verify kubeconfig:

kubectl config current-context

Regenerate kubeconfig:

aws eks update-kubeconfig \
  --region us-east-1 \
  --name twr-eks

Also verify that the authenticated IAM principal has appropriate EKS/Kubernetes access.

21. Evidence to Capture

The following screenshots/output should be stored under:

evidence/04-eks/

Recommended evidence:

01-eks-cluster-active.png
02-eks-version.png
03-eks-node-group.png
04-kubectl-context.png
05-kubectl-get-nodes.png
06-kubectl-get-nodes-wide.png
07-kube-system-pods.png
08-all-kubernetes-pods.png
09-eks-addons.png
10-jumphost-iam-identity.png

Useful command outputs:

aws eks describe-cluster \
  --region us-east-1 \
  --name twr-eks \
  --query 'cluster.status'
aws eks describe-cluster \
  --region us-east-1 \
  --name twr-eks \
  --query 'cluster.version' \
  --output text
kubectl get nodes -o wide
kubectl get pods -n kube-system
kubectl get pods -A
aws sts get-caller-identity
22. Phase Completion Checklist
 EKS Terraform configuration created
 EKS IAM role configured
 Worker node IAM role configured
 EKS cluster created
 EKS node group created
 Worker nodes deployed into private subnets
 EKS cluster status verified as ACTIVE
 Kubernetes version verified
 kubectl installed
 kubeconfig configured
 Kubernetes context verified
 Worker nodes show Ready
 kube-system pods verified
 EKS add-ons verified
 Jump host IAM access verified
 EKS API connectivity verified
 Evidence captured
23. Phase Result

At the end of Phase 04, the project has a functional Amazon EKS environment ready to host the microservices platform.

The resulting infrastructure is:

                         AWS
                          |
                 +--------+--------+
                 |       VPC       |
                 |                 |
                 |  EKS Cluster    |
                 |       |         |
                 |  +----+----+    |
                 |  |         |    |
                 | Node 1   Node 2 |
                 |  |         |    |
                 |  +----+----+    |
                 |       |         |
                 |   Kubernetes    |
                 |    Workloads    |
                 +--------+--------+
                          ^
                          |
                    DevOps Jump Host
                          |
                     kubectl / AWS CLI

This EKS platform becomes the foundation for the next phases: container image distribution through ECR, CI automation through Jenkins, Kubernetes application deployment, and GitOps deployment through Argo CD.