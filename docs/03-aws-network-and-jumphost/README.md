# Phase 03 — AWS Network & Jump Host

## 📌 Overview

Phase 03 establishes the AWS networking and administrative foundation required for the microservices DevSecOps platform.

This phase provisions the core AWS network infrastructure and an EC2 Jump Host that provides a controlled administration environment for AWS, Terraform, Kubernetes, Jenkins, Docker, and other DevOps tools.

The networking architecture includes:

- Amazon VPC
- Public subnets
- Private subnets
- Internet Gateway
- NAT Gateway
- Public route tables
- Private route tables
- Security groups
- EC2 Jump Host
- IAM role for the Jump Host
- Automated Jump Host bootstrap using EC2 user data

The Jump Host becomes the operational administration point for the infrastructure and subsequent EKS and CI/CD phases.

---

# 🎯 Objectives

The objectives of Phase 03 are:

1. Create the AWS VPC.
2. Create public and private subnets.
3. Configure the Internet Gateway.
4. Configure the NAT Gateway.
5. Configure public and private route tables.
6. Configure security groups.
7. Deploy the EC2 Jump Host.
8. Attach an IAM role to the Jump Host.
9. Configure the Jump Host using EC2 user data.
10. Install the required DevOps tools.
11. Validate AWS authentication through the IAM role.
12. Validate Internet and AWS API connectivity.
13. Prepare the Jump Host for EKS and CI/CD administration.

---

# 🏗️ Architecture

The Phase 03 architecture provides isolated networking using public and private subnets.

```text
                         Internet
                            │
                            ▼
                  ┌──────────────────┐
                  │ Internet Gateway │
                  └────────┬─────────┘
                           │
             ┌─────────────┴─────────────┐
             │                           │
             ▼                           ▼
      ┌──────────────┐            ┌──────────────┐
      │ Public       │            │ Public       │
      │ Subnet 1     │            │ Subnet 2     │
      │              │            │              │
      │ Jump Host    │            │ NAT Gateway  │
      └──────┬───────┘            └──────┬───────┘
             │                           │
             │                           │
             └─────────────┬─────────────┘
                           │
                           ▼
                  ┌──────────────────┐
                  │ Private Subnets  │
                  │                  │
                  │ EKS / Apps       │
                  └──────────────────┘
```

The exact CIDR ranges should match the Terraform configuration used by the project.

---

# 🌐 VPC Architecture

The VPC provides the isolated network boundary for the project.

Example architecture:

```text
VPC
│
├── Public Subnet 1
│   └── Jump Host
│
├── Public Subnet 2
│   └── NAT Gateway / Public resources
│
├── Private Subnet 1
│   └── EKS / Application resources
│
└── Private Subnet 2
    └── EKS / Application resources
```

The exact CIDR ranges should match the Terraform configuration used by the project.

---

# 🧩 Network Components

## 1. VPC

The VPC is the primary network boundary.

It provides:

- Private IP addressing
- Subnet segmentation
- Route table association
- Internet connectivity
- Network isolation

Example:

```text
VPC
CIDR   : Project-defined CIDR
Region : us-east-1
```

---

## 2. Public Subnets

Public subnets contain resources that require direct connectivity through the Internet Gateway.

The Jump Host is deployed in a public subnet.

Example:

```text
Public Subnet
      │
      └── Route Table
              │
              └── 0.0.0.0/0
                    │
                    ▼
              Internet Gateway
```

Resources in the public subnet require appropriate public IP addressing and security-group rules to communicate with the Internet.

---

## 3. Private Subnets

Private subnets are used for resources that should not have direct inbound Internet connectivity.

Example:

```text
Private Subnet
      │
      └── Route Table
              │
              └── 0.0.0.0/0
                    │
                    ▼
               NAT Gateway
                    │
                    ▼
                 Internet
```

Private resources can initiate outbound connections through the NAT Gateway without requiring public IP addresses.

---

# 🌐 Internet Gateway

The Internet Gateway provides connectivity between the VPC and the public Internet.

The public subnet route table contains a default route similar to:

```text
0.0.0.0/0
     │
     ▼
Internet Gateway
```

This enables resources in the public subnet with appropriate public IP addressing and security-group rules to communicate with the Internet.

---

# 🔄 NAT Gateway

The NAT Gateway provides outbound Internet connectivity for resources in private subnets.

The traffic flow is:

```text
Private Resource
      │
      ▼
Private Route Table
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

The NAT Gateway does not provide unsolicited inbound Internet access to private resources.

---

# 🛣️ Route Tables

The project uses separate routing logic for public and private subnets.

## Public Route Table

Example:

```text
Destination       Target

VPC CIDR          local
0.0.0.0/0         Internet Gateway
```

---

## Private Route Table

Example:

```text
Destination       Target

VPC CIDR          local
0.0.0.0/0         NAT Gateway
```

This separation provides the required network isolation.

---

# 🔐 Security Groups

Security groups control inbound and outbound traffic for AWS resources.

The project should follow the principle of least privilege.

Typical access requirements include:

```text
SSH
TCP 22

HTTP
TCP 80

HTTPS
TCP 443
```

Additional ports should only be opened when required by the application architecture.

For example, administrative access to Jenkins or other internal tools should not automatically be exposed to the entire Internet.

---

# 🖥️ Jump Host

The Jump Host is an EC2 instance deployed in the public subnet.

Its purpose is to provide an administrative environment for:

- AWS CLI
- Terraform
- Kubernetes CLI
- Docker
- Jenkins administration
- Ansible
- Maven
- Security tooling
- Cluster administration
- Infrastructure troubleshooting

Example architecture:

```text
Administrator
      │
      │ SSH
      ▼
┌───────────────────┐
│    Jump Host      │
│                   │
│ AWS CLI           │
│ Terraform         │
│ kubectl           │
│ Docker            │
│ Ansible           │
│ Maven             │
│ Security Tools    │
└─────────┬─────────┘
          │
          ▼
     AWS Services
```

---

# 🔑 Jump Host IAM Role

The Jump Host uses an IAM role instead of storing long-term AWS access keys on the EC2 instance.

The instance profile attaches the IAM role to the EC2 instance.

Example flow:

```text
EC2 Jump Host
      │
      ▼
IAM Instance Profile
      │
      ▼
IAM Role
      │
      ▼
AWS STS Temporary Credentials
      │
      ▼
AWS APIs
```

This is preferable to storing credentials such as:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

directly on the server.

---

# 🔍 IAM Role Validation

After connecting to the Jump Host, verify the AWS identity:

```bash
aws sts get-caller-identity
```

Example:

```json
{
    "UserId": "...",
    "Account": "...",
    "Arn": "arn:aws:sts::<account-id>:assumed-role/<role-name>/<instance-id>"
}
```

The returned ARN should show that the EC2 instance is using the expected IAM role.

---

# ⚙️ Jump Host Bootstrap

The Jump Host is configured automatically using EC2 user data.

Terraform passes the bootstrap script to the instance.

Example Terraform configuration:

```hcl
resource "aws_instance" "ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public-subnet1.id
  vpc_security_group_ids = [aws_security_group.security-group.id]

  iam_instance_profile = aws_iam_instance_profile.instance-profile.name

  root_block_device {
    volume_size = 30
  }

  user_data = file("${path.module}/install-tools.sh")

  tags = {
    Name = var.instance_name
  }
}
```

The `user_data` configuration causes the installation script to execute during the EC2 instance's initial boot.

---

# 🐧 Operating System

The Jump Host uses:

```text
Ubuntu 24.04 LTS
```

The bootstrap process installs the required DevOps tooling using the Ubuntu package-management system and vendor repositories where required.

---

# 🛠️ Installed DevOps Tools

The installation process includes tools such as:

```text
Java 21
Jenkins
Docker
Terraform
Ansible
Maven
AWS CLI
Node.js
Vault
Trivy
MariaDB
PostgreSQL
SonarQube
```

The exact tooling installed should match the final version of:

```text
install-tools.sh
```

used by the project.

---

# ☕ Java and Jenkins

Jenkins requires a supported Java runtime.

The Jump Host installs Java 21.

Validate Java:

```bash
java --version
```

Expected output should indicate Java 21.

---

# 🔧 Jenkins Service Validation

Check the Jenkins service:

```bash
sudo systemctl status jenkins --no-pager -l
```

Check whether Jenkins is listening:

```bash
sudo ss -lntp | grep 8080
```

Local connectivity can be tested using:

```bash
curl -I http://localhost:8080
```

If Jenkins is running successfully, the service should listen on the configured Jenkins port.

Check the Jenkins version:

```bash
jenkins --version
```

---

# 🐳 Docker Validation

Verify Docker:

```bash
docker --version
```

Verify Docker Compose:

```bash
docker compose version
```

Verify the Docker service:

```bash
sudo systemctl status docker
```

The Jenkins user should also have appropriate Docker access when Docker is used by Jenkins pipelines.

---

# 🏗️ Terraform Validation

Verify Terraform:

```bash
terraform version
```

Terraform is used by the CI/CD pipelines to provision AWS infrastructure.

---

# ☁️ AWS CLI Validation

Verify the AWS CLI:

```bash
aws --version
```

Then:

```bash
aws sts get-caller-identity
```

The second command confirms that the Jump Host can authenticate to AWS through its IAM role.

---

# ☸️ Kubernetes CLI

The Jump Host is also used for Kubernetes administration.

After the EKS cluster is created, the kubeconfig can be configured using:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name twr-eks
```

Then validate:

```bash
kubectl get nodes
```

The Kubernetes CLI should be installed on the Jump Host before performing cluster administration.

---

# 🌐 Network Connectivity Validation

## Public Connectivity

From the Jump Host:

```bash
curl -I https://www.google.com
```

Successful connectivity confirms outbound Internet access.

---

## AWS API Connectivity

Run:

```bash
aws sts get-caller-identity
```

Successful output confirms:

```text
Jump Host
    │
    ▼
AWS IAM
    │
    ▼
AWS API
```

---

## Private Subnet Connectivity

Private resources should be able to access required external endpoints through the NAT Gateway when appropriate.

Expected path:

```text
Private Subnet
      │
      ▼
Private Route Table
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

# 🔐 SSH Access

The Jump Host is the controlled administrative entry point.

The general access flow is:

```text
Administrator
      │
      │ SSH
      ▼
Public IP / DNS
      │
      ▼
Jump Host
      │
      ▼
Private AWS Resources
```

SSH access should be restricted to trusted source addresses whenever possible.

Avoid:

```text
0.0.0.0/0
```

for SSH access in production environments unless there is a specific security justification.

---

# 🔒 Security Considerations

The Jump Host is an Internet-facing administrative system and therefore requires additional security controls.

Recommended controls include:

- Restrict SSH source IPs.
- Use key-based authentication.
- Avoid password authentication.
- Keep the operating system updated.
- Keep DevOps tools updated.
- Use IAM roles instead of static AWS credentials.
- Avoid storing secrets in shell scripts.
- Avoid exposing unnecessary ports.
- Monitor administrative activity.
- Remove unused services.
- Use least-privilege IAM policies.

---

# 🐛 Troubleshooting

## Problem 1 — Jenkins Is Not Installed

Check the installation log:

```bash
sudo tail -100 /var/log/install-tools.log
```

Check the package:

```bash
dpkg -l | grep jenkins
```

Check the repository:

```bash
cat /etc/apt/sources.list.d/jenkins.list
```

Then update the package repository:

```bash
sudo apt-get update
```

---

## Problem 2 — Jenkins Service Does Not Exist

Check:

```bash
systemctl status jenkins
```

If the service does not exist, inspect:

```bash
sudo tail -100 /var/log/install-tools.log
```

The bootstrap script may have stopped at an earlier installation step.

---

## Problem 3 — Java Is Missing

Check:

```bash
java --version
```

If Java is missing:

```bash
sudo apt-get install -y openjdk-21-jdk
```

Then:

```bash
java --version
```

---

## Problem 4 — Docker Is Missing

Check:

```bash
docker --version
```

Check:

```bash
systemctl status docker
```

If necessary:

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

---

## Problem 5 — User Data Did Not Complete

EC2 user-data execution logs should be inspected.

Check:

```bash
sudo cat /var/log/cloud-init-output.log
```

Also check:

```bash
sudo cat /var/log/install-tools.log
```

These logs are especially useful when the installation script exits because of an error.

---

# 🧪 Validation Checklist

Before moving to the next phase, verify:

- [ ] VPC created
- [ ] Public subnets created
- [ ] Private subnets created
- [ ] Internet Gateway created
- [ ] NAT Gateway created
- [ ] Public route table configured
- [ ] Private route table configured
- [ ] Security groups configured
- [ ] Jump Host created
- [ ] IAM role attached to Jump Host
- [ ] AWS CLI installed
- [ ] Terraform installed
- [ ] Java 21 installed
- [ ] Jenkins installed
- [ ] Docker installed
- [ ] Ansible installed
- [ ] Maven installed
- [ ] Node.js installed
- [ ] Security tooling installed
- [ ] AWS STS authentication verified
- [ ] Internet connectivity verified
- [ ] Jenkins service verified
- [ ] Docker service verified
- [ ] Kubernetes administration tools available

---

# 📸 Evidence Collection

Store implementation evidence under:

```text
evidence/03-aws-network/
```

Recommended evidence:

```text
evidence/03-aws-network/
│
├── 01-vpc.png
├── 02-public-subnets.png
├── 03-private-subnets.png
├── 04-internet-gateway.png
├── 05-nat-gateway.png
├── 06-route-tables.png
├── 07-security-groups.png
├── 08-jumphost.png
├── 09-jumphost-iam-role.png
├── 10-aws-sts-identity.png
├── 11-jumphost-tools.png
├── 12-jenkins-service.png
├── 13-docker-service.png
└── 14-network-connectivity.png
```

## 🔒 Sensitive Information

Do not capture or commit:

- AWS access keys
- AWS secret keys
- SSH private keys
- Jenkins credentials
- GitHub tokens
- Database passwords
- API tokens
- Other sensitive credentials

---

# 📋 Phase Completion Criteria

Phase 03 is considered complete when:

- [ ] The VPC is successfully deployed.
- [ ] Public and private subnet architecture is working.
- [ ] Internet Gateway connectivity is verified.
- [ ] NAT Gateway connectivity is verified.
- [ ] Route tables are correctly associated.
- [ ] Security groups enforce the required access.
- [ ] The Jump Host is successfully deployed.
- [ ] The Jump Host uses an IAM role.
- [ ] AWS CLI authentication works without static AWS credentials.
- [ ] Required DevOps tools are installed.
- [ ] Jenkins is running successfully.
- [ ] Docker is running successfully.
- [ ] Network connectivity is verified.
- [ ] The Jump Host is ready for EKS and CI/CD administration.

---

# 📝 Outcome

At the end of Phase 03, the project has a functional AWS networking and administration layer.

The resulting architecture is:

```text
                         Internet
                            │
                            ▼
                     Internet Gateway
                            │
                            ▼
                    ┌───────────────┐
                    │ Public Subnet │
                    │               │
                    │  Jump Host    │
                    └───────┬───────┘
                            │
                       NAT Gateway
                            │
                            ▼
                    ┌───────────────┐
                    │ Private       │
                    │ Subnets       │
                    │               │
                    │ EKS / Apps    │
                    └───────────────┘
```

The Jump Host provides the operational foundation for the remaining DevSecOps implementation phases.

The next phase builds the Amazon EKS cluster and Kubernetes infrastructure.

---

# 📚 Related Phases

| Phase | Documentation |
|---|---|
| Phase 01 | [AWS Microservices DevSecOps Architecture](../01-architecture/) |
| Phase 02 | [Terraform State Management](../02-terraform-state/) |
| Phase 03 | **AWS Network & Jump Host** |
| Phase 04 | [Amazon EKS & Kubernetes](../04-eks/) |

---

**Phase 03 — AWS Network & Jump Host**

**Next:** [Phase 04 — Amazon EKS & Kubernetes →](../04-eks/)