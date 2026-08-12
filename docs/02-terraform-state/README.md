# Phase 02 — Terraform State Management

## 📌 Overview

Phase 02 establishes centralized and reliable **Terraform state management** using an **Amazon S3 remote backend**.

Terraform state maintains the mapping between the Terraform configuration and the infrastructure resources deployed in AWS.

For this project, Terraform state is stored remotely in Amazon S3 rather than locally on the Jenkins or developer machine.

The remote-state architecture provides:

* Centralized state storage
* Persistent state outside the Terraform working directory
* State version history
* Recovery from accidental state changes
* Consistent state access for CI/CD pipelines
* Separation of state between infrastructure components

This phase establishes the state-management foundation required for the remaining infrastructure implementation phases.

---

# 🎯 Objectives

The objectives of Phase 02 are:

1. Create an S3 bucket for Terraform state.
2. Enable S3 versioning.
3. Organize state using separate object keys.
4. Configure Terraform backends to use the S3 bucket.
5. Validate remote state initialization.
6. Verify state persistence.
7. Support Jenkins-based Terraform execution.
8. Provide a recovery mechanism for accidentally deleted or modified state.
9. Protect Terraform state from unauthorized or accidental access.
10. Ensure Terraform state files are not committed to Git.

---

# 🏗️ Architecture

The Terraform state architecture is based on a centralized Amazon S3 backend.

```text
                    Developer / Jenkins
                           │
                           ▼
                     Terraform CLI
                           │
                           ▼
                  ┌──────────────────┐
                  │ Terraform Backend│
                  │       S3         │
                  └────────┬─────────┘
                           │
                           ▼
                  ┌──────────────────┐
                  │    Amazon S3     │
                  │                  │
                  │   twr-dev-002    │
                  │                  │
                  │   ├── eks/       │
                  │   │   └──        │
                  │   │      terraform.tfstate
                  │   │              │
                  │   └── ecs/       │
                  │       └──        │
                  │          terraform.tfstate
                  └──────────────────┘
```

The S3 bucket acts as the centralized and persistent location for Terraform state.

---

# 🪣 Terraform State Bucket

The project uses an Amazon S3 bucket as the centralized Terraform state backend.

### Bucket

```text
twr-dev-002
```

Terraform state is separated using different S3 object prefixes.

### EKS State

```text
s3://twr-dev-002/eks/terraform.tfstate
```

### ECS State

```text
s3://twr-dev-002/ecs/terraform.tfstate
```

This separation prevents unrelated Terraform configurations from sharing the same state file.

---

# 💡 Why Remote State Is Required

Using a local state file such as:

```text
terraform.tfstate
```

creates several problems in a CI/CD environment.

### Problems with Local State

* State exists only on one machine.
* Jenkins cannot reliably share the same state with developers.
* State can be accidentally deleted.
* Multiple users can work with different state copies.
* Recovery becomes difficult.
* CI/CD execution becomes dependent on a particular workspace.

### Remote State Solution

Remote state solves these problems by storing the Terraform state centrally in Amazon S3.

```text
Local Terraform State
        │
        └── Machine dependent
        └── Difficult to share
        └── Difficult to recover

Remote Terraform State
        │
        └── Centralized
        └── Persistent
        └── CI/CD compatible
        └── Versioned
        └── Recoverable
```

---

# 🗂️ S3 Versioning

S3 versioning should be enabled on the Terraform state bucket.

Versioning provides historical versions of:

```text
terraform.tfstate
```

If the latest state is accidentally deleted or corrupted, an earlier version can potentially be recovered.

### Example Version History

```text
terraform.tfstate
       │
       ├── Version 1
       │
       ├── Version 2
       │
       ├── Version 3
       │
       └── Version 4
```

The latest version is normally used by Terraform while previous versions remain available for recovery when versioning is enabled.

---

# ⚙️ Backend Configuration

Terraform configurations can use an S3 backend similar to:

```hcl
terraform {
  backend "s3" {
    bucket = "twr-dev-002"
    key    = "eks/terraform.tfstate"
    region = "us-east-1"
  }
}
```

For another infrastructure component, a different state key should be used.

Example:

```hcl
terraform {
  backend "s3" {
    bucket = "twr-dev-002"
    key    = "ecs/terraform.tfstate"
    region = "us-east-1"
  }
}
```

The important difference is the S3 object key.

---

# 🔀 Backend Separation

The project follows the following state structure:

```text
twr-dev-002/
│
├── eks/
│   └── terraform.tfstate
│
└── ecs/
    └── terraform.tfstate
```

This allows EKS and ECS infrastructure to maintain independent Terraform state.

### State Mapping

```text
EKS Terraform Configuration
          │
          └──► eks/terraform.tfstate


ECS Terraform Configuration
          │
          └──► ecs/terraform.tfstate
```

This is preferable to using a single shared state file for unrelated infrastructure.

---

# 🚀 Terraform Initialization

After configuring the backend, initialize Terraform:

```bash
terraform init
```

Terraform connects to the configured S3 backend and initializes the working directory.

### Expected Output

```text
Initializing the backend...

Successfully configured the backend "s3"!
```

If the backend configuration has changed, use:

```bash
terraform init -reconfigure
```

This tells Terraform to reconfigure the backend using the current configuration.

---

# 🔍 Backend Validation

Initialize Terraform:

```bash
terraform init
```

A successful initialization should allow Terraform to operate using the remote state.

For example:

```bash
terraform plan
```

and:

```bash
terraform apply
```

The Terraform commands should read and update the remote state stored in Amazon S3.

---

# 📋 State Validation

The Terraform state can be inspected using:

```bash
terraform state list
```

Example output:

```text
aws_vpc.main
aws_subnet.public
aws_subnet.private
aws_internet_gateway.main
aws_route_table.public
```

The exact resources depend on the Terraform configuration.

The important point is that the Terraform state is being managed remotely.

---

# ☁️ Verify State in Amazon S3

The AWS CLI can be used to verify the state object.

### EKS State

```bash
aws s3 ls s3://twr-dev-002/eks/
```

Expected structure:

```text
eks/
└── terraform.tfstate
```

### ECS State

```bash
aws s3 ls s3://twr-dev-002/ecs/
```

Expected structure:

```text
ecs/
└── terraform.tfstate
```

---

# 🕐 Verify S3 State Version History

To inspect state versions:

```bash
aws s3api list-object-versions \
  --bucket twr-dev-002 \
  --prefix eks/terraform.tfstate \
  --region us-east-1
```

The response can provide information such as:

* Version ID
* Last modified time
* Object size
* Latest version
* Previous versions

Example fields:

```text
VersionId
IsLatest
LastModified
Size
```

This information is useful when investigating accidental state deletion or corruption.

---

# ♻️ Terraform State Recovery

If the current Terraform state is accidentally deleted, first verify whether S3 versioning is enabled.

Check the available versions:

```bash
aws s3api list-object-versions \
  --bucket twr-dev-002 \
  --prefix eks/terraform.tfstate \
  --region us-east-1
```

Identify the required previous version before attempting recovery.

## ⚠️ Important

Do **not** immediately run:

```bash
terraform apply
```

when the Terraform state is missing.

Terraform may interpret the existing infrastructure as unmanaged and attempt to create resources that already exist.

---

# 🔄 State Recovery Procedure

The recommended recovery process is:

```text
Identify Missing State
        │
        ▼
Check S3 Object Versions
        │
        ▼
Identify Correct Previous Version
        │
        ▼
Restore State
        │
        ▼
Run terraform init
        │
        ▼
Run terraform state list
        │
        ▼
Run terraform plan
        │
        ▼
Verify Expected Infrastructure Changes
```

---

# ⚠️ Recovery Considerations

Terraform state should never be restored blindly.

Before restoring a previous state version:

* Confirm the version belongs to the correct Terraform configuration.
* Confirm the S3 key is correct.
* Confirm the AWS account is correct.
* Confirm the AWS region is correct.
* Verify that the infrastructure still exists.
* Run `terraform plan` after recovery.
* Review the plan carefully before applying changes.

---

# 🔐 AWS Identity Validation

Verify the AWS identity being used for Terraform state operations:

```bash
aws sts get-caller-identity
```

Verify the configured AWS region:

```bash
aws configure get region
```

Example:

```text
us-east-1
```

These checks are important because using the wrong AWS account or region can result in inspecting the wrong S3 bucket or infrastructure environment.

---

# 🔄 Jenkins Integration

Jenkins uses the same remote Terraform backend.

The general workflow is:

```text
Jenkins
   │
   ▼
Checkout Terraform Repository
   │
   ▼
terraform init
   │
   ▼
S3 Remote Backend
   │
   ▼
terraform validate
   │
   ▼
terraform plan
   │
   ▼
terraform apply
```

Jenkins should **not** depend on a state file stored only inside:

```text
/var/lib/jenkins/workspace/
```

The Jenkins workspace is temporary and can be deleted or recreated.

The authoritative Terraform state should remain in Amazon S3.

---

# 🔄 CI/CD State Flow

```text
                    Jenkins
                       │
                       ▼
                Terraform Init
                       │
                       ▼
              ┌──────────────────┐
              │    Amazon S3     │
              │ Terraform State │
              └────────┬─────────┘
                       │
                       ▼
                Terraform Plan
                       │
                       ▼
                Terraform Apply
                       │
                       ▼
               AWS Infrastructure
```

---

# 🔐 State Isolation

Each Terraform component should have its own state key.

Example:

```text
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
```

This provides logical separation between infrastructure components.

For example, a change to the EKS Terraform configuration should not directly modify the ECS state.

---

# 🔒 Security Considerations

Terraform state can contain sensitive infrastructure information.

Therefore:

* Do not commit `terraform.tfstate` to Git.
* Do not commit `terraform.tfstate.backup` to Git.
* Restrict S3 bucket access.
* Use IAM policies following least-privilege principles.
* Enable S3 versioning.
* Do not expose the state bucket publicly.
* Do not store AWS credentials inside Terraform files.
* Use IAM roles where possible for AWS workloads.
* Protect Jenkins credentials.

### Recommended `.gitignore`

```gitignore
*.tfstate
*.tfstate.*
.terraform/
```

> The Terraform dependency lock file `.terraform.lock.hcl` is normally retained in source control so provider versions remain reproducible.

---

# 👮 Recommended IAM Permissions

The Jenkins execution identity should have only the permissions required for the Terraform workflow.

For the Terraform state bucket, access may need to cover operations such as:

```text
ListBucket
GetObject
PutObject
DeleteObject
```

Permissions should be scoped to the required bucket and prefixes rather than granting unrestricted S3 access.

---

# 🐛 Common Problems & Troubleshooting

## Problem 1 — Terraform State File Missing

### Symptoms

Running:

```bash
terraform state list
```

returns no resources.

### Possible Causes

* Local state was removed.
* Remote state object was deleted.
* Incorrect backend configuration.
* Incorrect S3 key.

### Resolution

Check:

1. Backend configuration.
2. S3 bucket.
3. S3 object key.
4. S3 object versions.
5. AWS account and region.

---

## Problem 2 — Wrong S3 Key

For example, Terraform expects:

```text
eks/terraform.tfstate
```

but the actual state is stored at:

```text
terraform.tfstate
```

Terraform may initialize successfully but appear to contain no existing resources.

Always verify:

```text
Bucket
Key
Region
```

---

## Problem 3 — Backend Configuration Changed

If the backend configuration changes, run:

```bash
terraform init -reconfigure
```

Example:

```bash
terraform init -reconfigure
```

---

## Problem 4 — Empty Terraform State

If:

```bash
terraform state list
```

returns nothing while AWS infrastructure already exists, do **not** immediately run:

```bash
terraform apply
```

First determine whether:

* The wrong backend is configured.
* The wrong S3 key is being used.
* The state was deleted.
* The infrastructure was created by another Terraform state.

---

# 🧪 Validation Checklist

Before moving to the next phase, verify:

* [ ] S3 state bucket exists.
* [ ] S3 versioning is enabled.
* [ ] EKS state has a dedicated key.
* [ ] ECS state has a dedicated key.
* [ ] Terraform backend is configured.
* [ ] `terraform init` succeeds.
* [ ] `terraform validate` succeeds.
* [ ] `terraform plan` reads the remote state.
* [ ] `terraform state list` shows expected resources.
* [ ] Jenkins can initialize Terraform.
* [ ] Jenkins can access the state backend.
* [ ] Terraform state files are not committed to Git.
* [ ] S3 bucket is not publicly accessible.
* [ ] State recovery procedure is documented or validated.

---

# 📸 Evidence Collection

Store Phase 02 implementation evidence under:

```text
evidence/02-terraform/
```

Recommended evidence:

```text
evidence/02-terraform/
│
├── 01-s3-state-bucket.png
├── 02-s3-versioning.png
├── 03-eks-state-object.png
├── 04-ecs-state-object.png
├── 05-terraform-init.png
├── 06-terraform-state-list.png
├── 07-s3-object-versions.png
├── 08-jenkins-terraform-init.png
└── 09-terraform-plan.png
```

### 🔒 Do Not Capture Sensitive Information

Avoid capturing or committing:

* AWS access keys
* AWS secret keys
* Tokens
* Passwords
* Private credentials
* Other sensitive account information

---

# ✅ Phase Completion Criteria

Phase 02 is considered complete when:

* [ ] Terraform state is stored remotely in Amazon S3.
* [ ] EKS and ECS use separate state keys.
* [ ] S3 versioning is enabled.
* [ ] Terraform successfully initializes using the remote backend.
* [ ] Terraform can read and update the remote state.
* [ ] Jenkins can execute Terraform against the remote backend.
* [ ] State recovery using S3 object versions is documented or validated.
* [ ] Terraform state files are excluded from Git.

---

# 📊 Phase Status

| Area                     | Status       |
| ------------------------ | ------------ |
| S3 State Bucket          | ✅ Configured |
| Remote Backend           | ✅ Configured |
| S3 Versioning            | ✅ Configured |
| EKS State Key            | ✅ Defined    |
| ECS State Key            | ✅ Defined    |
| Terraform Initialization | ✅ Defined    |
| State Validation         | ✅ Defined    |
| State Recovery           | ✅ Documented |
| Jenkins Integration      | ✅ Defined    |
| Security Controls        | ✅ Defined    |
| Evidence Structure       | ✅ Defined    |

---

# 📝 Outcome

At the end of Phase 02, the project has a centralized Terraform state architecture suitable for infrastructure automation and CI/CD.

The resulting state structure is:

```text
Amazon S3
│
└── twr-dev-002
    │
    ├── eks/
    │   └── terraform.tfstate
    │
    └── ecs/
        └── terraform.tfstate
```

This state-management layer becomes the foundation for the subsequent AWS infrastructure phases.

---

## 📚 Related Phases

| Phase    | Documentation                                                   |
| -------- | --------------------------------------------------------------- |
| Phase 01 | [AWS Microservices DevSecOps Architecture](../01-architecture/) |
| Phase 02 | **Terraform State Management**                                  |
| Phase 03 | [AWS Network & Jump Host](../03-aws-network-and-jumphost/)      |

---

**Phase 02 — Terraform State Management**
**Next:** [Phase 03 — AWS Network & Jump Host →](../03-aws-network-and-jumphost/)
