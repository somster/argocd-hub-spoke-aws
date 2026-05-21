---
name: argo-deployments
description: Complete ArgoCD API and CLI skill for GitOps automation. Use when working with ArgoCD for: (1) Managing Applications - create, sync, delete, rollback, get status, (2) ApplicationSets - templated multi-cluster argo-deployments, (3) Projects - RBAC, source/destination restrictions, sync windows, (4) Repositories - add/remove Git repos, Helm charts, OCI registries, (5) Clusters - register, rotate credentials, manage multi-cluster, (6) Accounts - generate tokens, manage users, check permissions, (7) Any ArgoCD REST API calls or argo-deployments CLI commands. Supports both REST API (curl/HTTP) and CLI wrapper approaches with bearer token authentication.
---

# ArgoCD Skill

Complete ArgoCD operations via REST API and CLI with bearer token authentication.

## Version Management

**CRITICAL**: This skill MUST ONLY generate output based on the latest stable ArgoCD version at invocation time.

Before generating any ArgoCD configuration or commands:

1. **Fetch latest stable ArgoCD version**:
   ```bash
   ARGOCD_VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases | \
     jq -r '.[] | select(.prerelease==false) | .tag_name' | head -1)
   echo "Latest stable ArgoCD: $ARGOCD_VERSION"
   ```

2. **Verify installed version matches or exceeds latest stable**:
   ```bash
   argo-deployments version --short
   # Should be at least the latest stable version
   ```

3. **Always use latest stable in Helm charts and manifests**:
   - Helm: Use `chart: argoproj/argo-cd` with `version: ">=3.0"` (or current major version)
   - K8s manifests: Reference latest stable release from `https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`

4. **API version compatibility**: All API endpoints in this skill support ArgoCD v3.0+. If generating for older versions, explicitly warn the user.

## Constraints

### MUST DO
- Use latest stable ArgoCD version only
- Validate token permissions before operations
- Use HTTPS for all API calls
- Implement proper error handling
- Document cluster credentials storage
- Use bearer token authentication (not password-based)

### MUST NOT DO
- Use pre-release or development ArgoCD versions in production
- Store authentication tokens in code or logs
- Mix ArgoCD major versions in multi-cluster setups
- Skip validation of sync policies
- Use HTTP (always use HTTPS for API calls)

## Authentication Setup

Generate and use bearer tokens for all operations:

```bash
# Generate token (requires existing login)
argo-deployments login $ARGOCD_SERVER --username admin --password $ARGOCD_PASSWORD
ARGOCD_TOKEN=$(argo-deployments account generate-token)

# Or generate for service account
ARGOCD_TOKEN=$(argo-deployments account generate-token --account cibot --expires-in 7d)

# Export for subsequent commands
export ARGOCD_SERVER="argocd.example.com"
export ARGOCD_AUTH_TOKEN="$ARGOCD_TOKEN"
```

**Service account setup** (in argocd-cm ConfigMap):

```yaml
data:
  accounts.cibot: apiKey,login
  accounts.cibot.enabled: "true"
```

## REST API Pattern

All API calls use this pattern:

```bash
curl -s -H "Authorization: Bearer $ARGOCD_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  "https://$ARGOCD_SERVER/api/v1/{endpoint}"
```

Use the helper script at `scripts/argocd-api.sh` for common operations.

## Quick Reference

### Applications

```bash
# List all applications
argo-deployments app list -o json

# Create application
argo-deployments app create myapp \
  --repo https://github.com/org/repo.git \
  --path manifests \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Sync with options
argo-deployments app sync myapp --prune --force --timeout 300

# Sync specific resources only
argo-deployments app sync myapp --resource apps:Deployment:nginx

# Dry run
argo-deployments app sync myapp --dry-run

# Wait for health
argo-deployments app wait myapp --health --sync --timeout 300

# Get status
argo-deployments app get myapp -o json | jq '{health: .status.health.status, sync: .status.sync.status}'

# Rollback
argo-deployments app history myapp
argo-deployments app rollback myapp 2

# Delete (cascade deletes resources)
argo-deployments app delete myapp --cascade -y

# Terminate running operation
argo-deployments app terminate-op myapp
```

### ApplicationSets

```bash
# Create/update ApplicationSet
argo-deployments appset create appset.yaml --upsert

# List
argo-deployments appset list

# Get details
argo-deployments appset get myappset -o yaml

# Delete
argo-deployments appset delete myappset -y
```

### Projects

```bash
# Create project
argo-deployments proj create myproject -d https://kubernetes.default.svc,default -s https://github.com/org/*

# Add destinations/sources
argo-deployments proj add-destination myproject https://kubernetes.default.svc 'team-*'
argo-deployments proj add-source myproject 'https://github.com/org/*'

# Manage roles
argo-deployments proj role create myproject deployer
argo-deployments proj role add-policy myproject deployer -a sync -p allow -o '*'
argo-deployments proj role add-group myproject deployer my-sso-group

# Generate role token
argo-deployments proj role create-token myproject deployer --expires-in 24h

# Sync windows
argo-deployments proj windows add myproject --kind allow --schedule "0 22 * * *" --duration 2h
argo-deployments proj windows list myproject
```

### Repositories

```bash
# Add HTTPS repo with token
argo-deployments repo add https://github.com/org/repo --username git --password $GH_TOKEN

# Add SSH repo
argo-deployments repo add git@github.com:org/repo.git --ssh-private-key-path ~/.ssh/id_rsa

# Add Helm repo
argo-deployments repo add https://charts.example.com --type helm --name myrepo

# Add OCI registry
argo-deployments repo add registry.example.com --type helm --enable-oci --username user --password pass

# Credential template (applies to matching repos)
argo-deployments repocreds add https://github.com/myorg/ --username git --password $TOKEN

# List/remove
argo-deployments repo list
argo-deployments repo rm https://github.com/org/repo
```

### Clusters

```bash
# Add cluster from kubeconfig context
argo-deployments cluster add my-context --name production

# List clusters
argo-deployments cluster list

# Get cluster details
argo-deployments cluster get https://production.example.com

# Rotate credentials
argo-deployments cluster rotate-auth production

# Remove cluster
argo-deployments cluster rm https://production.example.com
```

### Accounts

```bash
# List accounts
argo-deployments account list

# Generate token
argo-deployments account generate-token --account cibot --expires-in 7d --id deploy-token

# Check permissions
argo-deployments account can-i sync applications '*'
argo-deployments account can-i get applications 'myproject/*'

# Update password
argo-deployments account update-password --account admin

# Get user info
argo-deployments account get-user-info
```

## REST API Examples

See `references/api-reference.md` for complete endpoint documentation.

### Create Application via API

```bash
curl -X POST -H "Authorization: Bearer $ARGOCD_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  "https://$ARGOCD_SERVER/api/v1/applications" \
  -d '{
    "metadata": {"name": "myapp", "namespace": "argo-deployments"},
    "spec": {
      "project": "default",
      "source": {
        "repoURL": "https://github.com/org/repo.git",
        "path": "manifests",
        "targetRevision": "HEAD"
      },
      "destination": {
        "server": "https://kubernetes.default.svc",
        "namespace": "default"
      },
      "syncPolicy": {
        "automated": {"prune": true, "selfHeal": true},
        "syncOptions": ["CreateNamespace=true"]
      }
    }
  }'
```

### Sync Application via API

```bash
curl -X POST -H "Authorization: Bearer $ARGOCD_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  "https://$ARGOCD_SERVER/api/v1/applications/myapp/sync" \
  -d '{
    "revision": "HEAD",
    "prune": true,
    "dryRun": false,
    "strategy": {"hook": {}},
    "syncOptions": {"items": ["CreateNamespace=true"]}
  }'
```

### Get Application Status

```bash
curl -s -H "Authorization: Bearer $ARGOCD_AUTH_TOKEN" \
  "https://$ARGOCD_SERVER/api/v1/applications/myapp" | \
  jq '{name: .metadata.name, health: .status.health.status, sync: .status.sync.status}'
```

## Application Spec Reference

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argo-deployments
  finalizers:
    - resources-finalizer.argo-deployments.argoproj.io
spec:
  project: default

  source:
    repoURL: https://github.com/org/repo.git
    targetRevision: HEAD
    path: manifests

    # Helm options
    helm:
      releaseName: my-release
      valueFiles: [values.yaml, values-prod.yaml]
      parameters:
        - name: image.tag
          value: v1.0.0

    # Kustomize options
    kustomize:
      namePrefix: prod-
      images: [gcr.io/image:v1.0.0]

  destination:
    server: https://kubernetes.default.svc
    namespace: default

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
      - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m

  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers: [/spec/replicas]
```

## ApplicationSet Generators

See `references/api-reference.md` for complete generator patterns.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: cluster-apps
  namespace: argo-deployments
spec:
  generators:
    # List generator
    - list:
        elements:
          - cluster: dev
            url: https://dev.example.com
          - cluster: prod
            url: https://prod.example.com

    # Cluster generator
    - clusters:
        selector:
          matchLabels:
            environment: production

    # Git directory generator
    - git:
        repoURL: https://github.com/org/apps.git
        directories:
          - path: apps/*

    # Matrix generator (combine two generators)
    - matrix:
        generators:
          - clusters: {}
          - git:
              repoURL: https://github.com/org/apps.git
              directories: [{path: apps/*}]

  template:
    metadata:
      name: '{{.cluster}}-{{.path.basename}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/org/apps.git
        targetRevision: HEAD
        path: '{{.path.path}}'
      destination:
        server: '{{.url}}'
        namespace: '{{.path.basename}}'
```

## Sync Options Reference

| Option | Description |
|--------|-------------|
| `Prune=true` | Delete resources not in Git |
| `PruneLast=true` | Prune after sync completes |
| `Replace=true` | Use replace instead of apply |
| `ServerSideApply=true` | Use server-side apply |
| `CreateNamespace=true` | Create namespace if missing |
| `ApplyOutOfSyncOnly=true` | Only sync changed resources |
| `Validate=false` | Skip kubectl validation |
| `Force=true` | Force resource replacement |
| `RespectIgnoreDifferences=true` | Respect ignoreDifferences on sync |

## Resource Hooks and Waves

```yaml
metadata:
  annotations:
    # Sync wave (lower = earlier)
    argocd.argoproj.io/sync-wave: "-1"

    # Hook phase
    argocd.argoproj.io/hook: PreSync|Sync|PostSync|SyncFail|PostDelete

    # Hook deletion policy
    argocd.argoproj.io/hook-delete-policy: HookSucceeded|HookFailed|BeforeHookCreation
```

## Health Status Values

| Status | Description |
|--------|-------------|
| `Healthy` | Resource running correctly |
| `Progressing` | Deployment in progress |
| `Degraded` | Health check failed |
| `Suspended` | Resource paused |
| `Missing` | Resource doesn't exist |
| `Unknown` | Cannot determine health |

## CLI Global Flags

| Flag | Description |
|------|-------------|
| `--server` | ArgoCD server address |
| `--auth-token` | Bearer token |
| `--grpc-web` | Use gRPC-web (for proxies) |
| `--insecure` | Skip TLS verification |
| `--plaintext` | Disable TLS |
| `--config` | Config file path |
| `-o json/yaml/wide` | Output format |

## Error Handling

```bash
# Check if app exists before operations
if argo-deployments app get myapp &>/dev/null; then
  argo-deployments app sync myapp
else
  argo-deployments app create myapp ...
fi

# Wait with timeout and handle failure
if ! argo-deployments app wait myapp --health --timeout 300; then
  echo "App failed to become healthy"
  argo-deployments app get myapp
  exit 1
fi

# Idempotent upsert pattern
argo-deployments app create myapp --upsert ...
argo-deployments repo add https://repo --upsert ...
```

## Common Workflows

### Deploy and Wait Pattern

```bash
argo-deployments app sync myapp --prune --async
argo-deployments app wait myapp --health --sync --timeout 300
```

### Canary/Blue-Green with Argo Rollouts

```bash
# Promote rollout
argo-deployments app actions run myapp promote --kind Rollout --resource-name my-rollout
```

### Multi-Cluster Deployment

```bash
# Register clusters
argo-deployments cluster add dev-context --name dev
argo-deployments cluster add prod-context --name prod

# Use ApplicationSet with cluster generator
```

For complete API endpoint documentation, see `references/api-reference.md`.
For complete CLI command reference, see `references/cli-reference.md`.
