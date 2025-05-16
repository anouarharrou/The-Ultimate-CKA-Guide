# Kubernetes User Creation, Role, and RBAC Guide

## Overview

This guide explains the process of creating a user, assigning roles, and configuring RBAC permissions in a Kubernetes cluster. It includes generating certificates, creating roles, role bindings, and setting up a kubeconfig bundle for secure access.

### Prerequisites

- A running Kubernetes cluster.
- `kubectl` installed and configured to access the cluster.
- `openssl` for generating certificates.
- The user must have access to a local machine or server where they can generate a private key and CSR.

## Steps to Create User, Assign Role, and Configure RBAC

### Step 1: **Generate Private Key and CSR for the User**

Generate a private key and a Certificate Signing Request (CSR) for the user `john`:

```bash
openssl genrsa -out /home/harry/john.key 2048
openssl req -new -key /home/harry/john.key -out /home/harry/john.csr -subj "/CN=john/O=development" -days 10000
```
### Step 2: Create CertificateSigningRequest (CSR) in Kubernetes
Base64 encode the john.csr file to embed it into a YAML manifest:

```bash
cat /home/harry/john.csr | base64 | tr -d '\n'
```
Create the john-csr.yaml file with the following content:


```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: john-developer
spec:
  request: <BASE64_ENCODED_CSR>
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
```
##### Note: Replace <BASE64_ENCODED_CSR> with the output from the base64 encoding command above.

#### Apply the CSR:

```bash
kubectl apply -f john-csr.yaml
```
### Step 3: Approve the CSR
Approve the CSR to issue a certificate for the user john:

```bash
kubectl certificate approve john-developer
```
### Step 4: Retrieve the Signed Certificate
After the CSR is approved, retrieve the signed certificate:

```bash
kubectl get csr john-developer -o jsonpath='{.status.certificate}' | base64 --decode > /home/harry/john.crt
```

### Step 5: Create Role for the User
Create a role for the user john that allows interacting with pods in the development namespace. Create the developer-role.yaml file:

```yaml

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: development
  name: developer
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["create", "list", "get", "update", "delete"]
```
Apply the role:

```bash
kubectl apply -f developer-role.yaml
```
### Step 6: Create RoleBinding for the User
Create a role binding to bind the developer role to john. Create the developer-rolebinding.yaml file:

```yaml

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: development
subjects:
- kind: User
  name: john
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```
#### Apply the role binding:

```bash
kubectl apply -f developer-rolebinding.yaml
```

### Step 7: Create Kubeconfig for the User
Create a kubeconfig file for the user john to authenticate to the cluster. Create a file named john.kubeconfig with the following content:

```yaml

apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /path/to/ca.crt
    server: https://<kubernetes-api-server-endpoint>
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: john
  name: john-context
current-context: john-context
users:
- name: john
  user:
    client-certificate: /home/harry/john.crt
    client-key: /home/harry/john.key
```

#### Note:

Replace /path/to/ca.crt with the path to your Kubernetes cluster's CA certificate.
Replace <kubernetes-api-server-endpoint> with the actual Kubernetes API server URL.

### Step 8: Distribute Kubeconfig and Certificates
After creating the john.kubeconfig, john.key, and john.crt files, provide these files to the user john securely. The user can now access the Kubernetes cluster with the assigned role and permissions.

### Step 9: Verify the User's Access
To test if the user has the correct permissions, the user can run the following command:

``` bash
kubectl --kubeconfig=/path/to/john.kubeconfig get pods -n development
```

Or

``` bash
kubectl auth can-i get deployment --as=system:serviceaccount:development:john
```

## Conclusion
You have successfully created a user john, assigned a developer role with the necessary permissions, and provided the user with the required kubeconfig file to authenticate and interact with the Kubernetes cluster.
