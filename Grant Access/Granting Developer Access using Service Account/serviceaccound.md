Hello:

---

# Granting Developer Access in Kubernetes

As an admin, follow these steps to provide the necessary access to a developer **restricted to the `dev` namespace**:

---

### 1. **Create the Service Account**

Create a file named `service-account.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: developer
  namespace: dev
```

Apply it:

```sh
kubectl apply -f service-account.yaml
```

---

### 2. **Create the Role** *(namespace-scoped access only)*

Create a file named `role.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-role
  namespace: dev
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch", "create", "update", "delete"]
```

Apply it:

```sh
kubectl apply -f role.yaml
```

---

### 3. **Create the RoleBinding**

Create a file named `rolebinding.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-rolebinding
  namespace: dev
subjects:
- kind: ServiceAccount
  name: developer
  namespace: dev
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
```

Apply it:

```sh
kubectl apply -f rolebinding.yaml
```

---

### 4. **(Do Not Create ClusterRole or ClusterRoleBinding)**

> ⚠️ **Important:** *To prevent the developer from accessing other namespaces, do **not** bind any `ClusterRole` or create `ClusterRoleBinding`.*

---

### 5. **Authenticate the Developer**

#### **Option A: Token Authentication (simpler, short-lived)**

Extract the token:

```sh
kubectl get secret $(kubectl get sa developer -n dev -o jsonpath="{.secrets[0].name}") \
  -n dev -o jsonpath="{.data.token}" | base64 --decode
```

#### **Option B: Certificate-Based Authentication (longer-lived, more secure)**

1. **Generate a Private Key and CSR** on the developer’s machine:

```sh
openssl genrsa -out developer.key 2048
openssl req -new -key developer.key -out developer.csr -subj "/CN=developer/O=dev"
```

2. **Create a CSR resource in Kubernetes**:

```yaml
# developer-csr.yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: developer-csr
spec:
  request: <base64-encoded-csr>
  signerName: kubernetes.io/kube-apiserver-client
  usages:
    - client auth
```

Get base64-encoded CSR content and insert it:

```sh
cat developer.csr | base64 | tr -d '\n'
```

Then apply:

```sh
kubectl apply -f developer-csr.yaml
```

3. **Approve and retrieve the certificate**:

```sh
kubectl certificate approve developer-csr
kubectl get csr developer-csr -o jsonpath='{.status.certificate}' | base64 --decode > developer.crt
```

Now the developer has:
- `developer.key` (private key)
- `developer.crt` (signed client cert)

---

### 6. **Provide Configuration to the Developer**

#### If using **Token**:

```sh
TOKEN=<service-account-token>
kubectl config set-credentials developer-user --token=$TOKEN
```

#### If using **Certificate**:

```sh
kubectl config set-credentials developer-user \
  --client-certificate=developer.crt \
  --client-key=developer.key
```

Then set context:

```sh
kubectl config set-context developer-context \
  --cluster=your-cluster \
  --namespace=dev \
  --user=developer-user
kubectl config use-context developer-context
```

Replace `your-cluster` with the actual cluster name.

---

### ✅ Result

The developer can now only access the `dev` namespace, with either token or certificate authentication — depending on your security preference.