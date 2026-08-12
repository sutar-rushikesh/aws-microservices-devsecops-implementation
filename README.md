<div align="center">

# AWS Microservices DevSecOps Implementation

### End-to-End Enterprise DevSecOps Platform on AWS

<p align="center">

CI • CD • Docker • Kubernetes • GKE • Jenkins • SonarQube • Trivy • Artifact Registry • ArgoCD • Prometheus • Grafana • NGINX Ingress • TLS/SSL • Terraform

</p>

<img src="./application/profile.jpeg" width="180" style="border-radius:50%" alt="Rushikesh Sutar">

### 👨‍💻 Created by Rushikesh Sutar

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Rushikesh%20Sutar-blue?style=for-the-badge&logo=linkedin)](https://www.linkedin.com/in/devopswithrushikesh)

[![GitHub](https://img.shields.io/badge/GitHub-sutar--rushikesh-black?style=for-the-badge&logo=github)](https://github.com/sutar-rushikesh)

</div>

---

A complete implementation and documentation repository for an AWS-based microservices DevSecOps platform.

## Project Overview

This repository documents the implementation of a production-style DevSecOps platform using AWS infrastructure, Infrastructure as Code, CI/CD, containerization, Kubernetes, GitOps, DNS, monitoring, alerting, and end-to-end validation.

The repository is organized into implementation phases so that each major component of the platform can be understood, reproduced, and validated independently.

## Technology Stack

- AWS
- Terraform
- Amazon EKS
- Amazon ECR
- Docker
- Jenkins
- Kubernetes
- Argo CD
- GitOps
- Route 53
- Prometheus
- Grafana
- Alertmanager
- GitHub
- Linux

## Repository Structure
---

\\\	ext
aws-microservices-devsecops-implementation/
│
├── README.md
├── .gitignore
│
├── docs/
│   ├── 01-architecture/
│   ├── 02-terraform-state/
│   ├── 03-aws-network-and-jumphost/
│   ├── 04-eks/
│   ├── 05-ecr/
│   ├── 06-jenkins-ci/
│   ├── 07-kubernetes/
│   ├── 08-argocd-gitops/
│   ├── 09-route53-dns/
│   ├── 10-monitoring/
│   ├── 11-alerting/
│   └── 12-end-to-end-validation/
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
\\\

---

## Implementation Phases

---
| Phase | Area |
|---|---|
| 01 | Architecture |
| 02 | Terraform State |
| 03 | AWS Network & Jump Host |
| 04 | Amazon EKS |
| 05 | Amazon ECR |
| 06 | Jenkins CI |
| 07 | Kubernetes |
| 08 | Argo CD GitOps |
| 09 | Route 53 DNS |
| 10 | Monitoring |
| 11 | Alerting |
| 12 | End-to-End Validation |
---
## Documentation

Detailed implementation documentation is maintained under the \docs/\ directory.

Each phase documents:

- Objective
- Architecture
- Prerequisites
- Implementation
- Configuration
- Commands
- Validation
- Troubleshooting
- Evidence
- Lessons learned

## Evidence

The \evidence/\ directory contains screenshots, command outputs, configuration evidence, and validation artifacts associated with each implementation phase.

Sensitive information such as:

- AWS credentials
- Access keys
- Private keys
- GitHub tokens
- Passwords
- Kubernetes secrets

must never be committed to this repository.

## Status

Implementation completed and documented phase-by-phase.

Infrastructure resources may be destroyed after the required evidence and documentation have been captured.
# 👨‍💻 Author

## Rushikesh Sutar

Senior Software Engineer — DevSecOps | Cloud | Kubernetes | Terraform | AWS | GCP

### GitHub

https://github.com/sutar-rushikesh

### LinkedIn

https://www.linkedin.com/in/devopswithrushikesh

---

# ⭐ Support

If you found this project useful:

⭐ Star this repository

🍴 Fork this repository

📢 Share it with the DevOps community

🤝 Connect with me on LinkedIn

---

<div align="center">

### Thank you for visiting this repository ❤️

**Happy Learning!**
## License

This project is intended for educational, portfolio, and technical demonstration purposes.
<div align="center">
