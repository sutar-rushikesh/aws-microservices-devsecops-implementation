# Phase 08 — Argo CD GitOps

## 1. Overview

This phase implements GitOps-based continuous delivery using Argo CD and Amazon EKS.

Argo CD continuously monitors Kubernetes manifests stored in Git and synchronizes the desired application state with the Kubernetes cluster.

The implementation separates the responsibilities of CI and CD:

```text
Developer
    |
    v
GitHub
    |
    v
Jenkins CI
    |
    +--> Build Docker Image
    |
    +--> Push Image to Amazon ECR
    |
    +--> Update Kubernetes Manifest
    |
    v
GitHub Kubernetes Manifests
    |
    v
Argo CD
    |
    v
Amazon EKS
    |
    v
Kubernetes Workloads
```

Jenkins is responsible for the CI workflow, while Argo CD is responsible for deploying the desired state into Kubernetes.

---

## 2. Objectives

The objectives of this phase are:

- Install Argo CD on Amazon EKS.
- Configure access to the Argo CD server.
- Connect Argo CD to the Git repository.
- Create Argo CD Applications.
- Configure automated synchronization.
- Deploy Kubernetes manifests using GitOps.
- Verify synchronization between Git and EKS.
- Verify application health through Argo CD.
- Demonstrate Git-driven deployment updates.
- Establish the foundation for continuous delivery.

---

## 3. GitOps Architecture

The GitOps architecture implemented in this project is:

```text
                    GitHub Repository
                           |
                           |
                  Kubernetes Manifests
                           |
                           v
                      Argo CD
                           |
                    Desired State
                           |
                           v
                    Amazon EKS
                           |
             +-------------+-------------+
             |             |             |
        Deployment     Deployment    Deployment
             |             |             |
           Pods          Pods          Pods
```

Argo CD acts as the reconciliation engine between Git and Kubernetes.

---

## 4. Argo CD Directory Structure

The project stores Argo CD application definitions under:

```text
argocd/
└── applications/
    ├── adservice.yaml
    ├── cartservice.yaml
    ├── checkoutservice.yaml
    ├── currencyservice.yaml
    ├── emailservice.yaml
    ├── frontend.yaml
    ├── paymentservice.yaml
    ├── productcatalogservice.yaml
    ├── recommendationservice.yaml
    └── shippingservice.yaml
```

The exact application files should reflect the microservices implemented in the project.

---

## 5. Prerequisites

Before installing Argo CD, verify that:

- The EKS cluster is active.
- EKS worker nodes are available.
- `kubectl` is installed.
- AWS CLI is configured.
- The Kubernetes context points to the correct EKS cluster.
- Kubernetes manifests are available in Git.
- The Git repository is accessible to Argo CD.

### Verify AWS Identity

```bash
aws sts get-caller-identity
```

### Verify the EKS Cluster

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

### Configure the Kubernetes Context

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name twr-eks
```

### Verify Current Context

```bash
kubectl config current-context
```

### Verify Nodes

```bash
kubectl get nodes
```

---

## 6. Install Argo CD

Create the Argo CD namespace:

```bash
kubectl create namespace argocd
```

Install Argo CD:

```bash
kubectl apply \
  -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Verify the installation:

```bash
kubectl get pods -n argocd
```

The Argo CD components should eventually reach:

```text
STATUS: Running
```

---

## 7. Verify Argo CD Components

Run:

```bash
kubectl get pods -n argocd
```

Typical components include:

```text
argocd-application-controller
argocd-applicationset-controller
argocd-dex-server
argocd-notifications-controller
argocd-redis
argocd-repo-server
argocd-server
```

Verify Services:

```bash
kubectl get svc -n argocd
```

Verify all resources:

```bash
kubectl get all -n argocd
```

---

## 8. Expose Argo CD Server

By default, the Argo CD server Service can use `ClusterIP`.

Check the Service:

```bash
kubectl get svc argocd-server -n argocd
```

To expose the Argo CD server externally through an AWS LoadBalancer:

```bash
kubectl edit svc argocd-server -n argocd
```

Find:

```yaml
type: ClusterIP
```

Change it to:

```yaml
type: LoadBalancer
```

Save and exit.

Verify:

```bash
kubectl get svc argocd-server -n argocd
```

Example:

```text
NAME            TYPE           CLUSTER-IP     EXTERNAL-IP
argocd-server   LoadBalancer   10.x.x.x       <AWS-LOAD-BALANCER-DNS>
```

Wait until AWS assigns the external endpoint.

---

## 9. Retrieve Argo CD Endpoint

Run:

```bash
kubectl get svc argocd-server \
  -n argocd \
  -o wide
```

Or:

```bash
kubectl get svc argocd-server \
  -n argocd \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

The returned hostname is the external endpoint for the Argo CD server.

---

## 10. Retrieve Initial Admin Password

Argo CD creates an initial administrative password in a Kubernetes Secret.

Retrieve it with:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

The default Argo CD username is:

```text
admin
```

The retrieved password should be treated as a secret.

Do not commit the password to Git.

---

## 11. Argo CD CLI Login

If the Argo CD CLI is installed, obtain the LoadBalancer endpoint:

```bash
ARGOCD_SERVER=$(kubectl get svc argocd-server \
  -n argocd \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

Login:

```bash
argocd login $ARGOCD_SERVER \
  --username admin \
  --password <PASSWORD> \
  --insecure
```

Verify:

```bash
argocd account get-user-info
```

---

## 12. Access Through the Web UI

Open the Argo CD LoadBalancer endpoint in a browser.

Use:

```text
Username: admin
Password: <initial admin password>
```

After successful login, the Argo CD dashboard displays:

- Applications
- Application health
- Sync status
- Kubernetes resources
- Repository information
- Deployment status

---

## 13. Connect Argo CD to Git

Argo CD needs access to the Git repository containing the Kubernetes manifests.

For a public repository, Argo CD can generally access the repository directly.

For a private repository, configure repository credentials using the Argo CD UI or CLI.

Example CLI pattern:

```bash
argocd repo add https://github.com/<USERNAME>/<REPOSITORY>.git
```

For authenticated private repositories, use the appropriate Git credentials or token.

Never commit Git credentials or tokens into the repository.

---

## 14. Argo CD Application

An Argo CD Application defines:

- Source Git repository
- Repository path
- Target Kubernetes cluster
- Target namespace
- Synchronization policy

Example:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: microservices
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/<USERNAME>/<REPOSITORY>.git
    targetRevision: main
    path: kubernetes

  destination:
    server: https://kubernetes.default.svc
    namespace: microservices

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Update the repository URL and path according to the actual project structure.

---

## 15. Application Per Microservice

If the project uses separate Argo CD Applications for individual microservices, the structure can be:

```text
Argo CD
   |
   +--> adservice
   |
   +--> cartservice
   |
   +--> checkoutservice
   |
   +--> currencyservice
   |
   +--> frontend
   |
   +--> paymentservice
   |
   +--> productcatalogservice
   |
   +--> recommendationservice
   |
   +--> shippingservice
```

This provides independent visibility and synchronization status for each service.

---

## 16. Create Argo CD Application

Apply an Application manifest:

```bash
kubectl apply -f argocd/applications/
```

Verify:

```bash
kubectl get applications -n argocd
```

Example:

```text
NAME          SYNC STATUS   HEALTH STATUS
adservice     Synced        Healthy
cartservice   Synced        Healthy
frontend      Synced        Healthy
```

---

## 17. Verify Application Details

For an individual application:

```bash
kubectl get application adservice -n argocd
```

Detailed output:

```bash
kubectl describe application adservice -n argocd
```

Using the Argo CD CLI:

```bash
argocd app get adservice
```

---

## 18. Synchronization

Argo CD compares the state stored in Git with the state running in Kubernetes.

The basic workflow is:

```text
Git Repository
      |
      | Desired State
      v
   Argo CD
      |
      | Reconciliation
      v
Amazon EKS
      |
      | Actual State
      v
Kubernetes Resources
```

When the states differ, Argo CD detects the difference.

---

## 19. Manual Synchronization

An application can be synchronized manually:

```bash
argocd app sync adservice
```

Check status:

```bash
argocd app get adservice
```

Expected:

```text
Sync Status: Synced
Health Status: Healthy
```

---

## 20. Automated Synchronization

The project can use automated synchronization:

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

### Automated Sync

Argo CD automatically applies changes detected in Git.

### Prune

Resources removed from Git can be removed from Kubernetes.

### Self-Heal

If the live Kubernetes state is manually changed, Argo CD can restore the Git-defined desired state.

---

## 21. GitOps Deployment Flow

The complete application deployment flow is:

```text
Developer
    |
    v
GitHub
    |
    v
Jenkins
    |
    +--> Build Application
    |
    +--> Docker Build
    |
    +--> Security Scan
    |
    +--> Push Image
    |       |
    |       v
    |     Amazon ECR
    |
    +--> Update Kubernetes Manifest
            |
            v
        GitHub
            |
            v
         Argo CD
            |
            v
         Amazon EKS
            |
            v
      Kubernetes Pods
```

This separates image creation from application deployment.

---

## 22. Image Version Update

The CI pipeline updates the Kubernetes manifest with the newly created ECR image tag.

Example:

```yaml
image: 264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:25
```

A new Jenkins build may update it to:

```yaml
image: 264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:26
```

The change is committed to Git.

Argo CD detects the Git change and synchronizes the Kubernetes Deployment.

---

## 23. Verify GitOps Deployment

After the image manifest is updated:

Check Argo CD:

```bash
argocd app get adservice
```

Check Kubernetes:

```bash
kubectl get deployment adservice -n microservices
```

Check Pods:

```bash
kubectl get pods -n microservices
```

Check the deployed image:

```bash
kubectl get deployment adservice \
  -n microservices \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
```

Expected:

```text
264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:<BUILD_NUMBER>
```

---

## 24. Verify Rollout

Run:

```bash
kubectl rollout status deployment/adservice \
  -n microservices
```

Expected:

```text
deployment "adservice" successfully rolled out
```

Check ReplicaSets:

```bash
kubectl get rs -n microservices
```

---

## 25. Argo CD Application Health

An application can have different health states.

Typical states include:

```text
Healthy
Progressing
Degraded
Suspended
Missing
Unknown
```

The target state is:

```text
SYNC STATUS: Synced
HEALTH: Healthy
```

If an application is Degraded, inspect the associated Kubernetes resources and application events.

---

## 26. Troubleshooting Argo CD

### Application is OutOfSync

Check:

```bash
argocd app diff adservice
```

Then synchronize:

```bash
argocd app sync adservice
```

### Application is Degraded

Check:

```bash
argocd app get adservice
```

Check Kubernetes:

```bash
kubectl get pods -n microservices
```

Inspect failed Pods:

```bash
kubectl describe pod <pod-name> -n microservices
```

Check logs:

```bash
kubectl logs <pod-name> -n microservices
```

### Repository Cannot Be Accessed

Check:

```bash
argocd repo list
```

Verify the repository URL and credentials.

For a private repository, confirm that the configured Git credentials have repository access.

### ImagePullBackOff

Check:

```bash
kubectl describe pod <pod-name> -n microservices
```

Verify:

```text
ECR repository
Image name
Image tag
EKS node permissions
```

### Argo CD Server Is Not Accessible

Check:

```bash
kubectl get svc argocd-server -n argocd
```

Check Argo CD Pods:

```bash
kubectl get pods -n argocd
```

Check the service:

```bash
kubectl describe svc argocd-server -n argocd
```

---

## 27. Argo CD Resource Verification

Run:

```bash
kubectl get applications -n argocd
kubectl get appprojects -n argocd
kubectl get pods -n argocd
kubectl get svc -n argocd
kubectl get deployments -n argocd
```

---

## 28. Evidence to Capture

Store screenshots and command outputs under:

```text
evidence/08-argocd/
```

Recommended evidence:

```text
01-argocd-installation.png
02-argocd-pods-running.png
03-argocd-services.png
04-argocd-loadbalancer.png
05-argocd-login.png
06-argocd-dashboard.png
07-argocd-application-list.png
08-argocd-application-synced.png
09-argocd-application-healthy.png
10-argocd-resource-tree.png
11-argocd-git-repository.png
12-argocd-gitops-sync.png
13-kubernetes-pods-after-sync.png
14-updated-image-version.png
```

The most important evidence is the Argo CD Application showing:

```text
SYNC STATUS: Synced
HEALTH STATUS: Healthy
```

along with the corresponding Kubernetes resources.

---

## 29. Security Considerations

Argo CD access should be protected.

Recommended practices:

- Do not expose Argo CD unnecessarily.
- Use HTTPS for production access.
- Use strong administrative credentials.
- Rotate the initial admin password.
- Use dedicated repository credentials.
- Never commit Git tokens to source control.
- Use least-privilege RBAC.
- Restrict Argo CD project permissions.
- Avoid giving applications unnecessary cluster-wide permissions.
- Protect the Argo CD endpoint using appropriate network controls.

---

## 30. GitOps Benefits

The implemented GitOps model provides:

### Version-Controlled Deployments

Every Kubernetes configuration change is stored in Git.

### Auditability

Git history provides a record of deployment configuration changes.

### Reconciliation

Argo CD continuously compares Git state with Kubernetes state.

### Self-Healing

Configuration drift can automatically be corrected.

### Rollback

Previous Git revisions can be restored when required.

### Separation of Responsibilities

Jenkins handles CI while Argo CD handles CD.

---

## 31. End-to-End GitOps Validation

Perform the following validation:

### Step 1 — Update Application Image

Jenkins builds a new Docker image.

```text
Build #N
    |
    v
Amazon ECR
```

### Step 2 — Update Kubernetes Manifest

The CI pipeline updates the image tag.

```yaml
image: <ECR-IMAGE>:<BUILD_NUMBER>
```

### Step 3 — Commit to Git

The updated manifest is pushed to the Git repository.

### Step 4 — Argo CD Detects the Change

Argo CD detects that the Git desired state has changed.

### Step 5 — Argo CD Synchronizes

The Kubernetes Deployment is updated.

### Step 6 — Kubernetes Rolls Out the New Pods

Verify:

```bash
kubectl rollout status deployment/<service-name> \
  -n microservices
```

### Step 7 — Verify Application

Check:

```bash
kubectl get pods -n microservices
```

and verify the application through the frontend endpoint.

---

## 32. Phase Completion Criteria

Phase 08 is considered complete when:

```text
[ ] Argo CD is installed on the EKS cluster.
[ ] Argo CD Pods are running.
[ ] Argo CD server is accessible.
[ ] Git repository is configured.
[ ] Argo CD Applications are created.
[ ] Kubernetes manifests are synchronized from Git.
[ ] Applications show Synced.
[ ] Applications show Healthy.
[ ] ECR image updates are reflected in Kubernetes.
[ ] Git changes trigger the expected deployment update.
[ ] Kubernetes workloads remain synchronized with Git.
[ ] Evidence has been captured.
```

---

## 33. Final Architecture

After completing this phase, the deployment architecture is:

```text
                    Developer
                        |
                        v
                    GitHub
                        |
             +----------+----------+
             |                     |
             v                     v
        Jenkins CI            Kubernetes
             |                 Manifests
             v                     |
        Amazon ECR                 |
             |                     |
             +----------+----------+
                        |
                        v
                     Argo CD
                        |
                        v
                    Amazon EKS
                        |
              +---------+---------+
              |         |         |
             Pod       Pod       Pod
              |         |         |
              +---------+---------+
                        |
                        v
                   Application
```

This establishes the GitOps continuous delivery layer of the DevSecOps platform.

---

## 34. Next Phase

The next phase covers:

```text
Phase 09 — Route 53 DNS
```

This phase will document DNS configuration, domain mapping, AWS LoadBalancer integration, and application accessibility through the project domain.