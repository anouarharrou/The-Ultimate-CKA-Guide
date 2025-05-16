# Kubernetes Mock Exam Q\&A

This document contains a consolidated list of mock exam questions and detailed answers related to Kubernetes tasks, including `kubectl`, Helm, HPA/VPA, Gateway API, and more. Each solution includes not just the command but also an explanation for clarity and understanding.

---

## 1. **List Deployments in a Namespace**

**Question:** Print the names of all deployments in the `admin2406` namespace in the format:

```
DEPLOYMENT   CONTAINER_IMAGE   READY_REPLICAS   NAMESPACE
<deployment name>   <container image used>   <ready replica count>   <Namespace>
```

Sorted by deployment name and write to `/opt/admin2406_data`.

**Answer:**

```bash
kubectl get deployments -n admin2406 \
  -o=custom-columns="DEPLOYMENT:.metadata.name,CONTAINER_IMAGE:.spec.template.spec.containers[*].image,READY_REPLICAS:.status.readyReplicas,NAMESPACE:.metadata.namespace" \
  --sort-by=.metadata.name > /opt/admin2406_data
```

**Explanation:**

* Uses custom columns to format output.
* `--sort-by=.metadata.name` ensures ascending sort by deployment name.
* Output is redirected to `/opt/admin2406_data`.

---

## 2. **Check Pods with Kubeconfig**

**Question:** Is this command correct?

```bash
k get po --kubeconfig=admin.kubeconfig
```

**Answer:**
No, it's incomplete. It should be:

```bash
kubectl get pods --kubeconfig=admin.kubeconfig
```

**Explanation:**

* `k` is an alias for `kubectl`, not always available.
* Use full `kubectl` command to avoid ambiguity.

---

## 3. **Upgrade Deployment with Annotation**

**Task:** Create a deployment `nginx-deploy` with `nginx:1.16` and 1 replica, then upgrade to `nginx:1.17` with annotation.

**Answer:**

```bash
kubectl create deployment nginx-deploy --image=nginx:1.16 --replicas=1
kubectl set image deployment/nginx-deploy nginx=nginx:1.17
kubectl annotate deployment nginx-deploy kubernetes.io/change-cause="Updated nginx image to 1.17"
```

**Explanation:**

* `set image` performs rolling update.
* `annotate` adds a change message.

---

## 4. **Multi-Container Pod with Shared Volume**

**Task:** Create a pod `mc-pod` in `mc-namespace` with 3 containers sharing a non-persistent volume.

**Answer:** See YAML below.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mc-pod
  namespace: mc-namespace
spec:
  containers:
  - name: mc-pod-1
    image: nginx:1-alpine
    env:
    - name: NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName

  - name: mc-pod-2
    image: busybox:1
    command: ["/bin/sh", "-c"]
    args: ["while true; do date >> /var/log/shared/date.log; sleep 1; done"]
    volumeMounts:
    - name: shared-data
      mountPath: /var/log/shared

  - name: mc-pod-3
    image: busybox:1
    command: ["/bin/sh", "-c"]
    args: ["tail -f /var/log/shared/date.log"]
    volumeMounts:
    - name: shared-data
      mountPath: /var/log/shared

  volumes:
  - name: shared-data
    emptyDir: {}
```

---

## 5. **Identify VPA CRDs**

**Task:** Save all CRDs related to VerticalPodAutoscaler to `/root/vpa-crds.txt`

**Answer:**

```bash
kubectl get crds | grep -i verticalpodautoscaler | awk '{print $1}' > /root/vpa-crds.txt
```

**Explanation:** Filters and extracts only the relevant CRD names.

---

## 6. **Expose Deployment via NodePort**

**Task:** Expose `hr-web-app` on NodePort 30082 for app listening on 8080.

**Answer:**

```bash
kubectl expose deployment hr-web-app \
  --name=hr-web-app-service \
  --port=8080 \
  --target-port=8080 \
  --type=NodePort

kubectl patch service hr-web-app-service \
  -p '{"spec": {"ports": [{"port": 8080, "targetPort": 8080, "nodePort": 30082}]}}'
```

**Verification:**

```bash
kubectl get endpoints hr-web-app-service
```

---

## 7. **Create HPA with Stabilization**

**Task:** Create HPA `webapp-hpa` for `kkapp-deploy`, scale on CPU >50%, stabilization 300s.

**Answer:**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: webapp-hpa
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: kkapp-deploy
  minReplicas: 1
  maxReplicas: 10
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

Apply:

```bash
kubectl apply -f /webapp-hpa.yaml
```

---

## 8. **Create VPA in Auto Mode**

**Task:** Deploy VPA `analytics-vpa` for `analytics-deployment`, with `updateMode: Auto`

**Answer:**

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: analytics-vpa
  namespace: default
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: analytics-deployment
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: "*"
      controlledResources: ["cpu", "memory"]
```

Apply:

```bash
kubectl apply -f analytics-vpa.yaml
```

---

## 9. **Create Gateway Resource**

**Task:** Create a Gateway `web-gateway` with class `nginx`, HTTP listener on port 80.

**Answer:**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
  namespace: nginx-gateway
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
```

Apply:

```bash
kubectl apply -f web-gateway.yaml
```

Verify:

```bash
kubectl get gateway web-gateway -n nginx-gateway -o yaml | grep port
```

---

## 10. **Helm Upgrade to Specific Chart Version**

**Task:** Upgrade Helm release `kk-mock1` in `kk-ns` to chart version `18.1.15`

**Steps:**

1. Check current chart:

```bash
helm list -n kk-ns
```

2. If repo is misnamed do the following 2 commands othersways just go to 3th command and do update:

```bash
helm repo remove kk-mock1
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

3. Upgrade:

```bash
helm upgrade kk-mock1 bitnami/nginx --namespace kk-ns --version 18.1.15
```

4. Verify chart version:

```bash
helm list -n kk-ns | grep kk-mock1
```

---

## 📘 Documentation References

* [Kubernetes Docs](https://kubernetes.io/docs/home/)
* [Helm Docs](https://helm.sh/docs/)
* [Gateway API](https://gateway-api.sigs.k8s.io/)
* [HPA v2 API](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
* [Vertical Pod Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)

---

Let me know if you want a shell script or automation for these tasks.
