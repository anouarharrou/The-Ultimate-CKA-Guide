# Helm Crash Course + Bitnami Keycloak Customization Guide

## Table of Contents

1. [Helm Core Commands](#helm-core-commands)
2. [Helm Repo Management](#helm-repo-management)
3. [Helm Chart Lifecycle](#helm-chart-lifecycle)
4. [Helm Chart Customization (Bitnami Keycloak Example)](#helm-chart-customization-bitnami-keycloak-example)
5. [Pro Tips](#pro-tips)

---

## Helm Core Commands

### Chart Lifecycle Commands

```bash
helm install <release> <chart> [flags]       # Install a chart
helm upgrade <release> <chart> [flags]       # Upgrade a release
helm uninstall <release>                     # Uninstall a release
helm rollback <release> [revision]           # Rollback to a revision
```

### Chart Discovery & Inspection

```bash
helm repo list                               # List repos
helm search repo <chart>                     # Search repo
helm show values <chart>                     # Show default values
helm show chart <chart>                      # Show chart metadata
helm pull <chart> [flags]                    # Download chart archive
helm template <release> <chart> [flags]      # Render manifest without installing
```

### Helm Release Management

```bash
helm list [-A]                                # List releases
helm get all <release>                        # Full release manifest and metadata
helm get values <release>                     # Get current values
helm get manifest <release>                   # Get rendered manifest
helm get notes <release>                      # Get post-install notes
```

### Chart Development & Testing

```bash
helm create <chart-name>                      # Scaffold chart
helm lint <path>                              # Lint a chart
helm package <path>                           # Create .tgz archive
helm dependency update                        # Update dependencies
```

### Testing & Debugging

```bash
helm test <release>                           # Run tests
helm upgrade/install --dry-run --debug        # Dry-run preview
```

### Miscellaneous

```bash
helm env                                      # Show Helm environment
helm version                                  # Show Helm version
helm help [command]                           # Help system
```

---

## Helm Repo Management

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm repo list
helm repo remove <name>
```

To check if a version exists:

```bash
helm search repo bitnami/keycloak --versions
```

---

## Helm Chart Lifecycle Example

```bash
helm install my-release bitnami/nginx --version 18.1.15
helm upgrade my-release bitnami/nginx --version 18.2.0
helm uninstall my-release
```

---

## Helm Chart Customization (Bitnami Keycloak Example)

### Step 1: Add & Fetch the Chart

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm pull bitnami/keycloak --untar
cd keycloak
```

### Step 2: View All Configurable Values

```bash
helm show values bitnami/keycloak > default-values.yaml
```

### Step 3: Create `values-rxmaple.yaml`

```yaml
auth:
  adminUser: rxadmin
  adminPassword: rxsecret

service:
  type: ClusterIP
  port: 8080

ingress:
  enabled: true
  hostname: keycloak.rxmaple.internal
  path: /
  ingressClassName: nginx
  tls: false

postgresql:
  enabled: true
  auth:
    username: rxmaple_user
    password: rxmaple_pass
    database: keycloak_rxmaple

persistence:
  enabled: true
  storageClass: standard
  size: 1Gi

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

### Step 4: Install with Custom Values

```bash
helm install rxmaple-keycloak bitnami/keycloak -f values-rxmaple.yaml
```

### Step 5: Upgrade Later

```bash
helm upgrade rxmaple-keycloak bitnami/keycloak -f values-rxmaple.yaml
```

### Step 6: Debug and Preview

```bash
helm template rxmaple-keycloak bitnami/keycloak -f values-rxmaple.yaml
helm upgrade rxmaple-keycloak bitnami/keycloak -f values-rxmaple.yaml --dry-run --debug
```

---

## Pro Tips

* Always use `--dry-run --debug` before running `install` or `upgrade`.
* Use `extraEnvVars`, `extraVolumes`, `extraVolumeMounts` for advanced customizations.
* To use external DBs, disable the embedded DB and configure `externalDatabase.*` values.
* Use `helm show values` instead of editing `values.yaml` directly.
* Keep separate values files for each environment: `dev-values.yaml`, `prod-values.yaml`.
* Validate your YAML syntax with `yamllint`.

---
