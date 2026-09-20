# Kubernetes Monitoring Chart

Prometheus, Grafana and Alertmanager as one Helm chart, with alert rules that are worth waking up for.

`helm install` and you get cluster metrics, node health, pod restarts and alerting in about five minutes.

---

## Install

```bash
helm install monitoring ./charts/k8s-monitoring \
  --namespace monitoring --create-namespace \
  --set grafana.adminPassword=yourpassword
```

That's it. Prometheus discovers nodes and pods automatically, kube-state-metrics exposes object state, node-exporter covers the hosts, and the alert rules are loaded.

```bash
kubectl port-forward -n monitoring svc/monitoring-k8s-monitoring-grafana 3000:3000
```

---

## The alert that matters most

Most disk alerts fire at 90% or 95% full. By then you have minutes, and your options are bad ones.

```promql
predict_linear(node_filesystem_avail_bytes[1h], 4*3600) < 0
and node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.25
```

`predict_linear` fits a trend over the last hour and extrapolates four hours forward. If the projection crosses zero, the alert fires — while the disk is still at 70% and you have time to act calmly.

The second condition prevents noise: a disk at 80% free that briefly trends downward shouldn't page anyone. Both conditions have to hold.

This is the difference between an alert that informs you and an alert that gives you options.

---

## Alert rules included

| Group | Alerts |
|---|---|
| **node-health** | NodeNotReady, NodeMemoryPressure, NodeDiskPressure |
| **pod-health** | PodCrashLooping, PodNotReady, ContainerOOMKilled |
| **resource-pressure** | HighNodeCPU, HighNodeMemory, PodMemoryNearLimit |
| **disk-space** | DiskWillFillIn4Hours, DiskSpaceCritical |

Each group can be turned off:

```yaml
alerts:
  nodeHealth: true
  podHealth: true
  resourcePressure: true
  diskSpace: false
```

---

## PodMemoryNearLimit — catching OOMKills before they happen

```promql
container_memory_working_set_bytes
  / on(namespace,pod,container) kube_pod_container_resource_limits{resource="memory"} > 0.90
```

An OOMKilled container is a post-mortem. This alert fires at 90% of the limit, while the pod is still running and you can decide whether the limit is wrong or the application is leaking.

It requires the pod to actually have a memory limit set — which is a good reason to set them.

---

## Automatic pod discovery

Any pod becomes a scrape target by adding two annotations:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
```

No Prometheus config change, no redeploy. The relabel rules in the `kubernetes-pods` job pick it up on the next service discovery cycle.

This is the pattern that makes monitoring scale — application teams opt in from their own manifests rather than filing a ticket against the platform team.

---

## Persistence

Off by default. Prometheus writes to an `emptyDir`, which means metrics are lost when the pod restarts.

That's fine for a lab. For anything real:

```yaml
prometheus:
  persistence:
    enabled: true
    size: 50Gi
    storageClass: your-storage-class
  retention: 30d
```

Sizing rule of thumb: roughly 1–2 bytes per sample after compression. A cluster producing 10,000 samples per second at 30s intervals needs around 25GB for 30 days.

---

## Configuration reference

| Key | Default | Purpose |
|---|---|---|
| `prometheus.retention` | `15d` | How long metrics are kept |
| `prometheus.scrapeInterval` | `30s` | Sampling frequency |
| `prometheus.persistence.enabled` | `false` | Use a PVC instead of emptyDir |
| `grafana.adminPassword` | `changeme` | Override this |
| `grafana.anonymousAccess` | `false` | Read-only access without login |
| `alertmanager.receivers.slack.enabled` | `false` | Where alerts actually go |
| `alerts.*` | `true` | Enable or disable rule groups |

---

## Alertmanager receivers

Alerts fire and go nowhere by default. That's deliberate for a first install — you want to see what fires before you route it somewhere.

To route to Slack:

```yaml
alertmanager:
  receivers:
    slack:
      enabled: true
      webhookUrl: "https://hooks.slack.com/services/..."
      channel: "#alerts"
```

Put the webhook in a Kubernetes Secret rather than in values.yaml. A webhook URL in a Git repository is a credential leak.

---

## Author

**Mortadha Riahi** — Infrastructure & Platform Engineer

Red Hat Certified Specialist in Containers (EX188) · RHCE · RHCSA · AWS Solutions Architect

[LinkedIn](https://www.linkedin.com/in/mortadha-riahi/) · [AIOps](https://github.com/Mortadha1996/aiops-anomaly-detection) · [LLM platform](https://github.com/Mortadha1996/llm-inference-platform) · [AWS HA](https://github.com/Mortadha1996/aws-ha-architecture)

---

## Screenshot

Prometheus alert rules configured by the Helm chart.

![Prometheus Alert Rules](screenshots/prometheus-alert-rules.png)
