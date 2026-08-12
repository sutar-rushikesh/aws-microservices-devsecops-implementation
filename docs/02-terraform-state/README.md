# Phase 02 — Terraform State Management

## Overview

This phase establishes centralized and reliable Terraform state management using an Amazon S3 backend.

Terraform state is critical because it maintains the mapping between the Terraform configuration and the infrastructure resources deployed in AWS.

For this project, the Terraform state is stored remotely in Amazon S3 rather than locally on the Jenkins or developer machine.

The remote state design provides:

- Centralized state storage
- Persistent state outside the Terraform working directory
- State version history
- Recovery from accidental state changes
- Consistent state access for CI/CD pipelines
- Separation of state between infrastructure components

---

## Objectives

The objectives of this phase are:

1. Create an S3 bucket for Terraform state.
2. Enable S3 versioning.
3. Organize state using separate object keys.
4. Configure Terraform backends to use the S3 bucket.
5. Validate remote state initialization.
6. Verify state persistence.
7. Support Jenkins-based Terraform execution.
8. Provide a recovery mechanism for accidentally deleted or modified state.

---

## Architecture

```text
                         Developer / Jenkins
                                |
                                |
                         Terraform CLI
                                |
                                v
                     +----------------------+
                     |    Terraform Backend |
                     +----------------------+
                                |
                                v
                     +----------------------+
                     |       Amazon S3      |
                     |                      |
                     |  twr-dev-002         |
                     |                      |
                     |  ├── eks/            |
                     |  │   └── terraform.tfstate
                     |  │
                     |  └── ecs/            |
                     |      └── terraform.tfstate
                     +----------------------+


---

## 
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