# Phase 10 — Monitoring

## Overview

This phase implements monitoring for the AWS microservices DevSecOps platform.

The objective is to provide visibility into the health, availability, and resource utilization of the Kubernetes workloads running on Amazon EKS.

The monitoring layer is designed around:

- Prometheus — Metrics collection and monitoring
- Grafana — Metrics visualization and dashboards
- Kubernetes — Application and infrastructure metrics
- Amazon EKS — Kubernetes control plane and worker infrastructure
- Alertmanager — Alert routing and notification management

This phase focuses on monitoring and observability.

Alerting configuration is documented separately in:

```text
docs/11-alerting/
```

---

## 1. Objectives

The main objectives of this phase are:

- Deploy Prometheus in the Kubernetes cluster.
- Deploy Grafana for metrics visualization.
- Configure Prometheus to discover Kubernetes workloads.
- Collect Kubernetes and application metrics.
- Create monitoring dashboards.
- Verify that metrics are being collected.
- Validate Grafana connectivity with Prometheus.
- Verify application and infrastructure visibility.
- Capture monitoring implementation evidence.

---

## 2. Monitoring Architecture

```text
                         Users
                           |
                           v
                  +----------------+
                  | Application    |
                  | Microservices  |
                  +-------+--------+
                          |
                          | Metrics
                          v
                  +----------------+
                  |   Prometheus   |
                  | Metrics Server |
                  +-------+--------+
                          |
                          | PromQL
                          v
                  +----------------+
                  |    Grafana     |
                  | Dashboards     |
                  +----------------+
                          |
                          v
                     Monitoring
                      Visibility
```

The Kubernetes environment provides the application runtime platform.

Prometheus collects metrics from the Kubernetes environment and monitored workloads.

Grafana queries Prometheus and provides dashboards for operational visibility.

---

## 3. Prerequisites

Before starting this phase, verify that the following components are available:

- AWS account
- Amazon EKS cluster
- Kubernetes worker nodes
- kubectl configured
- Kubernetes workloads deployed
- Application services running
- Helm installed if Helm is used for monitoring deployment
- Sufficient cluster resources

Verify the Kubernetes connection:

```bash
kubectl get nodes
```

Expected result:

```text
NAME                         STATUS   ROLES    AGE
<worker-node>                Ready    <none>   ...
```

Verify namespaces:

```bash
kubectl get namespaces
```

---

## 4. Monitoring Namespace

Create a dedicated namespace for monitoring components.

```bash
kubectl create namespace monitoring
```

Verify:

```bash
kubectl get namespace monitoring
```

Expected:

```text
NAME          STATUS
monitoring    Active
```

If the namespace already exists, the command may return an `AlreadyExists` message.

That is not an issue.

---

## 5. Prometheus

### 5.1 Purpose

Prometheus is responsible for collecting and storing time-series metrics.

It can collect metrics related to:

- Kubernetes nodes
- Kubernetes pods
- Kubernetes services
- Container resources
- Application workloads
- CPU utilization
- Memory utilization
- Network metrics
- Request metrics where applications expose them

---

## 6. Install Prometheus

If Prometheus is installed using Helm, first add the Prometheus community repository:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

Update Helm repositories:

```bash
helm repo update
```

Install the monitoring stack:

```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

Verify Helm releases:

```bash
helm list -n monitoring
```

---

## 7. Verify Prometheus Components

Check the monitoring pods:

```bash
kubectl get pods -n monitoring
```

The deployment should contain monitoring components such as:

```text
prometheus
grafana
alertmanager
node-exporter
kube-state-metrics
```

Pod names may vary depending on the Helm chart version.

Check all monitoring resources:

```bash
kubectl get all -n monitoring
```

---

## 8. Verify Prometheus

Check Prometheus services:

```bash
kubectl get svc -n monitoring
```

Example:

```text
NAME                                    TYPE        CLUSTER-IP
prometheus-operated                     ClusterIP  10.x.x.x
prometheus-kube-prometheus-prometheus    ClusterIP  10.x.x.x
```

The exact service names may differ.

Identify the Prometheus service:

```bash
kubectl get svc -n monitoring | grep prometheus
```

---

## 9. Access Prometheus

If Prometheus is exposed internally, use port forwarding:

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

Open:

```text
http://localhost:9090
```

Verify that the Prometheus UI loads.

---

## 10. Verify Prometheus Targets

Open the Prometheus UI.

Navigate to:

```text
Status
    |
    +-- Targets
```

Prometheus should show discovered monitoring targets.

Targets may include:

- kube-state-metrics
- node-exporter
- kubelet
- kubernetes-api
- prometheus

The exact target list depends on the installed monitoring configuration.

Healthy targets should report:

```text
UP
```

---

## 11. Prometheus Queries

Prometheus uses PromQL for querying metrics.

Example query:

```promql
up
```

This verifies whether monitored targets are available.

Node-related query:

```promql
node_uname_info
```

Memory-related query:

```promql
node_memory_MemAvailable_bytes
```

CPU-related query:

```promql
rate(node_cpu_seconds_total[5m])
```

The exact available metrics depend on the exporters and workloads deployed in the cluster.

---

## 12. Grafana

### 12.1 Purpose

Grafana provides a visualization layer for Prometheus metrics.

It allows operators to monitor:

- Kubernetes cluster health
- Node utilization
- Pod utilization
- CPU
- Memory
- Network traffic
- Application metrics
- Resource consumption

---

## 13. Verify Grafana

Check the Grafana service:

```bash
kubectl get svc -n monitoring | grep grafana
```

Check Grafana pod:

```bash
kubectl get pods -n monitoring | grep grafana
```

Expected status:

```text
Running
```

---

## 14. Access Grafana

For a local administrative session, port forwarding can be used:

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Open:

```text
http://localhost:3000
```

The Grafana login page should appear.

The actual service name may vary depending on the Helm release name.

Use:

```bash
kubectl get svc -n monitoring
```

to identify the correct service.

---

## 15. Configure Prometheus as Grafana Data Source

Grafana should use Prometheus as its primary metrics data source.

Navigate to:

```text
Grafana
    |
    +-- Connections
          |
          +-- Data Sources
                |
                +-- Prometheus
```

Configure the Prometheus endpoint according to the Kubernetes service created by the monitoring stack.

Example internal endpoint:

```text
http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090
```

The exact service name should be obtained using:

```bash
kubectl get svc -n monitoring
```

Click:

```text
Save & Test
```

Expected result:

```text
Data source is working
```

---

## 16. Grafana Dashboards

Grafana dashboards provide visual representation of Prometheus metrics.

Useful dashboards include:

- Kubernetes Cluster
- Kubernetes Nodes
- Kubernetes Pods
- Kubernetes Workloads
- Node Exporter
- Container Resources

Dashboards should provide visibility into:

- CPU utilization
- Memory utilization
- Pod count
- Node count
- Pod restarts
- Network traffic
- Resource requests
- Resource limits
- Application availability

---

## 17. Kubernetes Monitoring

Check node health:

```bash
kubectl get nodes
```

Check resource utilization:

```bash
kubectl top nodes
```

Check pod utilization:

```bash
kubectl top pods -A
```

If `kubectl top` is unavailable, verify that the cluster has a metrics-server or another supported resource metrics implementation.

---

## 18. Monitor Application Pods

List application pods:

```bash
kubectl get pods -A
```

Inspect a specific application:

```bash
kubectl get pods -n <namespace>
```

Check pod details:

```bash
kubectl describe pod <pod-name> -n <namespace>
```

Check pod logs:

```bash
kubectl logs <pod-name> -n <namespace>
```

Check restart counts:

```bash
kubectl get pods -n <namespace>
```

Monitor the application from Grafana using the corresponding Kubernetes workload dashboards.

---

## 19. Monitor Kubernetes Nodes

List nodes:

```bash
kubectl get nodes
```

Check node details:

```bash
kubectl describe node <node-name>
```

Check resource usage:

```bash
kubectl top nodes
```

Important metrics include:

- CPU
- Memory
- Disk
- Network
- Pod capacity
- Node availability

---

## 20. Monitor Kubernetes Workloads

Check deployments:

```bash
kubectl get deployments -A
```

Check ReplicaSets:

```bash
kubectl get replicasets -A
```

Check pods:

```bash
kubectl get pods -A
```

Check services:

```bash
kubectl get services -A
```

These resources provide the foundation for application-level monitoring.

---

## 21. Monitoring Health Checks

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

Verify node exporter:

```bash
kubectl get pods -n monitoring | grep node-exporter
```

Verify kube-state-metrics:

```bash
kubectl get pods -n monitoring | grep kube-state-metrics
```

---

## 22. Monitoring Validation

The monitoring implementation should satisfy the following validation points.

### Prometheus

- Prometheus pod is running.
- Prometheus service is available.
- Prometheus UI is accessible.
- Prometheus targets are discovered.
- Targets report healthy status.
- PromQL queries return metrics.

### Grafana

- Grafana pod is running.
- Grafana UI is accessible.
- Prometheus is configured as a data source.
- Grafana can query Prometheus.
- Kubernetes dashboards display metrics.

### Kubernetes

- Nodes are visible.
- Pods are visible.
- Workloads are visible.
- CPU metrics are available.
- Memory metrics are available.
- Pod health can be monitored.

---

## 23. Monitoring Flow

The complete monitoring flow is:

```text
Kubernetes Cluster
       |
       +-------------------+
       |                   |
       v                   v
 Kubernetes             Node
 Workloads             Metrics
       |                   |
       +---------+---------+
                 |
                 v
            Prometheus
                 |
                 | PromQL
                 v
              Grafana
                 |
                 v
          Monitoring UI
```

---

## 24. Monitoring Evidence

Store implementation evidence under:

```text
evidence/10-monitoring/
```

Recommended evidence:

```text
01-monitoring-namespace.png
02-prometheus-pods.png
03-grafana-pods.png
04-monitoring-services.png
05-prometheus-targets.png
06-prometheus-query.png
07-grafana-login.png
08-grafana-datasource.png
09-grafana-kubernetes-dashboard.png
10-kubernetes-node-metrics.png
11-kubernetes-pod-metrics.png
12-monitoring-overview.png
```

Evidence should demonstrate:

- Monitoring namespace.
- Prometheus deployment.
- Grafana deployment.
- Monitoring services.
- Prometheus targets.
- PromQL query execution.
- Grafana availability.
- Prometheus data source configuration.
- Kubernetes dashboard.
- Node metrics.
- Pod metrics.
- Overall monitoring visibility.

Do not capture or commit passwords, tokens, credentials, or other secrets in screenshots.

---

## 25. Troubleshooting

### Prometheus pod is not running

Check:

```bash
kubectl get pods -n monitoring
```

Then:

```bash
kubectl describe pod <prometheus-pod> -n monitoring
```

Check logs:

```bash
kubectl logs <prometheus-pod> -n monitoring
```

### Grafana cannot connect to Prometheus

Check Prometheus service:

```bash
kubectl get svc -n monitoring | grep prometheus
```

Verify DNS/service connectivity from inside the cluster.

Confirm that the Grafana data source points to the correct Prometheus service.

### Prometheus targets are DOWN

Open:

```text
Prometheus
    |
    +-- Status
          |
          +-- Targets
```

Identify the failed target.

Then inspect the corresponding Kubernetes component:

```bash
kubectl get pods -n monitoring
```

Check logs:

```bash
kubectl logs <pod-name> -n monitoring
```

### No CPU or memory metrics

Check:

```bash
kubectl top nodes
```

and:

```bash
kubectl top pods -A
```

If metrics are unavailable, verify the metrics-server or equivalent resource metrics implementation.

### Grafana dashboard has no data

First verify Prometheus:

```promql
up
```

If Prometheus returns metrics but Grafana shows no data:

- Verify the Grafana Prometheus data source.
- Verify the Prometheus endpoint.
- Check the selected dashboard.
- Check the dashboard time range.
- Verify the PromQL queries.

---

## 26. Operational Monitoring

The monitoring platform should be used to observe the application continuously.

Recommended operational checks include:

- Cluster health
- Node availability
- Pod availability
- CPU utilization
- Memory utilization
- Pod restarts
- Application availability
- Resource consumption
- Monitoring component health

Monitoring should be reviewed before troubleshooting application or infrastructure problems.

---

## 27. Security Considerations

Monitoring endpoints should not be exposed publicly without appropriate security controls.

Recommended controls include:

- Restrict administrative interfaces.
- Use authentication for Grafana.
- Avoid exposing Prometheus publicly.
- Avoid exposing Alertmanager publicly.
- Protect Grafana credentials.
- Do not commit credentials to Git.
- Use Kubernetes Secrets where appropriate.
- Use IAM and AWS security controls for AWS resources.

---

## 28. Relationship With Alerting

Monitoring provides the metrics and visibility layer.

Alerting uses those metrics to identify abnormal conditions.

The conceptual flow is:

```text
Kubernetes
    |
    v
Prometheus
    |
    +-----------> Grafana
    |                |
    |                v
    |           Visualization
    |
    v
Alertmanager
    |
    v
Notifications
```

Alert rules and notification configuration are documented in:

```text
docs/11-alerting/
```

---

## 29. Phase Validation Checklist

| Component | Validation | Status |
|---|---|---|
| Monitoring namespace | Created | Completed / Pending |
| Prometheus | Running | Completed / Pending |
| Prometheus targets | Healthy | Completed / Pending |
| PromQL | Metrics returned | Completed / Pending |
| Grafana | Running | Completed / Pending |
| Prometheus datasource | Connected | Completed / Pending |
| Kubernetes dashboards | Visible | Completed / Pending |
| Node metrics | Available | Completed / Pending |
| Pod metrics | Available | Completed / Pending |
| Monitoring evidence | Captured | Completed / Pending |

---

## 30. Phase Outcome

At the end of this phase, the AWS microservices platform has a centralized monitoring layer.

The completed monitoring architecture provides:

```text
Amazon EKS
     |
     +-------------------------+
     |                         |
     v                         v
Kubernetes Metrics       Node Metrics
     |                         |
     +------------+------------+
                  |
                  v
             Prometheus
                  |
          +-------+-------+
          |               |
          v               v
       Grafana        Alertmanager
          |               |
          v               v
     Visualization    Alerting
```

Prometheus provides metrics collection and querying.

Grafana provides visualization and operational dashboards.

The monitoring foundation is now ready for the alerting implementation in Phase 11.

---

# Phase 10 Completed

Monitoring is considered complete when:

- Prometheus is deployed.
- Prometheus targets are healthy.
- Metrics can be queried.
- Grafana is deployed.
- Grafana is connected to Prometheus.
- Kubernetes metrics are visible.
- Application and infrastructure health can be observed.
- Monitoring evidence is stored under:

```text
evidence/10-monitoring/
```

The next phase is:

**Phase 11 — Alerting**