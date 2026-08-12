Terraform State Bucket

The project uses an Amazon S3 bucket as the centralized Terraform state backend.

Example:

Bucket:
twr-dev-002

State objects are separated using different prefixes.

EKS State
s3://twr-dev-002/eks/terraform.tfstate
ECS State
s3://twr-dev-002/ecs/terraform.tfstate

This separation prevents different Terraform configurations from sharing the same state file.

Why Remote State Is Required

Using a local state file such as:

terraform.tfstate

creates several problems in a CI/CD environment.

For example:

The state exists only on one machine.
Jenkins cannot reliably share the same state with developers.
State can be accidentally deleted.
Multiple users can work with different state copies.
Recovery becomes difficult.
CI/CD execution becomes dependent on a particular workspace.

Remote state solves these problems by storing the state centrally.

S3 Versioning

S3 versioning should be enabled on the Terraform state bucket.

This provides historical versions of:

terraform.tfstate

If the latest state is accidentally deleted or corrupted, an earlier version can potentially be recovered.

Example version history:

terraform.tfstate
        |
        +-- Version 1
        |
        +-- Version 2
        |
        +-- Version 3
        |
        +-- Version 4

The latest version is normally used by Terraform, while previous versions remain available for recovery when versioning is enabled.

Example Backend Configuration

Terraform configuration can use an S3 backend similar to:

terraform {
  backend "s3" {
    bucket = "twr-dev-002"
    key    = "eks/terraform.tfstate"
    region = "us-east-1"
  }
}

For another infrastructure component, the key should be different.

Example:

terraform {
  backend "s3" {
    bucket = "twr-dev-002"
    key    = "ecs/terraform.tfstate"
    region = "us-east-1"
  }
}

The important difference is the S3 object key.

Backend Separation

The project follows this structure:

twr-dev-002
│
├── eks/
│   └── terraform.tfstate
│
└── ecs/
    └── terraform.tfstate

This allows EKS and ECS infrastructure to maintain independent Terraform state.

For example:

EKS Terraform configuration
        |
        +----> eks/terraform.tfstate


ECS Terraform configuration
        |
        +----> ecs/terraform.tfstate

This is preferable to using a single shared state file for unrelated infrastructure.

Terraform Initialization

After configuring the backend, initialize Terraform:

terraform init

Terraform connects to the configured S3 backend and initializes the working directory.

Typical output:

Initializing the backend...

Successfully configured the backend "s3"!

If the backend configuration has changed, use:

terraform init -reconfigure

This tells Terraform to reconfigure the backend using the current configuration.

Backend Validation

Verify that Terraform is using the expected backend:

terraform init

Then inspect the Terraform configuration and backend settings.

A successful initialization should allow commands such as:

terraform plan

and:

terraform apply

to operate using the remote state.

State Validation

The Terraform state can be inspected using:

terraform state list

Example:

aws_vpc.main
aws_subnet.public
aws_subnet.private
aws_internet_gateway.main
aws_route_table.public

The exact resources depend on the Terraform configuration.

The important point is that the state is being managed remotely.

Verify State in Amazon S3

The AWS CLI can be used to verify the state object.

Example:

aws s3 ls s3://twr-dev-002/eks/

Expected structure:

eks/
└── terraform.tfstate

For ECS:

aws s3 ls s3://twr-dev-002/ecs/

Expected:

ecs/
└── terraform.tfstate
S3 Version History

To inspect state versions:

aws s3api list-object-versions \
  --bucket twr-dev-002 \
  --prefix eks/terraform.tfstate \
  --region us-east-1

This can show:

Version ID
Last modified time
Object size
Latest version
Previous versions

Example:

VersionId
IsLatest
LastModified
Size

This information is useful when investigating accidental state deletion or corruption.

State Recovery

If the current Terraform state is accidentally deleted, first verify whether S3 versioning is enabled.

Check versions:

aws s3api list-object-versions \
  --bucket twr-dev-002 \
  --prefix eks/terraform.tfstate \
  --region us-east-1

Identify the required previous version.

Do not immediately run:

terraform apply

when the Terraform state is missing.

Terraform may interpret the infrastructure as unmanaged and attempt to create resources that already exist.

The correct recovery procedure is:

Identify missing state
        |
        v
Check S3 object versions
        |
        v
Identify correct previous version
        |
        v
Restore state
        |
        v
Run terraform init
        |
        v
Run terraform state list
        |
        v
Run terraform plan
        |
        v
Verify expected infrastructure changes
Important Recovery Consideration

Terraform state should never be restored blindly.

Before restoring a previous state version:

Confirm the version belongs to the correct Terraform configuration.
Confirm the S3 key is correct.
Confirm the AWS account is correct.
Confirm the AWS region is correct.
Verify the infrastructure still exists.
Run terraform plan after recovery.
Review the plan carefully before applying changes.
AWS CLI Validation

Verify the AWS identity used for state operations:

aws sts get-caller-identity

Verify the configured AWS region:

aws configure get region

Example:

us-east-1

These checks are important because using the wrong AWS account or region can result in inspecting the wrong S3 bucket or infrastructure environment.

Jenkins Integration

Terraform pipelines use the same remote backend.

The general flow is:

Jenkins
   |
   v
Checkout Terraform Repository
   |
   v
terraform init
   |
   v
S3 Remote Backend
   |
   v
terraform validate
   |
   v
terraform plan
   |
   v
terraform apply

Jenkins should never depend on a state file stored only inside:

/var/lib/jenkins/workspace/

The workspace is temporary and can be deleted or recreated.

The authoritative Terraform state should remain in S3.

CI/CD State Flow
                 Jenkins
                    |
                    v
             Terraform Init
                    |
                    v
          +-------------------+
          |   Amazon S3       |
          | Terraform State   |
          +-------------------+
                    |
                    v
             Terraform Plan
                    |
                    v
             Terraform Apply
                    |
                    v
             AWS Infrastructure
State Isolation

Each Terraform component should have its own state key.

Example:

twr-dev-002/
│
├── eks/
│   └── terraform.tfstate
│
├── ecs/
│   └── terraform.tfstate
│
└── ec2/
    └── terraform.tfstate

This provides logical separation between infrastructure components.

A change to the EKS Terraform configuration should not directly modify the ECS state.

Security Considerations

Terraform state can contain sensitive infrastructure information.

Therefore:

Do not commit terraform.tfstate to Git.
Do not commit terraform.tfstate.backup to Git.
Restrict S3 bucket access.
Use IAM policies with least privilege.
Enable S3 versioning.
Avoid exposing the state bucket publicly.
Do not store AWS credentials inside Terraform files.
Use IAM roles where possible for AWS workloads.
Protect Jenkins credentials.

Example .gitignore entries:

*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl

The exact .gitignore policy should be reviewed according to the project's dependency-lock requirements.

Recommended IAM Permissions

The Jenkins execution identity should have only the permissions required for the Terraform workflow.

For the Terraform state bucket, access generally needs to cover operations such as:

ListBucket
GetObject
PutObject
DeleteObject

The exact permissions should be scoped to the required bucket and prefixes rather than granting unrestricted S3 access.

Common Problems
Problem 1 — Terraform State File Missing

Symptoms:

terraform state list

returns no resources.

Possible cause:

Local state removed.
Remote state object deleted.
Incorrect backend configuration.
Incorrect S3 key.

Check the backend configuration and S3 object.

Problem 2 — Wrong S3 Key

For example, Terraform expects:

eks/terraform.tfstate

but the actual state is stored at:

terraform.tfstate

Terraform will initialize successfully but may appear to have no existing resources.

Always verify the configured:

bucket
key
region
Problem 3 — Backend Configuration Changed

If the backend configuration changes, run:

terraform init -reconfigure

Example:

terraform init -reconfigure
Problem 4 — Empty Terraform State

If:

terraform state list

returns nothing while AWS infrastructure already exists, do not immediately run:

terraform apply

First determine whether:

The wrong backend is configured.
The wrong S3 key is being used.
The state was deleted.
The infrastructure was created by another Terraform state.
Validation Checklist

Before moving to the next phase, verify:

[ ] S3 state bucket exists
[ ] S3 versioning is enabled
[ ] EKS state has a dedicated key
[ ] ECS state has a dedicated key
[ ] Terraform backend is configured
[ ] terraform init succeeds
[ ] terraform validate succeeds
[ ] terraform plan reads the remote state
[ ] terraform state list shows expected resources
[ ] Jenkins can initialize Terraform
[ ] Jenkins can access the state backend
[ ] terraform.tfstate is not committed to Git
[ ] S3 bucket is not publicly accessible
Evidence to Capture

Store implementation evidence under:

evidence/02-terraform/

Recommended evidence:

01-s3-state-bucket.png
02-s3-versioning.png
03-eks-state-object.png
04-ecs-state-object.png
05-terraform-init.png
06-terraform-state-list.png
07-s3-object-versions.png
08-jenkins-terraform-init.png
09-terraform-plan.png

Avoid capturing or committing sensitive information such as:

AWS access keys
Secret keys
Tokens
Passwords
Private credentials
Phase Completion Criteria

Phase 02 is considered complete when:

Terraform state is stored remotely in S3.
EKS and ECS use separate state keys.
S3 versioning is enabled.
Terraform can successfully initialize using the remote backend.
Terraform can read and update the remote state.
Jenkins can execute Terraform against the remote backend.
State recovery using S3 object versions has been validated or documented.
Terraform state files are excluded from Git.
Outcome

At the end of this phase, the project has a centralized Terraform state architecture suitable for infrastructure automation and CI/CD.

The resulting state structure is:

Amazon S3
│
└── twr-dev-002
    │
    ├── eks/
    │   └── terraform.tfstate
    │
    └── ecs/
        └── terraform.tfstate

This state-management layer becomes the foundation for the subsequent AWS infrastructure phases.


**File location:**

```text
docs/02-terraform-state/README.md

Then we can move to Phase 03 — AWS Network and Jump Host.


VPC Architecture

The VPC provides the isolated network boundary for the project.

Example architecture:

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

The exact CIDR ranges should match the Terraform configuration used by the project.

Network Components
VPC

The VPC is the primary network boundary.

It provides:

Private IP addressing
Subnet segmentation
Route table association
Internet connectivity
Network isolation

Example:

VPC
CIDR: Project-defined CIDR
Region: us-east-1
Public Subnets

Public subnets contain resources that require direct connectivity through the Internet Gateway.

The Jump Host is deployed in a public subnet.

Example:

Public Subnet
      |
      +-- Route Table
              |
              +-- 0.0.0.0/0
                    |
                    v
              Internet Gateway
Private Subnets

Private subnets are used for resources that should not have direct inbound Internet connectivity.

For example:

Private Subnet
      |
      +-- Route Table
              |
              +-- 0.0.0.0/0
                    |
                    v
               NAT Gateway
                    |
                    v
                 Internet

Private resources can initiate outbound connections through the NAT Gateway without requiring public IP addresses.

Internet Gateway

The Internet Gateway provides connectivity between the VPC and the public Internet.

The public subnet route table contains a default route similar to:

0.0.0.0/0
     |
     v
Internet Gateway

This enables resources in the public subnet with appropriate public IP addressing and security-group rules to communicate with the Internet.

NAT Gateway

The NAT Gateway provides outbound Internet connectivity for resources in private subnets.

The traffic flow is:

Private Resource
      |
      v
Private Route Table
      |
      v
NAT Gateway
      |
      v
Internet Gateway
      |
      v
Internet

The NAT Gateway does not provide unsolicited inbound Internet access to private resources.

Route Tables

The project uses separate routing logic for public and private subnets.

Public Route Table

Example:

Destination       Target

VPC CIDR          local
0.0.0.0/0         Internet Gateway
Private Route Table

Example:

Destination       Target

VPC CIDR          local
0.0.0.0/0         NAT Gateway

This separation provides the required network isolation.

Security Groups

Security groups control inbound and outbound traffic for AWS resources.

The project should follow the principle of least privilege.

Typical access requirements include:

SSH
TCP 22

HTTP
TCP 80

HTTPS
TCP 443

Additional ports should only be opened when required by the application architecture.

For example, administrative access to Jenkins or other internal tools should not automatically be exposed to the entire Internet.

Jump Host

The Jump Host is an EC2 instance deployed in the public subnet.

Its purpose is to provide an administrative environment for:

AWS CLI
Terraform
Kubernetes CLI
Docker
Jenkins administration
Ansible
Maven
Security tooling
Cluster administration
Infrastructure troubleshooting

Example architecture:

Administrator
      |
      | SSH
      v
+-------------------+
|    Jump Host      |
|                   |
| AWS CLI            |
| Terraform          |
| kubectl            |
| Docker             |
| Ansible            |
| Maven              |
| Security Tools     |
+---------+---------+
          |
          |
          v
     AWS Services
Jump Host IAM Role

The Jump Host uses an IAM role instead of storing long-term AWS access keys on the EC2 instance.

The instance profile attaches the IAM role to the EC2 instance.

Example flow:

EC2 Jump Host
      |
      v
IAM Instance Profile
      |
      v
IAM Role
      |
      v
AWS STS Temporary Credentials
      |
      v
AWS APIs

This is preferable to storing credentials such as:

AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY

directly on the server.

IAM Role Validation

After connecting to the Jump Host, verify the AWS identity:

aws sts get-caller-identity

Example:

{
    "UserId": "...",
    "Account": "...",
    "Arn": "arn:aws:sts::<account-id>:assumed-role/<role-name>/<instance-id>"
}

The returned ARN should show that the EC2 instance is using the expected IAM role.

Jump Host Bootstrap

The Jump Host is configured automatically using EC2 user data.

Terraform passes the bootstrap script to the instance.

Example Terraform configuration:

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

The user_data configuration causes the installation script to execute during the EC2 instance's initial boot.

Operating System

The Jump Host uses Ubuntu 24.04 LTS.

The bootstrap process installs the required DevOps tooling using the Ubuntu package-management system and vendor repositories where required.

The installation process includes tools such as:

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

The exact tooling installed should match the final version of install-tools.sh used by the project.

Java and Jenkins

Jenkins requires a supported Java runtime.

The Jump Host installs Java 21.

Validation:

java --version

Expected output should indicate Java 21.

Jenkins can then be validated using:

systemctl status jenkins

and:

jenkins --version
Jenkins Service Validation

Check the Jenkins service:

sudo systemctl status jenkins --no-pager -l

Check whether Jenkins is listening:

sudo ss -lntp | grep 8080

Local connectivity can be tested using:

curl -I http://localhost:8080

If Jenkins is running successfully, the service should listen on the configured Jenkins port.

Docker Validation

Verify Docker:

docker --version

Verify Docker Compose:

docker compose version

Verify the service:

sudo systemctl status docker

The Jenkins user should also have appropriate Docker access when Docker is used by Jenkins pipelines.

Terraform Validation

Verify Terraform:

terraform version

Terraform is used by the CI/CD pipelines to provision AWS infrastructure.

AWS CLI Validation

Verify:

aws --version

Then:

aws sts get-caller-identity

The second command confirms that the Jump Host can authenticate to AWS through its IAM role.

Kubernetes CLI

The Jump Host is also used for Kubernetes administration.

After the EKS cluster is created, the kubeconfig can be configured using:

aws eks update-kubeconfig \
  --region us-east-1 \
  --name twr-eks

Then validate:

kubectl get nodes

The Kubernetes CLI should be installed on the Jump Host before performing cluster administration.

Network Connectivity Validation
Public Connectivity

From the Jump Host:

curl -I https://www.google.com

Successful connectivity confirms outbound Internet access.

AWS API Connectivity

Run:

aws sts get-caller-identity

Successful output confirms:

Jump Host
    |
    v
AWS IAM
    |
    v
AWS API
Private Subnet Connectivity

Private resources should be able to access required external endpoints through the NAT Gateway when appropriate.

The expected path is:

Private Subnet
      |
      v
Private Route Table
      |
      v
NAT Gateway
      |
      v
Internet Gateway
      |
      v
Internet
SSH Access

The Jump Host is the controlled administrative entry point.

The general access flow is:

Administrator
      |
      | SSH
      v
Public IP / DNS
      |
      v
Jump Host
      |
      v
Private AWS Resources

SSH access should be restricted to trusted source addresses whenever possible.

Avoid:

0.0.0.0/0

for SSH access in production environments unless there is a specific security justification.

Security Considerations

The Jump Host is an Internet-facing administrative system and therefore requires additional security controls.

Recommended controls include:

Restrict SSH source IPs.
Use key-based authentication.
Avoid password authentication.
Keep the operating system updated.
Keep DevOps tools updated.
Use IAM roles instead of static AWS credentials.
Avoid storing secrets in shell scripts.
Avoid exposing unnecessary ports.
Monitor administrative activity.
Remove unused services.
Use least-privilege IAM policies.
Troubleshooting
Jenkins Is Not Installed

Check the installation log:

sudo tail -100 /var/log/install-tools.log

Check the package:

dpkg -l | grep jenkins

Check the repository:

cat /etc/apt/sources.list.d/jenkins.list

Then update the package repository:

sudo apt-get update
Jenkins Service Does Not Exist

Check:

systemctl status jenkins

If the service does not exist, inspect:

sudo tail -100 /var/log/install-tools.log

The bootstrap script may have stopped at an earlier installation step.

Java Is Missing

Check:

java --version

If Java is missing:

sudo apt-get install -y openjdk-21-jdk

Then:

java --version
Docker Is Missing

Check:

docker --version

Check:

systemctl status docker

If necessary:

sudo systemctl enable docker
sudo systemctl start docker
User Data Did Not Complete

EC2 user-data execution logs should be inspected.

Check:

sudo cat /var/log/cloud-init-output.log

and:

sudo cat /var/log/install-tools.log

These logs are especially useful when the installation script exits because of an error.

Validation Checklist

Before moving to the next phase, verify:

[ ] VPC created
[ ] Public subnets created
[ ] Private subnets created
[ ] Internet Gateway created
[ ] NAT Gateway created
[ ] Public route table configured
[ ] Private route table configured
[ ] Security groups configured
[ ] Jump Host created
[ ] IAM role attached to Jump Host
[ ] AWS CLI installed
[ ] Terraform installed
[ ] Java 21 installed
[ ] Jenkins installed
[ ] Docker installed
[ ] Ansible installed
[ ] Maven installed
[ ] Node.js installed
[ ] Security tooling installed
[ ] AWS STS authentication verified
[ ] Internet connectivity verified
[ ] Jenkins service verified
[ ] Docker service verified
[ ] Kubernetes administration tools available
Evidence to Capture

Store implementation evidence under:

evidence/03-aws-network/

Recommended evidence:

01-vpc.png
02-public-subnets.png
03-private-subnets.png
04-internet-gateway.png
05-nat-gateway.png
06-route-tables.png
07-security-groups.png
08-jumphost.png
09-jumphost-iam-role.png
10-aws-sts-identity.png
11-jumphost-tools.png
12-jenkins-service.png
13-docker-service.png
14-network-connectivity.png

Do not capture or commit:

AWS access keys
AWS secret keys
SSH private keys
Jenkins credentials
GitHub tokens
Database passwords
API tokens
Other sensitive credentials
Phase Completion Criteria

Phase 03 is considered complete when:

The VPC is successfully deployed.
Public and private subnet architecture is working.
Internet Gateway connectivity is verified.
NAT Gateway connectivity is verified.
Route tables are correctly associated.
Security groups enforce the required access.
The Jump Host is successfully deployed.
The Jump Host uses an IAM role.
AWS CLI authentication works without static AWS credentials.
Required DevOps tools are installed.
Jenkins is running successfully.
Docker is running successfully.
Network connectivity is verified.
The Jump Host is ready for EKS and CI/CD administration.
Outcome

At the end of this phase, the project has a functional AWS networking and administration layer.

The resulting architecture is:

                         Internet
                            |
                            v
                     Internet Gateway
                            |
                            v
                    +---------------+
                    | Public Subnet |
                    |               |
                    |  Jump Host    |
                    +-------+-------+
                            |
                       NAT Gateway
                            |
                            v
                    +---------------+
                    | Private       |
                    | Subnets       |
                    |               |
                    | EKS / Apps    |
                    +---------------+

The Jump Host provides the operational foundation for the remaining DevSecOps implementation phases.

The next phase builds the Amazon EKS cluster and Kubernetes infrastructure.