1. Objectives

The main objectives of this phase are:

Deploy Prometheus in the Kubernetes cluster.
Deploy Grafana for metrics visualization.
Configure Prometheus to discover Kubernetes workloads.
Collect Kubernetes and application metrics.
Create monitoring dashboards.
Verify that metrics are being collected.
Validate Grafana connectivity with Prometheus.
Verify application and infrastructure visibility.
Capture monitoring implementation evidence.
2. Monitoring Architecture
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

The Kubernetes environment provides the application runtime platform.

Prometheus collects metrics from the Kubernetes environment and monitored workloads.

Grafana queries Prometheus and provides dashboards for operational visibility.

3. Prerequisites

Before starting this phase, verify that the following components are available:

AWS account
Amazon EKS cluster
Kubernetes worker nodes
kubectl configured
Kubernetes workloads deployed
Application services running
Helm installed if Helm is used for monitoring deployment
Sufficient cluster resources

Verify the Kubernetes connection:

kubectl get nodes

Expected result:

NAME                         STATUS   ROLES    AGE
<worker-node>                Ready    <none>   ...

Verify namespaces:

kubectl get namespaces
4. Monitoring Namespace

Create a dedicated namespace for monitoring components.

kubectl create namespace monitoring

Verify:

kubectl get namespace monitoring

Expected:

NAME          STATUS
monitoring    Active

If the namespace already exists, the command may return an AlreadyExists message.

That is not an issue.

5. Prometheus
5.1 Purpose

Prometheus is responsible for collecting and storing time-series metrics.

It can collect metrics related to:

Kubernetes nodes
Kubernetes pods
Kubernetes services
Container resources
Application workloads
CPU utilization
Memory utilization
Network metrics
Request metrics where applications expose them
6. Install Prometheus

If Prometheus is installed using Helm, first add the Prometheus community repository:

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

Update Helm repositories:

helm repo update

Install the monitoring stack:

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

Verify Helm releases:

helm list -n monitoring
7. Verify Prometheus Components

Check the monitoring pods:

kubectl get pods -n monitoring

The deployment should contain monitoring components such as:

prometheus
grafana
alertmanager
node-exporter
kube-state-metrics

Pod names may vary depending on the Helm chart version.

Check all monitoring resources:

kubectl get all -n monitoring
8. Verify Prometheus

Check Prometheus services:

kubectl get svc -n monitoring

Example:

NAME                                    TYPE        CLUSTER-IP
prometheus-operated                     ClusterIP  10.x.x.x
prometheus-kube-prometheus-prometheus    ClusterIP  10.x.x.x

The exact service names may differ.

Identify the Prometheus service:

kubectl get svc -n monitoring | grep prometheus
9. Access Prometheus

If Prometheus is exposed internally, use port forwarding:

kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

Open:

http://localhost:9090

Verify that the Prometheus UI loads.

10. Verify Prometheus Targets

Open the Prometheus UI.

Navigate to:

Status
    |
    +-- Targets

Prometheus should show discovered monitoring targets.

Targets may include:

kube-state-metrics
node-exporter
kubelet
kubernetes-api
prometheus

The exact target list depends on the installed monitoring configuration.

Healthy targets should report:

UP
11. Prometheus Queries

Prometheus uses PromQL for querying metrics.

Example query:

up

This verifies whether monitored targets are available.

Node-related query:

node_uname_info

Memory-related query:

node_memory_MemAvailable_bytes

CPU-related query:

rate(node_cpu_seconds_total[5m])

The exact available metrics depend on the exporters and workloads deployed in the cluster.

12. Grafana
12.1 Purpose

Grafana provides a visualization layer for Prometheus metrics.

It allows operators to monitor:

Kubernetes cluster health
Node utilization
Pod utilization
CPU
Memory
Network traffic
Application metrics
Resource consumption
13. Verify Grafana

Check the Grafana service:

kubectl get svc -n monitoring | grep grafana

Check Grafana pod:

kubectl get pods -n monitoring | grep grafana

Expected status:

Running
14. Access Grafana

For a local administrative session, port forwarding can be used:

kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

Open:

http://localhost:3000

The Grafana login page should appear.

The actual service name may vary depending on the Helm release name.

Use:

kubectl get svc -n monitoring

to identify the correct service.

15. Configure Prometheus as Grafana Data Source

Grafana should use Prometheus as its primary metrics data source.

Navigate to:

Grafana
    |
    +-- Connections
          |
          +-- Data Sources
                |
                +-- Prometheus

Configure the Prometheus endpoint according to the Kubernetes service created by the monitoring stack.

Example internal endpoint:

http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090

The exact service name should be obtained using:

kubectl get svc -n monitoring

Click:

Save & Test

Expected result:

Data source is working
16. Grafana Dashboards

Grafana dashboards provide visual representation of Prometheus metrics.

Useful dashboards include:

Kubernetes Cluster
Kubernetes Nodes
Kubernetes Pods
Kubernetes Workloads
Node Exporter
Container Resources

Dashboards should provide visibility into:

CPU utilization
Memory utilization
Pod count
Node count
Pod restarts
Network traffic
Resource requests
Resource limits
Application availability
17. Kubernetes Monitoring

Check node health:

kubectl get nodes

Check resource utilization:

kubectl top nodes

Check pod utilization:

kubectl top pods -A

If kubectl top is unavailable, verify that the cluster has a metrics-server or another supported resource metrics implementation.

18. Monitor Application Pods

List application pods:

kubectl get pods -A

Inspect a specific application:

kubectl get pods -n <namespace>

Check pod details:

kubectl describe pod <pod-name> -n <namespace>

Check pod logs:

kubectl logs <pod-name> -n <namespace>

Check restart counts:

kubectl get pods -n <namespace>

Monitor the application from Grafana using the corresponding Kubernetes workload dashboards.

19. Monitor Kubernetes Nodes

List nodes:

kubectl get nodes

Check node details:

kubectl describe node <node-name>

Check resource usage:

kubectl top nodes

Important metrics include:

CPU
Memory
Disk
Network
Pod capacity
Node availability
20. Monitor Kubernetes Workloads

Check deployments:

kubectl get deployments -A

Check ReplicaSets:

kubectl get replicasets -A

Check pods:

kubectl get pods -A

Check services:

kubectl get services -A

These resources provide the foundation for application-level monitoring.

21. Monitoring Health Checks

Verify Prometheus:

kubectl get pods -n monitoring | grep prometheus

Verify Grafana:

kubectl get pods -n monitoring | grep grafana

Verify Alertmanager:

kubectl get pods -n monitoring | grep alertmanager

Verify node exporter:

kubectl get pods -n monitoring | grep node-exporter

Verify kube-state-metrics:

kubectl get pods -n monitoring | grep kube-state-metrics
22. Monitoring Validation

The monitoring implementation should satisfy the following validation points.

Prometheus
Prometheus pod is running.
Prometheus service is available.
Prometheus UI is accessible.
Prometheus targets are discovered.
Targets report healthy status.
PromQL queries return metrics.
Grafana
Grafana pod is running.
Grafana UI is accessible.
Prometheus is configured as a data source.
Grafana can query Prometheus.
Kubernetes dashboards display metrics.
Kubernetes
Nodes are visible.
Pods are visible.
Workloads are visible.
CPU metrics are available.
Memory metrics are available.
Pod health can be monitored.
23. Monitoring Flow

The complete monitoring flow is:

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
24. Monitoring Evidence

Store implementation evidence under:

evidence/10-monitoring/

Recommended evidence:

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

Evidence should demonstrate:

Monitoring namespace.
Prometheus deployment.
Grafana deployment.
Monitoring services.
Prometheus targets.
PromQL query execution.
Grafana availability.
Prometheus data source configuration.
Kubernetes dashboard.
Node metrics.
Pod metrics.
Overall monitoring visibility.

Do not capture or commit passwords, tokens, credentials, or other secrets in screenshots.

25. Troubleshooting
Prometheus pod is not running

Check:

kubectl get pods -n monitoring

Then:

kubectl describe pod <prometheus-pod> -n monitoring

Check logs:

kubectl logs <prometheus-pod> -n monitoring
Grafana cannot connect to Prometheus

Check Prometheus service:

kubectl get svc -n monitoring | grep prometheus

Verify DNS/service connectivity from inside the cluster.

Confirm that the Grafana data source points to the correct Prometheus service.

Prometheus targets are DOWN

Open:

Prometheus
    |
    +-- Status
          |
          +-- Targets

Identify the failed target.

Then inspect the corresponding Kubernetes component:

kubectl get pods -n monitoring

Check logs:

kubectl logs <pod-name> -n monitoring
No CPU or memory metrics

Check:

kubectl top nodes

and:

kubectl top pods -A

If metrics are unavailable, verify the metrics-server or equivalent resource metrics implementation.

Grafana dashboard has no data

First verify Prometheus:

up

If Prometheus returns metrics but Grafana shows no data:

Verify the Grafana Prometheus data source.
Verify the Prometheus endpoint.
Check the selected dashboard.
Check the dashboard time range.
Verify the PromQL queries.
26. Operational Monitoring

The monitoring platform should be used to observe the application continuously.

Recommended operational checks include:

Cluster health
Node availability
Pod availability
CPU utilization
Memory utilization
Pod restarts
Application availability
Resource consumption
Monitoring component health

Monitoring should be reviewed before troubleshooting application or infrastructure problems.

27. Security Considerations

Monitoring endpoints should not be exposed publicly without appropriate security controls.

Recommended controls include:

Restrict administrative interfaces.
Use authentication for Grafana.
Avoid exposing Prometheus publicly.
Avoid exposing Alertmanager publicly.
Protect Grafana credentials.
Do not commit credentials to Git.
Use Kubernetes Secrets where appropriate.
Use IAM and AWS security controls for AWS resources.
28. Relationship With Alerting

Monitoring provides the metrics and visibility layer.

Alerting uses those metrics to identify abnormal conditions.

The conceptual flow is:

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

Alert rules and notification configuration are documented in:

docs/11-alerting/
29. Phase Validation Checklist
Component	Validation	Status
Monitoring namespace	Created	Completed / Pending
Prometheus	Running	Completed / Pending
Prometheus targets	Healthy	Completed / Pending
PromQL	Metrics returned	Completed / Pending
Grafana	Running	Completed / Pending
Prometheus datasource	Connected	Completed / Pending
Kubernetes dashboards	Visible	Completed / Pending
Node metrics	Available	Completed / Pending
Pod metrics	Available	Completed / Pending
Monitoring evidence	Captured	Completed / Pending
30. Phase Outcome

At the end of this phase, the AWS microservices platform has a centralized monitoring layer.

The completed monitoring architecture provides:

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

Prometheus provides metrics collection and querying.

Grafana provides visualization and operational dashboards.

The monitoring foundation is now ready for the alerting implementation in Phase 11.

Phase 10 Completed

Monitoring is considered complete when:

Prometheus is deployed.
Prometheus targets are healthy.
Metrics can be queried.
Grafana is deployed.
Grafana is connected to Prometheus.
Kubernetes metrics are visible.
Application and infrastructure health can be observed.
Monitoring evidence is stored under:
evidence/10-monitoring/

The next phase is:

Phase 11 — Alerting

Prometheus collects metrics from the Kubernetes environment.

Prometheus evaluates alert rules against those metrics.

When an alert condition is satisfied, Prometheus sends the alert to Alertmanager.

Alertmanager is responsible for grouping, routing, and managing alerts.

Grafana continues to provide visualization of the underlying metrics.

3. Prerequisites

Before starting this phase, verify that Phase 10 has been completed.

Required components:

Amazon EKS cluster
Kubernetes workloads
Prometheus
Grafana
Alertmanager
Prometheus metrics
kubectl
Helm if Helm was used for the monitoring deployment

Verify the cluster:

kubectl get nodes

Verify monitoring:

kubectl get pods -n monitoring

Verify Alertmanager:

kubectl get pods -n monitoring | grep alertmanager
4. Verify Alertmanager

Check all monitoring services:

kubectl get svc -n monitoring

Identify the Alertmanager service:

kubectl get svc -n monitoring | grep alertmanager

Check Alertmanager pods:

kubectl get pods -n monitoring | grep alertmanager

Expected status:

Running
5. Access Alertmanager

For local administrative access, use port forwarding.

First identify the Alertmanager service:

kubectl get svc -n monitoring | grep alertmanager

Then forward the service port.

Example:

kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093

Open:

http://localhost:9093

The Alertmanager UI should be accessible.

The exact service name may vary depending on the Helm release.

Use:

kubectl get svc -n monitoring

to identify the correct service.

6. Alertmanager Components

Alertmanager provides several important capabilities:

Alertmanager
    |
    +-- Alert grouping
    |
    +-- Alert routing
    |
    +-- Alert deduplication
    |
    +-- Alert inhibition
    |
    +-- Notification delivery

This prevents operators from receiving unnecessary duplicate notifications when multiple alerts originate from the same underlying problem.

7. Alert Rules

Alert rules define conditions that should generate alerts.

Typical Kubernetes alert conditions include:

Pod unavailable
Pod repeatedly restarting
Deployment replicas unavailable
Node unavailable
High CPU utilization
High memory utilization
Persistent volume capacity problems
Application availability problems
Monitoring component failures

Alert rules should be based on metrics collected by Prometheus.

8. Alert Rule Directory

Store alert rule configuration in the project repository under:

monitoring/alert-rules/

Recommended structure:

monitoring/
└── alert-rules/
    ├── README.md
    ├── kubernetes-alerts.yaml
    ├── node-alerts.yaml
    ├── pod-alerts.yaml
    └── application-alerts.yaml

The exact files can be adjusted according to the implementation.

9. Example Alert Rule

A basic Kubernetes pod availability rule can be represented as:

groups:
  - name: kubernetes-alerts
    rules:
      - alert: PodNotReady
        expr: kube_pod_status_ready{condition="false"} == 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Kubernetes pod is not ready"
          description: "A Kubernetes pod has remained in a non-ready state for more than 5 minutes."

The rule contains:

alert
expr
for
labels
annotations
10. Alert Rule Components
Alert Name

Example:

alert: PodNotReady

This identifies the alert.

Expression

Example:

expr: kube_pod_status_ready{condition="false"} == 1

The expression determines when the alert condition is true.

Duration

Example:

for: 5m

This prevents transient conditions from immediately generating alerts.

The condition must remain true for the specified duration.

Severity

Example:

labels:
  severity: warning

Severity labels can be used for routing and prioritization.

Typical levels include:

info
warning
critical
Annotations

Annotations provide human-readable information.

Example:

annotations:
  summary: "Kubernetes pod is not ready"
  description: "A Kubernetes pod has remained in a non-ready state for more than 5 minutes."
11. Pod Restart Alert

A pod restart condition can be monitored using Kubernetes container restart metrics.

Example:

groups:
  - name: pod-alerts
    rules:
      - alert: PodRestartingFrequently
        expr: increase(kube_pod_container_status_restarts_total[10m]) > 3
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Pod is restarting frequently"
          description: "A container has restarted multiple times during the last 10 minutes."

This can help identify:

Application crashes
Configuration problems
Resource exhaustion
Dependency failures
Container startup failures
12. Node Availability Alert

Node availability should be monitored to detect worker-node problems.

Example:

groups:
  - name: node-alerts
    rules:
      - alert: KubernetesNodeNotReady
        expr: kube_node_status_condition{condition="Ready",status="true"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Kubernetes node is not ready"
          description: "A Kubernetes worker node has remained in a non-ready state."

This type of alert is important because node failures can affect multiple workloads.

13. CPU Utilization Alert

CPU utilization can be monitored using node or container metrics.

Example concept:

groups:
  - name: resource-alerts
    rules:
      - alert: HighCPUUtilization
        expr: <cpu-utilization-expression>
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU utilization detected"
          description: "CPU utilization has remained above the configured threshold."

The exact PromQL expression should match the metrics exposed by the monitoring implementation.

Before adding an alert rule, verify the metric exists in Prometheus.

14. Memory Utilization Alert

Memory utilization can also be monitored.

Example concept:

groups:
  - name: resource-alerts
    rules:
      - alert: HighMemoryUtilization
        expr: <memory-utilization-expression>
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High memory utilization detected"
          description: "Memory utilization has remained above the configured threshold."

The expression should be validated against the actual Prometheus metrics available in the cluster.

15. Application Availability

Application availability should be monitored where application-specific metrics are available.

Possible indicators include:

Application endpoint availability
HTTP request failures
HTTP 5xx responses
Application latency
Pod availability
Deployment replica availability
Container restarts

Application-specific alert rules should be added only when the required metrics are available.

16. Deployment Availability

Deployment availability can be monitored using Kubernetes state metrics.

Example concept:

groups:
  - name: deployment-alerts
    rules:
      - alert: DeploymentReplicasUnavailable
        expr: <deployment-replica-expression>
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Deployment replicas are unavailable"
          description: "One or more expected application replicas are unavailable."

The exact expression should be validated against the metrics exposed by kube-state-metrics.

17. Configure Alert Rules

If using kube-prometheus-stack, alert rules can be managed using PrometheusRule resources.

Example:

apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: kubernetes-alert-rules
  namespace: monitoring
spec:
  groups:
    - name: kubernetes-alerts
      rules:
        - alert: PodNotReady
          expr: kube_pod_status_ready{condition="false"} == 1
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "Kubernetes pod is not ready"
            description: "A Kubernetes pod has remained in a non-ready state for more than 5 minutes."

Apply the rule:

kubectl apply -f monitoring/alert-rules/kubernetes-alerts.yaml
18. Verify PrometheusRule

List PrometheusRule resources:

kubectl get prometheusrule -n monitoring

Inspect a specific rule:

kubectl describe prometheusrule kubernetes-alert-rules -n monitoring

Verify the rule was accepted by the Prometheus Operator.

19. Verify Alert Rules in Prometheus

Open the Prometheus UI.

Navigate to:

Alerts

Prometheus should display configured alert rules.

You can also use the Prometheus API/UI to verify rule evaluation.

The alert should show a state such as:

Inactive
Pending
Firing
20. Alert States
Inactive

The alert condition is currently false.

Condition = false

No alert is generated.

Pending

The alert condition is true, but the configured for duration has not elapsed.

Condition = true
Timer = running
Firing

The condition has remained true for the configured duration.

Condition = true
Timer = completed

Prometheus sends the alert to Alertmanager.

21. Test Alert Generation

Alerting should be tested in a controlled environment.

One approach is to create a temporary test alert.

Example:

apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: test-alert
  namespace: monitoring
spec:
  groups:
    - name: test-alert
      rules:
        - alert: DevSecOpsTestAlert
          expr: vector(1)
          for: 1m
          labels:
            severity: warning
          annotations:
            summary: "DevSecOps test alert"
            description: "Temporary alert used to validate the monitoring and alerting pipeline."

Apply:

kubectl apply -f test-alert.yaml

After the configured duration, verify the alert in Prometheus.

After validation, remove the test alert:

kubectl delete prometheusrule test-alert -n monitoring

Do not leave temporary test alerts in the production configuration.

22. Alertmanager Verification

Check Alertmanager:

kubectl get pods -n monitoring | grep alertmanager

Check logs:

kubectl logs -n monitoring <alertmanager-pod>

Check the Alertmanager service:

kubectl get svc -n monitoring | grep alertmanager

Access the UI using port forwarding:

kubectl port-forward -n monitoring svc/<alertmanager-service> 9093:9093

Open:

http://localhost:9093
23. Alertmanager Routing

Alertmanager can route alerts based on labels.

For example:

severity=warning
severity=critical

A conceptual routing structure is:

Alertmanager
     |
     +---------------------+
     |                     |
     v                     v
 severity=warning    severity=critical
     |                     |
     v                     v
 Warning Channel      Critical Channel

This allows operational teams to prioritize critical infrastructure events.

24. Notification Configuration

Notification destinations depend on the implementation.

Possible destinations include:

Email
Slack
Microsoft Teams
PagerDuty
Webhook
Other supported notification systems

Notification credentials must not be committed to Git.

Use Kubernetes Secrets or an appropriate external secret-management mechanism.

25. Secret Management

Never store credentials directly in:

README files
YAML files
Jenkinsfiles
Git repositories
Screenshots

Sensitive values should be provided through secure mechanisms such as:

Kubernetes Secrets
AWS Secrets Manager
Jenkins Credentials
External Secrets
IAM-based authentication
26. Alert Severity Model

A simple severity model can be used:

INFO
 |
 +-- Informational condition

WARNING
 |
 +-- Potential operational issue

CRITICAL
 |
 +-- Immediate operational attention required

Example:

Pod restart spike       -> WARNING
High resource usage     -> WARNING
Node unavailable        -> CRITICAL
Application unavailable -> CRITICAL

The actual severity should be determined according to operational requirements.

27. Alert Deduplication

Alertmanager can group similar alerts.

For example, if several pods on the same node fail simultaneously, grouping can prevent a large number of individual notifications.

Conceptually:

Pod 1 Failure
Pod 2 Failure
Pod 3 Failure
Pod 4 Failure
       |
       v
 Alertmanager
       |
       v
Grouped Notification

This makes alerts easier to consume.

28. Alert Inhibition

Alertmanager can also suppress secondary alerts when a higher-level failure is already known.

Example:

Node failure
     |
     +--> Pod failures
     +--> Application failures
     +--> Resource failures

Instead of generating separate notifications for every dependent workload, a higher-priority node alert can be used to identify the root cause.

29. Alert Validation Commands

Check PrometheusRule resources:

kubectl get prometheusrule -n monitoring

Check monitoring pods:

kubectl get pods -n monitoring

Check Alertmanager:

kubectl get pods -n monitoring | grep alertmanager

Check services:

kubectl get svc -n monitoring

Check cluster nodes:

kubectl get nodes

Check workloads:

kubectl get pods -A
30. End-to-End Alert Flow

The expected alerting flow is:

Kubernetes Workload
        |
        v
     Metrics
        |
        v
   Prometheus
        |
        v
  Alert Rule
        |
        v
 Condition Met
        |
        v
  Alert = Firing
        |
        v
  Alertmanager
        |
        v
 Notification

This validates the complete alerting pipeline.

31. Alerting Evidence

Store implementation evidence under:

evidence/11-alerting/

Recommended evidence:

01-alertmanager-pods.png
02-alertmanager-service.png
03-prometheus-alert-rules.png
04-prometheus-alert-state.png
05-test-alert-firing.png
06-alertmanager-alert.png
07-alertmanager-routing.png
08-alert-notification.png
09-kubernetes-health-alert.png
10-node-alert.png
11-pod-restart-alert.png
12-alerting-overview.png

Evidence should demonstrate:

Alertmanager is running.
Prometheus alert rules exist.
Alert rules are evaluated.
A controlled test alert enters the firing state.
Alertmanager receives the alert.
Alert routing works.
Notification delivery works if configured.
Kubernetes infrastructure alerts can be generated.

Do not capture or commit:

Passwords
API tokens
Access keys
Webhook secrets
SMTP credentials
Kubernetes Secret values
32. Troubleshooting
Alertmanager pod is not running

Check:

kubectl get pods -n monitoring | grep alertmanager

Inspect:

kubectl describe pod <alertmanager-pod> -n monitoring

Check logs:

kubectl logs <alertmanager-pod> -n monitoring
Alert rule is not visible in Prometheus

Check:

kubectl get prometheusrule -n monitoring

Inspect:

kubectl describe prometheusrule <rule-name> -n monitoring

Check Prometheus Operator and Prometheus logs if the rule is not being discovered.

Alert remains inactive

Check:

The PromQL expression.
Whether the required metric exists.
The current metric value.
The configured threshold.
The for duration.
Prometheus target health.

Test the expression directly in Prometheus.

Alert remains pending

Check the configured:

for:

For example:

for: 5m

The condition must remain true for the full duration before the alert becomes firing.

Alert is firing but Alertmanager does not receive it

Verify:

kubectl get pods -n monitoring | grep alertmanager

Then check Alertmanager logs:

kubectl logs -n monitoring <alertmanager-pod>

Also verify Prometheus configuration and Alertmanager connectivity.

Alertmanager receives the alert but notification is not delivered

Check:

Alertmanager configuration.
Notification receiver.
Routing rules.
Credentials.
Network connectivity.
Notification provider status.

Never expose notification credentials in the repository.

33. Security Considerations

Alerting systems can contain operationally sensitive information.

Security controls should include:

Protect Alertmanager UI.
Protect Grafana UI.
Restrict Prometheus access.
Protect notification credentials.
Avoid public exposure of monitoring endpoints.
Use Kubernetes Secrets for sensitive configuration.
Use IAM-based authentication where appropriate.
Do not commit secrets to Git.
Limit access to monitoring namespaces.
34. Monitoring and Alerting Relationship

Phase 10 established monitoring.

Phase 11 builds alerting on top of those metrics.

Phase 10
Monitoring
    |
    v
Prometheus Metrics
    |
    v
Phase 11
Alert Rules
    |
    v
Alertmanager
    |
    v
Notifications

Monitoring answers:

"What is happening?"

Alerting answers:

"What requires attention?"
35. Phase Validation Checklist
Component	Validation	Status
Alertmanager	Running	Completed / Pending
PrometheusRule	Created	Completed / Pending
Alert rules	Visible in Prometheus	Completed / Pending
Alert evaluation	Working	Completed / Pending
Test alert	Fired successfully	Completed / Pending
Alertmanager	Received alert	Completed / Pending
Alert routing	Validated	Completed / Pending
Notification	Validated if configured	Completed / Pending
Kubernetes alert	Validated	Completed / Pending
Evidence	Captured	Completed / Pending
36. Phase Outcome

At the end of this phase, the platform has an alerting layer capable of detecting important operational conditions.

The completed architecture is:

                    AWS
                     |
                     v
                 Amazon EKS
                     |
          +----------+----------+
          |                     |
          v                     v
      Workloads              Nodes
          |                     |
          +----------+----------+
                     |
                     v
                 Prometheus
                     |
              Alert Evaluation
                     |
                     v
                Alertmanager
                     |
          +----------+----------+
          |                     |
          v                     v
      Alert Routing       Notifications

Prometheus evaluates infrastructure and workload conditions.

Alertmanager manages alert grouping, routing, and notification delivery.

This provides an operational alerting mechanism for the microservices platform.

37. Phase 11 Completed

Alerting is considered complete when:

Alertmanager is running.
Prometheus alert rules are configured.
Alert rules are visible in Prometheus.
Alert conditions can be evaluated.
A controlled test alert can enter the firing state.
Alertmanager receives the alert.
Alert routing works.
Notification delivery is validated where configured.
Alerting evidence is stored under:
evidence/11-alerting/

The next phase is:

Phase 12 — End-to-End Validation