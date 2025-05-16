Example of CKA EXAMS Questions

---

### ✅ **1. List cert-manager CRDs and extract `subject` field from `Certificate` CRD**

📘 **Docs:**

- [CRDs - Kubernetes](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/)
- [cert-manager CRDs](https://cert-manager.io/docs/concepts/custom-resources/)

#### Step-by-Step:

**Command 1:**

```bash
kubectl get crds | grep cert-manager > crds.yaml
```

- `kubectl get crds`: Lists all CustomResourceDefinitions (these define custom K8s APIs).
- `grep cert-manager`: Filters only those related to cert-manager.
- `> crds.yaml`: Saves the output to a file.

**Command 2:tls**

```bash
kubectl get crd certificates.cert-manager.io \
  -o jsonpath='{.spec.versions[*].schema.openAPIV3Schema.properties.spec.properties.subject}' > subject.yaml
```

- This extracts the JSON schema of the `Certificate` CRD's `.spec.subject` field, which shows its internal structure (used by cert-manager to define TLS cert subjects).

---

### ✅ **2. Edit ConfigMap to enable TLSv1.2 and make it immutable**

📘 **Docs:**

- [Immutable ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-immutable)

#### Step-by-Step:

**ConfigMap YAML:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tls-config
immutable: true
data:
  TLS_MIN_VERSION: TLSv1.2
```

**Command:**

```bash
kubectl apply -f tls-cm.yaml
```

- `immutable: true` prevents changes later.
- If you need to change it, delete and recreate.

---

### ✅ **3. Install cri-dockerd `.deb` and set system params**

📘 **Docs:**

- [cri-dockerd GitHub](https://github.com/Mirantis/cri-dockerd)

#### Step-by-Step:

**Commands:**

```bash
sudo dpkg -i cri-dockerd_0.3.1.3-0.ubuntu-jammy_amd64.deb
```

**Enable and start service:**

```bash
sudo systemctl enable cri-docker.service
sudo systemctl start cri-docker.service
```

- This sets up `cri-dockerd`, which acts as a shim between K8s and Docker Engine.
- Needed because Docker runtime support was removed in K8s v1.24+.

---

### ✅ **4. Create Ingress for a Deployment**

📘 **Docs:**

- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

#### Ingress YAML Example:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: app.example.com  # You forgot this "host" part in interview
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

---

### ✅ **5. Gateway API Migration (Ingress ➝ Gateway + HTTPRoute)**

📘 **Docs:**

- [Gateway API Overview](https://gateway-api.sigs.k8s.io/)
- [HTTPRoute](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1beta1.HTTPRoute)

#### Step-by-Step:

1. **Create Gateway**
2. **Create HTTPRoute**
3. **Delete Ingress**

**Gateway Example:**

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: my-gateway
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    hostname: app.example.com
```

**HTTPRoute Example:**

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: my-route
spec:
  parentRefs:
  - name: my-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: my-service
      port: 80
```

**Delete old ingress:**

```bash
kubectl delete ingress my-ingress
```

---

### ✅ **6. Add Sidecar and Shared Volume**

📘 **Docs:**

- [Multi-container Pods](https://kubernetes.io/docs/concepts/workloads/pods/#multi-container-pods)
- [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)

#### Step-by-Step:

**Deployment Snippet:**

```yaml
volumes:
- name: shared-data
  emptyDir: {}

containers:
- name: main
  image: myapp
  volumeMounts:
  - name: shared-data
    mountPath: /app/shared

- name: sidecar
  image: alpine
  command: ["/bin/sh", "-c", "tail -f /dev/null"]
  volumeMounts:
  - name: shared-data
    mountPath: /sidecar/shared
```

---

### ✅ **7. PVC + Mount to Deployment**

📘 **Docs:**

- [PVC](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

**PVC YAML:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

**Deployment Volume Mount:**

```yaml
volumes:
- name: storage
  persistentVolumeClaim:
    claimName: data-pvc

containers:
- name: app
  image: myapp
  volumeMounts:
  - name: storage
    mountPath: /data
```

---

### ✅ **8. ArgoCD Install with Helm (No CRDs)**

📘 **Docs:**

- [ArgoCD Helm Chart](https://github.com/argoproj/argo-helm)

#### Step-by-Step:

Let’s break down **exactly** what these two Helm commands are doing, step by step, in a **real-world ArgoCD Helm install scenario**, using version `5.51.6` (latest as of early 2025) — and I’ll clearly explain why each flag matters.

---

## ✅ **1. `helm template` – Render Helm chart to static YAML**

### 🔧 Command:

```bash
helm template argocd argo/argo-cd \
  --version 5.51.6 \
  --namespace argocd \
  --skip-crds > argocd.yaml
```

### 🔍 What this does:

- `helm template`: Generates Kubernetes manifests **locally** from the Helm chart without installing them into the cluster.
- `argocd`: The **release name** (this is how the deployment will be identified).
- `argo/argo-cd`: The **chart name**, from the `argo` Helm repo (assumes you've run `helm repo add argo https://argoproj.github.io/argo-helm`).
- `--version 5.51.6`: Use a **specific stable version** of the chart — never rely on "latest" during production installs.
- `--namespace argocd`: All the rendered resources will be namespaced to `argocd`.
- `--skip-crds`: **Do not render CustomResourceDefinitions** in the output (useful when CRDs already exist or you want to manage them manually).
- `> argocd.yaml`: Output everything to a file. You can inspect or apply it manually with `kubectl apply -f argocd.yaml`.

### 💡 When to use:

- If you're doing GitOps or want to review changes in PRs before applying.
- If your cluster has CRDs already and you want to **avoid duplication** or conflict.

---

## ✅ **2. `helm install` – Actually deploy the chart**

### 🔧 Command:

```bash
helm install argocd argo/argo-cd \
  --version 5.51.6 \
  --namespace argocd \
  --create-namespace \
  --skip-crds
```

### 🔍 What this does:

- `helm install`: Installs the chart into the cluster.
- `argocd`: The release name (same as above).
- `argo/argo-cd`: The chart location (must have `helm repo add`ed it beforehand).
- `--version 5.51.6`: Lock to a specific chart version to avoid unexpected changes.
- `--namespace argocd`: Target namespace for the install.
- `--create-namespace`: Ensures the namespace exists (if not, it creates it).
- `--skip-crds`: Again, **do not install CRDs** (CRDs should usually be applied separately, especially if you're upgrading or in a shared cluster).

### 💡 Why `--skip-crds` is critical:

- ArgoCD Helm chart contains **CRDs** like `Application`, `AppProject`.
- Helm doesn’t manage CRDs well during upgrades or uninstall (they’re cluster-wide).
- Installing CRDs manually gives you full control and avoids damaging shared setups.

---

## ✅ TL;DR Summary

| Command                             | Purpose             | What Happens                                              |
| ----------------------------------- | ------------------- | --------------------------------------------------------- |
| `helm template ... > argocd.yaml` | Render YAML to file | No changes to cluster, for dry-run, review, GitOps        |
| `helm install ...`                | Install to cluster  | Actually deploys ArgoCD into cluster                      |
| `--skip-crds`                     | Omit CRDs           | Use when CRDs are already installed or managed separately |
| `--namespace`                     | Target namespace    | Ensures all resources are scoped correctly                |
| `--version`                       | Chart version       | Prevents breaking changes by locking version              |

---

---

### ✅ **9. Divide Node Resources (Include Init Containers)**

📘 **Docs:**

- [Resource Requests and Limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

**Deployment Snippet:**

```yaml
initContainers:
- name: init
  image: busybox
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "100m"
      memory: "128Mi"

containers:
- name: app
  resources:
    requests:
      cpu: "500m"
      memory: "256Mi"
    limits:
      cpu: "500m"
      memory: "256Mi"
```

---

### ✅ **10. Least Permissive NetworkPolicy**

📘 **Docs:**

- [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

**Example:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-backend
  namespace: frontend
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              name: back-end
          podSelector:
            matchLabels:
              app: backend
```

---

### ✅ **11. Install CNI: Flannel vs Calico**

📘 **Docs:**

- [CNI Overview](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)

#### When to choose:

- **Flannel**: Basic overlay, no policy.
- **Calico**: Advanced policy support.

**Calico Install:**

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
```

---

### ✅ **12. HPA - Horizontal Pod Autoscaler**

📘 **Docs:**

- [HPA Walkthrough](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

**Example:**

```bash
kubectl autoscale deployment my-deploy \
  --cpu-percent=50 \
  --min=1 \
  --max=5
```

---

### ✅ **13. Troubleshooting**

Usually involves:

```bash
kubectl get pods
kubectl describe pod <pod>
kubectl logs <pod>
kubectl get events
```

---

### ✅ **14. Expose Deployment via NodePort and Fix Port in Deployment**

📘 **Docs:**

- [Service Types](https://kubernetes.io/docs/concepts/services-networking/service/#nodeport)

**Service Example:**

```yaml
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30007
```

**Deployment Fix:**

```yaml
ports:
- containerPort: 8080
```

---

### ✅ **15. Priority Class**

📘 **Docs:**

- [Pod Priority](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)

**PriorityClass:**

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 100000
globalDefault: false
```

**Use in Pod/Deployment:**

```yaml
priorityClassName: high-priority
```

---
