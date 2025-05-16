
# 🚨 Kubernetes Task Review Report

---

## 📌 Q1: Create Default StorageClass

🔧 **Context:** `ssh cluster1-controlplane`

🎯 **Objective:**

* Create a `StorageClass` named `local-sc`
* Use `kubernetes.io/no-provisioner`
* Volume binding mode: `WaitForFirstConsumer`
* Volume expansion: `true`
* Set as the default StorageClass

💡 **Solution:**

```yaml
# local-sc.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-sc
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

🔁 Apply & Verify:

```bash
ssh cluster1-controlplane
kubectl apply -f local-sc.yaml
kubectl get storageclass
```

✅ You should see `local-sc` marked as `(default)`.

---

## 📌 Q2: Logging Deployment with Sidecar

🔧 **Context:** `ssh cluster1-controlplane`

🎯 **Objective:**

* Create `logging-deployment` in `logging-ns` with:

  * Main container: `app-container`, image: `busybox`
  * Logs written to `/var/log/app/app.log`
  * Sidecar: `log-agent`, `tail -f` same log file
* Shared `emptyDir` volume

💡 **Solution:**

```yaml
# logger-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: logging-deployment
  namespace: logging-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: logger
  template:
    metadata:
      labels:
        app: logger
    spec:
      volumes:
      - name: log-volume
        emptyDir: {}
      containers:
      - name: app-container
        image: busybox
        command:
        - sh
        - -c
        - "while true; do echo 'Log entry' >> /var/log/app/app.log; sleep 5; done"
        volumeMounts:
        - name: log-volume
          mountPath: /var/log/app
      - name: log-agent
        image: busybox
        command:
        - tail
        - -f
        - /var/log/app/app.log
        volumeMounts:
        - name: log-volume
          mountPath: /var/log/app
```

🔁 Apply & Verify:

```bash
kubectl apply -f logger-deployment.yaml
kubectl logs -n logging-ns deployment/logging-deployment -c log-agent
```

📈 You should see log lines from `app-container`.

---

## 📌 Q3: Ingress for Web App

🔧 **Context:** `ssh cluster1-controlplane`

🎯 **Objective:**

* Ingress name: `webapp-ingress`
* Namespace: `ingress-ns`
* Host: `kodekloud-ingress.app`
* Path: `/`, type: `Prefix`
* Route to: `webapp-svc` on port `80`

💡 **Solution:**

```yaml
# webapp-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  namespace: ingress-ns
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: kodekloud-ingress.app
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp-svc
            port:
              number: 80
```

🔁 Apply & Test:

```bash
kubectl apply -f webapp-ingress.yaml
curl http://kodekloud-ingress.app/
```

---

## 📌 Q4: Nginx Deployment and Upgrade

🔧 **Context:** `ssh cluster1-controlplane`

🎯 **Objective:**

* Create `nginx-deploy` with image `nginx:1.16`
* Upgrade to `nginx:1.17` using rolling update

💡 **Solution:**

```bash
kubectl create deployment nginx-deploy --image=nginx:1.16 --dry-run=client -o yaml > deploy.yaml
kubectl apply -f deploy.yaml --record
kubectl set image deployment/nginx-deploy nginx=nginx:1.17 --record
kubectl rollout history deployment nginx-deploy
```

---

## 📌 Q5: Create User Access with CSR

🔧 **Context:** `ssh cluster1-controlplane`

🎯 **Objective:**

* CSR: `john-developer`, signer: `kube-apiserver-client`
* Private Key: `/root/CKA/john.key`
* CSR: `/root/CKA/john.csr`
* Role: `developer` for `development` namespace

💡 **Solution:**

```yaml
# john-developer CSR YAML (with base64-encoded CSR)
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: john-developer
spec:
  signerName: kubernetes.io/kube-apiserver-client
  request: BASE64_ENCODED_CSR
  usages:
  - digital signature
  - key encipherment
  - client auth
```

🔁 Apply & Approve:

```bash
kubectl apply -f john-csr.yaml
kubectl certificate approve john-developer
kubectl create role developer --resource=pods --verb=create,list,get,update,delete --namespace=development
kubectl create rolebinding developer-role-binding --role=developer --user=john --namespace=development
kubectl auth can-i update pods --as=john --namespace=development
```

---

## 📌 Q6: DNS Pod & Service Resolution

🔧 **Context:** `ssh cluster1-controlplane`

🎯 **Objective:**

* Create pod `nginx-resolver`, expose with service
* Test DNS from busybox pod and record to files

💡 **Solution:**

```bash
kubectl run nginx-resolver --image=nginx
kubectl expose pod nginx-resolver --name=nginx-resolver-service --port=80 --target-port=80
kubectl run test-nslookup --image=busybox:1.28 --rm -it --restart=Never -- nslookup nginx-resolver-service > /root/CKA/nginx.svc
kubectl get pod nginx-resolver -o wide
kubectl run test-nslookup --image=busybox:1.28 --rm -it --restart=Never -- nslookup <pod-ip.default.pod> > /root/CKA/nginx.pod
```

---

## 📌 Q7: Static Pod on Node

🔧 **Context:** `ssh cluster1-node01`

🎯 **Objective:**

* Create static pod: `nginx-critical`
* Place it in `/etc/kubernetes/manifests`

💡 **Solution:**

```bash
kubectl run nginx-critical --image=nginx --dry-run=client -o yaml > static.yaml
scp static.yaml cluster1-node01:/root/
ssh cluster1-node01
mkdir -p /etc/kubernetes/manifests
vi /var/lib/kubelet/config.yaml  # ensure staticPodPath is configured
cp /root/static.yaml /etc/kubernetes/manifests/
exit
kubectl get pods
```

---

## 📌 Q8: Horizontal Pod Autoscaler (HPA)

🔧 **Context:** `ssh cluster1-controlplane`

🎯 **Objective:**

* Create HPA `backend-hpa` for `backend-deployment` in `backend` namespace
* Memory average utilization: `65%`
* Min: `3`, Max: `15` replicas

💡 **Solution:**

```yaml
# webapp-hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
  namespace: backend
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend-deployment
  minReplicas: 3
  maxReplicas: 15
  metrics:
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 65
```

🔁 Apply:

```bash
kubectl create -f webapp-hpa.yaml
```

---

## 📌 Q9: Fix Kubelet Issue

🔧 **Context:** `ssh cluster2-controlplane`

🎯 **Objective:**

* Restore control plane by restarting `kubelet`

💡 **Solution:**

```bash
ssh cluster2-controlplane
journalctl -xe
systemctl status kubelet
sudo systemctl start kubelet
sudo systemctl enable kubelet
kubectl get nodes
```

---

## 📌 Q10: Update Gateway to Support HTTPS

🔧 **Context:** `ssh cluster1-controlplane`

🎯 **Objective:**

* Modify `web-gateway` in `cka5673` namespace to:

  * Handle HTTPS on port `443`
  * Use TLS cert in secret `kodekloud-tls`

💡 **Partial YAML (Example):**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
  namespace: cka5673
spec:
  listeners:
  - name: https
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: kodekloud-tls
        kind: Secret
        group: ""
```
---

## 📌 Q11 - Identify and Uninstall Vulnerable Helm Chart**

**Target Image:** `kodekloud/webapp-color:v1`

**Steps:**

```bash
helm ls -A  # List all releases across namespaces
```

For each release:

```bash
kubectl get deploy -n <NAMESPACE> -o name  # Get deployments
kubectl get deploy <DEPLOYMENT-NAME> -n <NAMESPACE> -o json | jq -r '.spec.template.spec.containers[].image'
```

When you find `kodekloud/webapp-color:v1` in one of the deployments:

```bash
helm uninstall <RELEASE-NAME> -n <NAMESPACE>
```

✅ **Confirmation:**
Run `helm ls -A` again to ensure the release is gone.

---

## 📌 Q12 - Apply Most Restrictive NetworkPolicy**

**Goal:** Allow traffic from `frontend` namespace to `backend` only. Deny `databases`.

**Steps:**

```bash
cat /root/net-pol-1.yaml
cat /root/net-pol-2.yaml
cat /root/net-pol-3.yaml  # <-- This is the correct one
```

**Why net-pol-3.yaml is correct:**

* Specifically allows from `frontend` only
* No mention of `databases` = denied

**Apply:**

```bash
kubectl apply -f /root/net-pol-3.yaml
kubectl get netpol -n backend
```

✅ **Validation:** Only `net-pol-3` should appear.

---

## 📌 Q13 - Fix Failed Deployment Due to ResourceQuota**

**Issue:** `ResourceQuota` blocks a pod due to memory over-allocation. You can’t touch the quota.

**Steps:**

```bash
kubectl get deploy
kubectl describe rs backend-api-<hash>  # Shows ResourceQuota exceeded
```

**Fix Deployment:**

```bash
kubectl edit deployment backend-api
```

Reduce memory **requests** to **fit within quota**:

```yaml
resources:
  requests:
    cpu: "50m"
    memory: "90Mi"
  limits:
    cpu: "150m"
    memory: "150Mi"
```

If the pod still doesn’t spawn:

```bash
kubectl get rs
kubectl delete rs backend-api-<old-hash>
```

✅ **Confirm:**

```bash
kubectl get pods  # All should be Running
```

---

## 📌 Q14 - Install Calico with Custom CIDR**

**CIDR Required:** `172.17.0.0/16`

**Steps:**

1. **Install Tigera Operator:**

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/tigera-operator.yaml
```

2. **Download and Edit Custom Resources:**

```bash
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/custom-resources.yaml
vi custom-resources.yaml
```

**Update the CIDR block:**

```yaml
cidr: 172.17.0.0/16
```

3. **Apply:**

```bash
kubectl create -f custom-resources.yaml
watch kubectl get pods -n calico-system
```

4. **Test Connectivity:**

```bash
kubectl run web-app --image=nginx
kubectl get pod web-app -o jsonpath='{.status.podIP}'

kubectl run test --rm -it --image=jrecord/nettools -- curl <web-app-IP>
```

✅ **Success Criteria:**

* Calico pods are up
* Curl returns HTTP 200

---


