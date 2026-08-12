# Phase 07 — Kubernetes Deployment

## 1. Overview

This phase covers the deployment of the microservices application into the Amazon EKS cluster using Kubernetes manifests.

The Kubernetes layer is responsible for running the containerized microservices, exposing the required services, and providing the deployment configuration consumed by the GitOps workflow.

The implementation uses Kubernetes Deployments and Services, with configuration organized into separate directories for maintainability.

---

## 2. Objectives

The main objectives of this phase are:

- Deploy microservices workloads into Amazon EKS.
- Define Kubernetes Deployments for application services.
- Define Kubernetes Services for application connectivity.
- Configure application namespaces.
- Configure container images from Amazon ECR.
- Configure replica counts and container ports.
- Verify that pods and services are running successfully.
- Prepare Kubernetes manifests for Argo CD GitOps deployment.
- Validate application accessibility through the Kubernetes service layer.

---

## 3. Kubernetes Architecture

The Kubernetes deployment follows this structure:

```text
                    Amazon EKS Cluster
                           |
                           |
                    Kubernetes Namespace
                           |
             +-------------+-------------+
             |                           |
       Deployments                   Services
             |                           |
       +-----+-----+             +------+------+
       |           |             |             |
   Microservice  Microservice   ClusterIP   LoadBalancer
       |           |             |             |
       +-----------+-------------+-------------+
                           |
                    Application Traffic
```

---

## 4. Kubernetes Directory Structure

The Kubernetes manifests are organized as follows:

```text
kubernetes/
│
├── namespace/
│   └── namespace.yaml
│
├── deployments/
│   ├── adservice.yaml
│   ├── cartservice.yaml
│   ├── checkoutservice.yaml
│   ├── currencyservice.yaml
│   ├── emailservice.yaml
│   ├── frontend.yaml
│   ├── paymentservice.yaml
│   ├── productcatalogservice.yaml
│   ├── recommendationservice.yaml
│   ├── shippingservice.yaml
│   └── ...
│
├── services/
│   ├── adservice.yaml
│   ├── cartservice.yaml
│   ├── checkoutservice.yaml
│   ├── currencyservice.yaml
│   ├── emailservice.yaml
│   ├── frontend.yaml
│   ├── paymentservice.yaml
│   ├── productcatalogservice.yaml
│   ├── recommendationservice.yaml
│   ├── shippingservice.yaml
│   └── ...
│
└── config/
    └── application configuration files
```

The exact microservice files should reflect the services implemented in the project.

---

## 5. Kubernetes Namespace

A dedicated namespace can be used to logically isolate the application workloads.

Example:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: microservices
```

Create the namespace:

```bash
kubectl apply -f kubernetes/namespace/namespace.yaml
```

Verify:

```bash
kubectl get namespaces
```

Expected result:

```text
NAME           STATUS
microservices  Active
```

---

## 6. Kubernetes Deployment

Each microservice is deployed using a Kubernetes Deployment.

A Deployment manages:

- Pod creation
- Replica management
- Rolling updates
- Container configuration
- Image version updates
- Desired application state

Example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: adservice
  namespace: microservices
spec:
  replicas: 1
  selector:
    matchLabels:
      app: adservice
  template:
    metadata:
      labels:
        app: adservice
    spec:
      containers:
        - name: adservice
          image: 264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:latest
          ports:
            - containerPort: 9555
```

The image reference points to the corresponding Amazon ECR repository.

---

## 7. Container Image Management

The application containers are stored in Amazon ECR.

The Kubernetes Deployment references the ECR image.

Example:

```text
264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:<TAG>
```

The image tag is updated by the CI pipeline whenever a new image is built and pushed.

Example:

```text
adservice:1
adservice:2
adservice:3
```

This allows Kubernetes to deploy a specific application version.

---

## 8. Kubernetes Service

A Kubernetes Service provides stable network access to application Pods.

Example:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: adservice
  namespace: microservices
spec:
  selector:
    app: adservice
  ports:
    - protocol: TCP
      port: 9555
      targetPort: 9555
```

The Service selects Pods using the matching label:

```text
app: adservice
```

---

## 9. Service Types

The project uses Kubernetes Service types according to the application requirement.

### ClusterIP

Internal microservices can use:

```yaml
type: ClusterIP
```

This makes the service accessible only from within the Kubernetes cluster.

Example:

```text
frontend
   |
   +--> cartservice
   |
   +--> productcatalogservice
   |
   +--> paymentservice
```

Internal services do not need public exposure.

### LoadBalancer

The frontend application can be exposed externally using:

```yaml
type: LoadBalancer
```

AWS creates an external load balancer for the Kubernetes Service.

Example:

```text
Internet
   |
   v
AWS Load Balancer
   |
   v
Kubernetes Service
   |
   v
Frontend Pods
```

---

## 10. Apply Kubernetes Manifests

After connecting to the EKS cluster, verify the current context:

```bash
kubectl config current-context
```

Verify cluster connectivity:

```bash
kubectl get nodes
```

Expected result:

```text
NAME                          STATUS   ROLES
ip-10-0-x-x.compute.internal  Ready    <none>
```

Create the namespace:

```bash
kubectl apply -f kubernetes/namespace/
```

Deploy the application:

```bash
kubectl apply -f kubernetes/deployments/
```

Apply the services:

```bash
kubectl apply -f kubernetes/services/
```

---

## 11. Verify Deployments

Check all Deployments:

```bash
kubectl get deployments -n microservices
```

Example:

```text
NAME                    READY   UP-TO-DATE   AVAILABLE
adservice               1/1     1            1
cartservice             1/1     1            1
checkoutservice         1/1     1            1
currencyservice         1/1     1            1
frontend                1/1     1            1
paymentservice          1/1     1            1
productcatalogservice   1/1     1            1
```

---

## 12. Verify Pods

Run:

```bash
kubectl get pods -n microservices
```

Expected status:

```text
NAME                                    READY   STATUS
adservice-xxxxxxxxxx-xxxxx              1/1     Running
cartservice-xxxxxxxxxx-xxxxx            1/1     Running
frontend-xxxxxxxxxx-xxxxx               1/1     Running
```

All application Pods should eventually reach:

```text
STATUS = Running
```

---

## 13. Verify Services

Run:

```bash
kubectl get svc -n microservices
```

Example:

```text
NAME                    TYPE           CLUSTER-IP      EXTERNAL-IP
adservice               ClusterIP      10.x.x.x        <none>
cartservice             ClusterIP      10.x.x.x        <none>
frontend                LoadBalancer   10.x.x.x        <AWS-DNS>
```

The frontend LoadBalancer should receive an AWS-provided DNS endpoint.

---

## 14. Verify Pod Logs

For troubleshooting:

```bash
kubectl logs <pod-name> -n microservices
```

Example:

```bash
kubectl logs deployment/adservice -n microservices
```

For live logs:

```bash
kubectl logs -f deployment/adservice -n microservices
```

---

## 15. Describe Kubernetes Resources

If a Pod is not starting correctly:

```bash
kubectl describe pod <pod-name> -n microservices
```

For Deployment troubleshooting:

```bash
kubectl describe deployment adservice -n microservices
```

For Service troubleshooting:

```bash
kubectl describe svc frontend -n microservices
```

---

## 16. Common Pod States

### Running

```text
STATUS: Running
```

The container is running successfully.

### Pending

```text
STATUS: Pending
```

Possible causes include:

- Insufficient cluster capacity
- Scheduling constraints
- Missing resources
- Networking problems

Check:

```bash
kubectl describe pod <pod-name> -n microservices
```

### CrashLoopBackOff

The container repeatedly starts and exits.

Check:

```bash
kubectl logs <pod-name> -n microservices
```

### ImagePullBackOff

Kubernetes cannot pull the container image.

Check:

```bash
kubectl describe pod <pod-name> -n microservices
```

Possible causes:

- Incorrect ECR repository
- Incorrect image tag
- ECR authentication issue
- IAM permissions
- Incorrect image name

---

## 17. ECR Image Pull Permissions

Because application images are stored in Amazon ECR, the EKS worker nodes require appropriate permissions to pull images.

The required permissions should allow the nodes to authenticate to ECR and retrieve container images.

Typical ECR read operations include:

```text
ecr:GetAuthorizationToken
ecr:BatchCheckLayerAvailability
ecr:GetDownloadUrlForLayer
ecr:BatchGetImage
```

The exact IAM configuration should match the Terraform implementation used for the EKS worker nodes.

---

## 18. Rolling Updates

When a Deployment references a new image tag, Kubernetes can perform a rolling update.

Example:

```bash
kubectl set image deployment/adservice \
  adservice=264991295389.dkr.ecr.us-east-1.amazonaws.com/adservice:2 \
  -n microservices
```

Monitor the rollout:

```bash
kubectl rollout status deployment/adservice -n microservices
```

Check rollout history:

```bash
kubectl rollout history deployment/adservice -n microservices
```

---

## 19. Rollback

If a deployment fails, the previous version can be restored:

```bash
kubectl rollout undo deployment/adservice -n microservices
```

Verify:

```bash
kubectl rollout status deployment/adservice -n microservices
```

This provides a basic rollback mechanism before GitOps reconciliation is considered.

---

## 20. Frontend Accessibility

After the frontend Service is exposed through an AWS LoadBalancer:

```bash
kubectl get svc frontend -n microservices
```

Retrieve the external endpoint:

```bash
kubectl get svc frontend \
  -n microservices \
  -o wide
```

The application can then be accessed through the LoadBalancer endpoint.

The external DNS name can later be integrated with Route 53.

---

## 21. Kubernetes Validation Checklist

Run the following commands:

```bash
kubectl get nodes

kubectl get namespaces

kubectl get deployments -n microservices

kubectl get pods -n microservices

kubectl get svc -n microservices

kubectl get endpoints -n microservices

kubectl get events -n microservices --sort-by=.lastTimestamp
```

Expected state:

```text
EKS Cluster        -> Accessible
Nodes              -> Ready
Namespace          -> Active
Deployments        -> Available
Pods               -> Running
Services           -> Created
Frontend           -> Externally Accessible
```

---

## 22. Evidence to Capture

The following screenshots or command outputs should be stored under:

```text
evidence/07-kubernetes/
```

Recommended evidence:

```text
01-kubectl-get-nodes.png
02-kubectl-get-namespaces.png
03-kubectl-get-deployments.png
04-kubectl-get-pods.png
05-kubectl-get-services.png
06-frontend-loadbalancer.png
07-pod-logs.png
08-deployment-details.png
09-service-details.png
10-application-ui.png
```

These demonstrate that the Kubernetes workloads were successfully deployed and exposed.

---

## 23. Security Considerations

The Kubernetes implementation should follow the principle of least privilege.

Recommended practices:

- Keep internal services as ClusterIP where possible.
- Expose only required frontend services.
- Avoid hardcoding credentials in Kubernetes manifests.
- Store sensitive configuration in Kubernetes Secrets or an appropriate secret-management solution.
- Use immutable image tags instead of relying exclusively on latest.
- Restrict Kubernetes RBAC permissions.
- Use namespaces for workload isolation.
- Keep container images scanned before deployment.
- Avoid running containers with unnecessary privileges.

---

## 24. Integration With CI/CD

The Kubernetes deployment is integrated with the CI/CD workflow.

The overall flow is:

```text
Developer
   |
   v
GitHub
   |
   v
Jenkins
   |
   +--> Build Docker Image
   |
   +--> Security Checks
   |
   +--> Push Image to ECR
   |
   +--> Update Kubernetes Manifest
   |
   v
Git Repository
   |
   v
Argo CD
   |
   v
Amazon EKS
   |
   v
Kubernetes Deployment
   |
   v
Application Pods
```

The CI pipeline builds and publishes application images, while the Kubernetes manifests define how those images are deployed.

---

## 25. GitOps Preparation

The Kubernetes manifests created in this phase become the desired state consumed by Argo CD.

The workflow is:

```text
Docker Image
     |
     v
Amazon ECR
     |
     v
Kubernetes Manifest
     |
     v
Git Repository
     |
     v
Argo CD
     |
     v
Amazon EKS
```

Argo CD continuously compares the desired state stored in Git with the actual state of the Kubernetes cluster.

The Argo CD implementation is documented separately in:

```text
docs/08-argocd-gitops/
```

---

## 26. Final Validation

The Kubernetes phase is considered complete when:

- EKS nodes are in Ready state.
- The application namespace exists.
- Kubernetes Deployments are available.
- Application Pods are running.
- Kubernetes Services are created.
- Internal services are reachable within the cluster.
- The frontend service receives an external endpoint.
- The application is accessible through the frontend endpoint.
- Container images are successfully pulled from ECR.
- Kubernetes manifests are stored in Git.
- The manifests are ready for Argo CD synchronization.

---

## 27. Phase Completion

At the end of this phase, the microservices application is running on Amazon EKS using Kubernetes Deployments and Services.

The resulting platform provides the Kubernetes runtime layer required for the next phase:

```text
Kubernetes
    |
    v
Argo CD GitOps
    |
    v
Automated Deployment
```

The next phase covers:

**Phase 08 — Argo CD GitOps Deployment**