# 🧠 Kubernetes Handy CLI Reference & Admin Tips

A powerful collection of practical `kubectl` commands and operational tips to streamline your daily Kubernetes workflow and ace the CKA exam. This guide is useful for both CKA candidates and K8s practitioners.

---

## 🔄 Switch Namespace Context

```bash
kubectl config set-context $(kubectl config current-context) --namespace=dev
```

## 📋 View Pods Across All Namespaces

```bash
kubectl get pods --all-namespaces
```

---

## 🐳 Working With Pods

### 🚀 Create a Pod
```bash
kubectl run nginx --image=nginx
```

### 🛠️ Generate Pod Manifest Without Creating It
```bash
kubectl run nginx --image=nginx --dry-run=client -o yaml
```

---

## 🌐 Pod Exposure

### 📡 Expose a Pod and Create a ClusterIP Service
```bash
kubectl run my-app --image=nginx --port=80 --expose
```

### 📡 Expose with Specific Service Type (e.g., NodePort)
```bash
kubectl run my-app --image=nginx --port=80 --expose --service-type=NodePort
```

---

## 📦 Deployments

### 🚀 Create a Deployment
```bash
kubectl create deployment nginx --image=nginx
```

### 📝 Generate Deployment YAML Without Creating It
```bash
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml
```

### 📊 Scale Deployment to 4 Replicas
```bash
kubectl scale deployment nginx --replicas=4
```
---
## 🔁 ReplicaSets

**Scale ReplicaSet using file**
```bash
kubectl scale --replicas=6 -f replicaset-definition.yaml
```

**Scale ReplicaSet by name**
```bash
kubectl scale --replicas=6 replicaset myapp-replicaset
```
---

## 🔌 Services

### 🚀 ClusterIP for Redis Pod
```bash
kubectl expose pod redis --port=6379 --name redis-service --dry-run=client -o yaml
```

### 🔍 Or Using ClusterIP Generator
```bash
kubectl create service clusterip redis --tcp=6379:6379 --dry-run=client -o yaml
```

### 🌐 NodePort for NGINX Pod (Manual NodePort Set)
```bash
kubectl create service nodeport nginx --tcp=80:80 --node-port=30080 --dry-run=client -o yaml
```

### ☁️ LoadBalancer Service for Deployment
```bash
kubectl expose deployment example --port=8765 --target-port=9376 --name=example-service --type=LoadBalancer
```

---

## 🔁 Service Types Cheat Sheet

| 🌐 Requirement               | 🛠️ Service Type |
|-----------------------------|-----------------|
| Internal communication only | `ClusterIP`     |
| Basic external access       | `NodePort`      |
| Public cloud access         | `LoadBalancer`  |
| Connect to external svc     | `ExternalName`  |

---

## 🔁 ReplicaSet Scaling

```bash
kubectl scale --replicas=6 -f replicaset-definition.yaml
kubectl scale --replicas=6 replicaset myapp-replicaset
```

---
## 📜 Logs and Debugging

**Follow logs**
```bash
kubectl logs my-app-pod -f
```

**Get logs from previous container**
```bash
kubectl logs my-app-pod --previous
```

**Get logs with timestamps**
```bash
kubectl logs my-app-pod --timestamps
```

**Delete Pods by name pattern**
```bash
kubectl delete po $(kubectl get po --no-headers | awk '$1 ~ /new-replica-set/ {print $1}')
```

**Compare local manifest with live Pod**
```bash
kubectl get pods/[pod-name] -o yaml > apiserver-[pod-name].yaml
```

**Ephemeral debug container**
```bash
kubectl debug -it [pod-name] --image=[image-name] --target=[pod-name]
```

---
## 🧠 Cluster & Node Diagnostics

**Cluster log locations**
```bash

| Node Type | Component            | Log File Location                  |
|-----------|----------------------|------------------------------------|
| Master    | API Server           | /var/log/kube-apiserver.log        |
| Master    | Scheduler            | /var/log/kube-scheduler.log        |
| Master    | Controller Manager   | /var/log/kube-controller-manager.log |
| Worker    | Kubelet              | /var/log/kubelet.log               |
| Worker    | Kube Proxy           | /var/log/kube-proxy.log            |

```

---

## 🧹 Delete Pods by Name Pattern

```bash
kubectl delete po --field-selector metadata.name=new-replica-set
```

### 🧼 Wildcard Pattern Match
```bash
kubectl delete po $(kubectl get po --no-headers | awk '$1 ~ /new-replica-set/ {print $1}')
```
---

## 🔍 Manifest Debugging & Debug Containers

### 📑 Compare Manifest From API Server
```bash
kubectl get pod <pod-name> -o yaml > apiserver-<pod-name>.yaml
```

### 🐞 Create Ephemeral Debug Container
```bash
kubectl debug -it <pod-name> --image=busybox --target=<container-name>
```

---

## 🧾 Cluster Component Logs

| Node Type | Component            | Location                                |
|-----------|----------------------|-----------------------------------------|
| Master    | API Server           | `/var/log/kube-apiserver.log`           |
| Master    | Scheduler            | `/var/log/kube-scheduler.log`           |
| Master    | Controller Manager   | `/var/log/kube-controller-manager.log`  |
| Worker    | Kubelet              | `/var/log/kubelet.log`                  |
| Worker    | Kube Proxy           | `/var/log/kube-proxy.log`               |

---

## ⚖️ Taints & Tolerations vs Node Affinity

| Feature           | Taints & Tolerations                     | Node Affinity                            |
|------------------|------------------------------------------|-------------------------------------------|
| Control Mechanism| Node says “stay away unless…”            | Pod says “I want to go here”             |
| Who Defines It?  | Node (taints), Pod (tolerates)           | Pod defines it                           |
| Default Behavior | Blocks pods unless tolerated             | No blocking; only schedules if matches   |
| Use For          | Dedicated nodes, workload isolation      | Preferred placement, constraints         |

---

> 💡 **TIP**: Use `--dry-run=client -o yaml > file.yaml` to safely generate any manifest and tweak before applying.

> 💥 **Practice these live in a real cluster or minikube setup. Don’t memorize. Internalize!**


---
## 📚 Useful Kubernetes Documentation Links
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [ReplicaSets](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Node Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)