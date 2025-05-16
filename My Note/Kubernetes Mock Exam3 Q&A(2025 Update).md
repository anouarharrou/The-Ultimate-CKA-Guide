## Q.1 🚀

**Task**

Prepare your environment for Kubernetes cluster deployment using kubeadm. Adjust and persist the following network parameters:

* `net.ipv4.ip_forward = 1`
* `net.bridge.bridge-nf-call-iptables = 1`

**Solution**

```bash
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf
sysctl -p
```

To verify:

```bash
sysctl net.ipv4.ip_forward
sysctl net.bridge.bridge-nf-call-iptables
```

## Q.2 👷‍♂️

**Task**

Create a service account `pvviewer`, a `ClusterRole` `pvviewer-role`, and a `ClusterRoleBinding` `pvviewer-role-binding` to allow listing PersistentVolumes. Deploy a pod using the service account.

**Solution**

```bash
kubectl create serviceaccount pvviewer
kubectl create clusterrole pvviewer-role --resource=persistentvolumes --verb=list
kubectl create clusterrolebinding pvviewer-role-binding --clusterrole=pvviewer-role --serviceaccount=default:pvviewer
```

Pod manifest:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pvviewer
spec:
  containers:
  - image: redis
    name: pvviewer
  serviceAccountName: pvviewer
```

## Q.3 🏛️

**Task**

Create a `StorageClass` named `rancher-sc`:

* provisioner: `rancher.io/local-path`
* volumeBindingMode: `WaitForFirstConsumer`
* allowVolumeExpansion: true

**Solution**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rancher-sc
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

Apply:

```bash
kubectl apply -f rancher-sc.yaml
```

## Q.4 📊

**Task**

Create a `ConfigMap` named `app-config` in `cm-namespace` with keys:

* ENV=production
* LOG\_LEVEL=info

Update deployment `cm-webapp` to use these variables.

**Solution**

```bash
kubectl create configmap app-config -n cm-namespace \
  --from-literal=ENV=production \
  --from-literal=LOG_LEVEL=info
kubectl set env deployment/cm-webapp -n cm-namespace --from=configmap/app-config
```

## Q.5 ⬆️

**Task**

Create `PriorityClass` `low-priority` (value: 50000) and assign it to pod `lp-pod` in namespace `low-priority`.

**Solution**

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 50000
globalDefault: false
description: "Low priority class"
```

Apply and recreate pod with:

```bash
kubectl delete pod lp-pod -n low-priority
kubectl apply -f lp-pod.yaml
```

## Q.6 🚧

**Task**

Fix incoming connections to `np-test-service` by creating a `NetworkPolicy` named `ingress-to-nptest` allowing port 80.

**Solution**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ingress-to-nptest
  namespace: default
spec:
  podSelector:
    matchLabels:
      run: np-test-1
  policyTypes:
  - Ingress
  ingress:
  - ports:
    - protocol: TCP
      port: 80
```

## Q.7 🛂

**Task**

Taint node `node01`. Schedule `prod-redis` with toleration. Prevent `dev-redis` from running on `node01`.

**Solution**

```bash
kubectl taint node node01 env_type=production:NoSchedule
kubectl run dev-redis --image=redis:alpine
```

Prod pod manifest:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: prod-redis
spec:
  containers:
  - name: prod-redis
    image: redis:alpine
  tolerations:
  - key: env_type
    operator: Equal
    value: production
    effect: NoSchedule
```

## Q.8 📁

**Task**

Fix binding issue between PVC `app-pvc` and PV `app-pv` in namespace `storage-ns`. Don't modify PV.

**Solution**
Update PVC's access mode to match PV:

```bash
kubectl get pvc app-pvc -n storage-ns -o yaml > pvc.yaml
# Edit accessModes to match PV
kubectl delete pvc -n storage-ns app-pvc
kubectl apply -f pvc.yaml
```

## Q.9 📂

**Task**

Fix the kubeconfig file `/root/CKA/super.kubeconfig` with incorrect port (9999).

**Solution**

```bash
vi /root/CKA/super.kubeconfig
# Change port to 6443
kubectl cluster-info --kubeconfig=/root/CKA/super.kubeconfig
```

## Q.10 📉

**Task**

Scale `nginx-deploy` to 3 replicas. Troubleshoot if not scaling.

**Solution**

```bash
kubectl scale deploy nginx-deploy --replicas=3
```

If controller-manager has a typo:

```bash
sed -i 's/kube-contro1ler-manager/kube-controller-manager/g' /etc/kubernetes/manifests/kube-controller-manager.yaml
```

## Q.11 📊

**Task**

Create an HPA `api-hpa` in namespace `api` for deployment `api-deployment`. Use custom metric `requests_per_second` with avg 1000. Min: 1, Max: 20.

**Solution**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
  namespace: api
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-deployment
  minReplicas: 1
  maxReplicas: 20
  metrics:
  - type: Pods
    pods:
      metric:
        name: requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"
```

Apply:

```bash
kubectl apply -f api-hpa.yaml
```

## Q.12 🚧📅

**Task**

Configure `web-route` to split traffic: 80% to `web-service`, 20% to `web-service-v2`. Use `web-gateway`.

**Solution**

```bash
kubectl create -n default -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
spec:
  parentRefs:
    - name: web-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web-service
      port: 80
      weight: 80
    - name: web-service-v2
      port: 80
      weight: 20
EOF
```

## Q.13 📄

**Task**

Upgrade Helm deployment `webpage-server-01` with chart in `/root/new-version`. Validate first, install, then uninstall old release.

**Solution**

```bash
helm ls -n default
cd /root/
helm lint ./new-version
helm install --generate-name ./new-version
helm uninstall webpage-server-01 -n default
```

## Q.14 🌐

**Task**

Identify and output Kubernetes cluster Pod CIDR to `/root/pod-cidr.txt`.

**Solution**

```bash
kubectl get node -o jsonpath='{.items[0].spec.podCIDR}' > /root/pod-cidr.txt
cat /root/pod-cidr.txt
```
