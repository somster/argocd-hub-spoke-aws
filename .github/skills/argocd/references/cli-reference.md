# ArgoCD CLI Reference

Complete command reference for the `argocd` CLI (v3.0+).

**Important**: This reference documents the latest stable ArgoCD CLI. Commands and flags may vary in older versions. Always verify compatibility with your deployed ArgoCD version.

## Version Management

Before using the ArgoCD CLI, ensure you're running the latest stable version:

```bash
# Check your current CLI version
argo-deployments version

# Get latest stable ArgoCD version
LATEST_VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases | \
  jq -r '.[] | select(.prerelease==false) | .tag_name' | head -1)

# Update instructions
# Visit https://github.com/argoproj/argo-cd/releases for latest binaries
```

**Recommendation**: Keep your `argocd` CLI version aligned with your deployed ArgoCD server version to avoid compatibility issues.

## Global Flags

| Flag | Description |
|------|-------------|
| `--server string` | ArgoCD server address |
| `--auth-token string` | Bearer token for authentication |
| `--client-crt string` | Client certificate file |
| `--client-crt-key string` | Client certificate key file |
| `--config string` | Path to ArgoCD config (default ~/.argocd/config) |
| `--core` | Use direct Kubernetes API (no argocd-server) |
| `--grpc-web` | Use gRPC-web protocol (for proxies/ingress) |
| `--grpc-web-root-path string` | gRPC-web root path override |
| `--header strings` | Additional headers (can be repeated) |
| `--http-retry-max int` | Max HTTP retries (default 0) |
| `--insecure` | Skip TLS verification |
| `--kube-context string` | Kubernetes context (for --core mode) |
| `--logformat string` | Log format (text, json) |
| `--loglevel string` | Log level (debug, info, warn, error) |
| `--plaintext` | Disable TLS |
| `--port-forward` | Connect via port-forward |
| `--port-forward-namespace string` | Namespace for port-forward |
| `--redis-haproxy-name string` | Redis HA proxy service name |
| `--redis-name string` | Redis service name |
| `--server-crt string` | Server certificate file |

## Authentication Commands

### argocd login

```bash
argo-deployments login SERVER [flags]

# Interactive login
argo-deployments login argo-deployments.example.com

# Non-interactive
argo-deployments login argo-deployments.example.com --username admin --password secret

# With SSO
argo-deployments login argo-deployments.example.com --sso

# Skip TLS
argo-deployments login argo-deployments.example.com --insecure

Flags:
  --grpc-web               Use gRPC-web
  --insecure               Skip TLS verification
  --name string            Context name override
  --password string        Password
  --plaintext              Disable TLS
  --skip-test-tls          Skip TLS test
  --sso                    Perform SSO login
  --sso-port int           Port for SSO callback (default 8085)
  --username string        Username
```

### argocd logout

```bash
argo-deployments logout SERVER [flags]
```

### argocd relogin

```bash
argo-deployments relogin [flags]

# Refresh SSO session
argo-deployments relogin --sso
```

### argocd context

```bash
# List contexts
argo-deployments context

# Switch context
argo-deployments context myserver

# Delete context
argo-deployments context myserver --delete
```

## Application Commands

### argocd app create

```bash
argo-deployments app create NAME [flags]

# From Git repo
argo-deployments app create myapp \
  --repo https://github.com/org/repo.git \
  --path manifests \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# With Helm
argo-deployments app create myapp \
  --repo https://charts.example.com \
  --helm-chart mychart \
  --revision 1.0.0 \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --helm-set image.tag=v1.0.0 \
  --values-literal-file values.yaml

# With Kustomize
argo-deployments app create myapp \
  --repo https://github.com/org/repo.git \
  --path kustomize/overlays/prod \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --kustomize-image gcr.io/image:v1.0.0

# With auto-sync
argo-deployments app create myapp \
  --repo https://github.com/org/repo.git \
  --path manifests \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated \
  --auto-prune \
  --self-heal \
  --sync-option CreateNamespace=true

Flags:
  --allow-empty                    Allow empty resources
  --annotations stringArray        Annotations (key=value)
  --auto-prune                     Enable auto-prune
  --config-management-plugin string Plugin name
  --core                           Use core mode
  --dest-name string               Destination cluster name
  --dest-namespace string          Destination namespace
  --dest-server string             Destination server URL
  --directory-exclude string       Directory exclude pattern
  --directory-include string       Directory include pattern
  --directory-recurse              Recurse directories
  --env string                     Environment
  --file string                    Create from file
  --grpc-web                       Use gRPC-web
  --helm-chart string              Helm chart name
  --helm-pass-credentials          Pass credentials to Helm
  --helm-set stringArray           Helm set values
  --helm-set-file stringArray      Helm set file values
  --helm-set-string stringArray    Helm set string values
  --helm-skip-crds                 Skip CRDs
  --helm-version string            Helm version
  --ignore-missing-value-files     Ignore missing value files
  --jsonnet-ext-var stringArray    Jsonnet ext vars
  --jsonnet-libs stringArray       Jsonnet libs
  --jsonnet-tla-code stringArray   Jsonnet TLA code
  --jsonnet-tla-str stringArray    Jsonnet TLA strings
  --kustomize-common-annotation stringArray Common annotations
  --kustomize-common-label stringArray Common labels
  --kustomize-force-common-annotation Force common annotations
  --kustomize-force-common-label   Force common labels
  --kustomize-image stringArray    Kustomize images
  --kustomize-namespace string     Kustomize namespace
  --kustomize-replica stringArray  Kustomize replicas
  --kustomize-version string       Kustomize version
  --label stringArray              Labels (key=value)
  --name string                    Application name
  --nameprefix string              Kustomize name prefix
  --namesuffix string              Kustomize name suffix
  --path string                    Path within repo
  --plugin-env stringArray         Plugin env vars
  --project string                 Project (default "default")
  --ref string                     Source ref
  --release-name string            Helm release name
  --repo string                    Repository URL
  --revision string                Revision (default "HEAD")
  --revision-history-limit int     Revision history limit
  --self-heal                      Enable self-heal
  --set-finalizer                  Set finalizer
  --sync-option stringArray        Sync options
  --sync-policy string             Sync policy (none, automated)
  --sync-retry-backoff-duration string Retry backoff duration
  --sync-retry-backoff-factor int  Retry backoff factor
  --sync-retry-backoff-max-duration string Max retry duration
  --sync-retry-limit int           Retry limit
  --upsert                         Update if exists
  --validate                       Validate manifests
  --values stringArray             Helm values files
  --values-literal-file string     Values from file
```

### argocd app get

```bash
argo-deployments app get APPNAME [flags]

# Get app details
argo-deployments app get myapp

# JSON output
argo-deployments app get myapp -o json

# Wide output (shows all resources)
argo-deployments app get myapp -o wide

# YAML output
argo-deployments app get myapp -o yaml

# Show operation info
argo-deployments app get myapp --show-operation

# Show params
argo-deployments app get myapp --show-params

Flags:
  --hard-refresh         Force refresh from source
  -o, --output string    Output format (json, yaml, wide)
  --refresh              Refresh app first
  --show-operation       Show last operation
  --show-params          Show parameters
```

### argocd app list

```bash
argo-deployments app list [flags]

# List all apps
argo-deployments app list

# Filter by project
argo-deployments app list -p myproject

# Filter by label
argo-deployments app list -l app=myapp

# JSON output
argo-deployments app list -o json

# Filter by cluster
argo-deployments app list --cluster production

Flags:
  --app-namespace string    App namespace
  -c, --cluster string      Filter by cluster
  -l, --selector string     Label selector
  -o, --output string       Output format (wide, name, json, yaml)
  -p, --project stringArray Project filter
  -r, --repo string         Repository filter
```

### argocd app sync

```bash
argo-deployments app sync APPNAME [flags]

# Basic sync
argo-deployments app sync myapp

# Sync with prune
argo-deployments app sync myapp --prune

# Force sync (recreate resources)
argo-deployments app sync myapp --force

# Dry run
argo-deployments app sync myapp --dry-run

# Sync specific revision
argo-deployments app sync myapp --revision v1.0.0

# Sync specific resources
argo-deployments app sync myapp --resource apps:Deployment:nginx
argo-deployments app sync myapp --resource :Service:nginx --resource apps:Deployment:nginx

# Async sync (don't wait)
argo-deployments app sync myapp --async

# Sync with retry
argo-deployments app sync myapp --retry-limit 5 --retry-backoff-duration 5s

# Preview sync diff
argo-deployments app sync myapp --preview-changes

Flags:
  --apply-out-of-sync-only     Only sync out-of-sync resources
  --async                       Don't wait for completion
  --assumeYes                   Assume yes on prompts
  --dry-run                     Preview without applying
  --force                       Force resource deletion/recreation
  --info stringArray            Sync info (key=value)
  --label stringArray           Filter resources by label
  --local string                Sync from local path
  --local-repo-root string      Local repo root
  --preview-changes             Preview changes
  --prune                       Delete resources not in Git
  --replace                     Use replace instead of apply
  --resource stringArray        Sync specific resources (group:kind:name)
  --retry-backoff-duration duration Retry duration (default 5s)
  --retry-backoff-factor int    Retry factor (default 2)
  --retry-backoff-max-duration duration Max retry duration (default 3m)
  --retry-limit int             Retry limit
  --revision string             Sync to revision
  --server-side                 Server-side apply
  --strategy string             Sync strategy (apply, hook)
  --timeout uint                Timeout in seconds
```

### argocd app wait

```bash
argo-deployments app wait APPNAME [flags]

# Wait for sync and health
argo-deployments app wait myapp

# Wait for health only
argo-deployments app wait myapp --health

# Wait for sync only
argo-deployments app wait myapp --sync

# Wait for operation
argo-deployments app wait myapp --operation

# With timeout
argo-deployments app wait myapp --health --timeout 300

# Wait for suspended
argo-deployments app wait myapp --suspended

Flags:
  --degraded           Wait for degraded
  --health             Wait for healthy
  --operation          Wait for operation
  --resource stringArray Wait for specific resources
  --suspended          Wait for suspended
  --sync               Wait for synced
  --timeout uint       Timeout in seconds
```

### argocd app delete

```bash
argo-deployments app delete APPNAME [flags]

# Delete app and resources
argo-deployments app delete myapp

# Delete without confirmation
argo-deployments app delete myapp -y

# Keep resources (orphan)
argo-deployments app delete myapp --cascade=false

# Force delete
argo-deployments app delete myapp --cascade --propagation-policy foreground

Flags:
  --cascade                Delete resources (default true)
  --propagation-policy string Propagation policy (foreground, background, orphan)
  -y, --yes                 Skip confirmation
```

### argocd app history

```bash
argo-deployments app history APPNAME [flags]

# Show deployment history
argo-deployments app history myapp

# JSON output
argo-deployments app history myapp -o json

Flags:
  -o, --output string   Output format (wide, id, json)
```

### argocd app rollback

```bash
argo-deployments app rollback APPNAME ID [flags]

# Rollback to history ID
argo-deployments app rollback myapp 2

# Dry run
argo-deployments app rollback myapp 2 --dry-run

# Prune on rollback
argo-deployments app rollback myapp 2 --prune

Flags:
  --dry-run   Preview without applying
  --prune     Delete extra resources
  --timeout uint Timeout in seconds
```

### argocd app diff

```bash
argo-deployments app diff APPNAME [flags]

# Show diff
argo-deployments app diff myapp

# Diff against revision
argo-deployments app diff myapp --revision v1.0.0

# Local diff
argo-deployments app diff myapp --local ./manifests

# Quiet (exit code only)
argo-deployments app diff myapp --exit-code

Flags:
  --exit-code           Use exit code for result
  --hard-refresh        Force refresh
  --local string        Local manifests path
  --local-repo-root string Local repo root
  --refresh             Refresh first
  --revision string     Compare revision
  --server-side-generate Server-side manifest generation
```

### argocd app logs

```bash
argo-deployments app logs APPNAME [flags]

# Get logs
argo-deployments app logs myapp

# Follow logs
argo-deployments app logs myapp -f

# Specific container
argo-deployments app logs myapp --container nginx

# Specific pod
argo-deployments app logs myapp --name nginx-xxx

# Filter by group/kind
argo-deployments app logs myapp --group apps --kind Deployment

# Tail lines
argo-deployments app logs myapp --tail 100

# Since time
argo-deployments app logs myapp --since-time 2023-01-01T00:00:00Z
argo-deployments app logs myapp --since 1h

Flags:
  --container string    Container name
  -f, --follow          Follow logs
  --group string        Resource group
  --kind string         Resource kind
  --name string         Pod name
  --namespace string    Resource namespace
  --previous            Previous container instance
  --since duration      Since duration (e.g., 1h)
  --since-time string   Since time (RFC3339)
  --tail int            Tail lines (default -1, all)
  --timestamps          Show timestamps
```

### argocd app set

```bash
argo-deployments app set APPNAME [flags]

# Change target revision
argo-deployments app set myapp --revision v1.0.0

# Change sync policy
argo-deployments app set myapp --sync-policy automated

# Set Helm values
argo-deployments app set myapp --helm-set image.tag=v2.0.0

# Add sync option
argo-deployments app set myapp --sync-option Prune=true

Flags:
  # Same as app create, allows updating any setting
```

### argocd app unset

```bash
argo-deployments app unset APPNAME [flags]

# Remove Helm parameter
argo-deployments app unset myapp --parameter image.tag

# Remove values file
argo-deployments app unset myapp --values values-override.yaml

Flags:
  --ignore-missing-value-files
  --jsonnet-ext-var-code stringArray
  --jsonnet-ext-var stringArray
  --jsonnet-tla-code stringArray
  --jsonnet-tla-str stringArray
  --kustomize-image stringArray
  --name-prefix
  --name-suffix
  --parameter stringArray
  --pass-credentials
  --plugin-env stringArray
  --values stringArray
```

### argocd app resources

```bash
argo-deployments app resources APPNAME [flags]

# List resources
argo-deployments app resources myapp

Flags:
  --orphaned            Show orphaned resources only
  -o, --output string   Output format (wide, tree, json)
```

### argocd app manifests

```bash
argo-deployments app manifests APPNAME [flags]

# Get live manifests
argo-deployments app manifests myapp

# Get source manifests
argo-deployments app manifests myapp --source live

# Get specific revision
argo-deployments app manifests myapp --revision v1.0.0

Flags:
  --local string        Local path
  --local-repo-root string Local repo root
  --revision string     Revision
  --source string       Source (live, git)
```

### argocd app patch

```bash
argo-deployments app patch APPNAME [flags]

# Patch application
argo-deployments app patch myapp --patch '{"spec":{"source":{"targetRevision":"v1.0.0"}}}'

# Patch from file
argo-deployments app patch myapp --patch-file patch.json

Flags:
  --patch string        JSON/YAML patch
  --patch-file string   Patch file
  --type string         Patch type (json, merge, strategic)
```

### argocd app terminate-op

```bash
argo-deployments app terminate-op APPNAME [flags]

# Terminate running operation
argo-deployments app terminate-op myapp
```

### argocd app actions

```bash
# List available actions
argo-deployments app actions list myapp --kind Deployment

# Run action
argo-deployments app actions run myapp restart --kind Deployment --resource-name nginx --namespace default

# Disable action
argo-deployments app actions run myapp disable --kind Rollout --resource-name canary
```

## ApplicationSet Commands

### argocd appset create

```bash
argo-deployments appset create FILE [flags]

# Create from file
argo-deployments appset create appset.yaml

# Upsert
argo-deployments appset create appset.yaml --upsert

Flags:
  --upsert   Update if exists
```

### argocd appset get

```bash
argo-deployments appset get NAME [flags]

# Get details
argo-deployments appset get myappset

# YAML output
argo-deployments appset get myappset -o yaml

Flags:
  -o, --output string   Output format (json, yaml)
```

### argocd appset list

```bash
argo-deployments appset list [flags]

# List all
argo-deployments appset list

# Filter by project
argo-deployments appset list -p myproject

Flags:
  -o, --output string   Output format (wide, json, yaml)
  -p, --project stringArray Project filter
  -l, --selector string Label selector
```

### argocd appset delete

```bash
argo-deployments appset delete NAME [flags]

# Delete
argo-deployments appset delete myappset

# Without confirmation
argo-deployments appset delete myappset -y

Flags:
  -y, --yes   Skip confirmation
```

## Project Commands

### argocd proj create

```bash
argo-deployments proj create NAME [flags]

# Create project
argo-deployments proj create myproject \
  -d https://kubernetes.default.svc,default \
  -s https://github.com/org/*

Flags:
  --allow-cluster-resource stringArray Allow cluster resources
  --allow-namespaced-resource stringArray Allow namespaced resources
  --deny-cluster-resource stringArray Deny cluster resources
  --deny-namespaced-resource stringArray Deny namespaced resources
  --description string    Description
  -d, --dest stringArray  Destinations (server,namespace)
  --orphaned-resources-warn Warn on orphaned resources
  --signature-keys stringArray GPG signature keys
  --source-namespaces stringArray Source namespaces
  -s, --src stringArray   Source repos
  --upsert                Update if exists
```

### argocd proj list

```bash
argo-deployments proj list [flags]

# List projects
argo-deployments proj list

# JSON output
argo-deployments proj list -o json

Flags:
  -o, --output string   Output format (wide, json, yaml, name)
```

### argocd proj get

```bash
argo-deployments proj get NAME [flags]

# Get project
argo-deployments proj get myproject

Flags:
  -o, --output string   Output format (json, yaml)
```

### argocd proj edit

```bash
# Open in editor
argo-deployments proj edit myproject
```

### argocd proj delete

```bash
argo-deployments proj delete NAME [flags]

# Delete project
argo-deployments proj delete myproject
```

### argocd proj add-destination

```bash
argo-deployments proj add-destination PROJECT SERVER NAMESPACE [flags]

# Add destination
argo-deployments proj add-destination myproject https://kubernetes.default.svc 'team-*'

# Add by cluster name
argo-deployments proj add-destination myproject production default --name
```

### argocd proj remove-destination

```bash
argo-deployments proj remove-destination PROJECT SERVER NAMESPACE
```

### argocd proj add-source

```bash
argo-deployments proj add-source PROJECT URL

# Add source repo
argo-deployments proj add-source myproject 'https://github.com/org/*'
```

### argocd proj remove-source

```bash
argo-deployments proj remove-source PROJECT URL
```

### argocd proj role create

```bash
argo-deployments proj role create PROJECT ROLE

# Create role
argo-deployments proj role create myproject developer
```

### argocd proj role delete

```bash
argo-deployments proj role delete PROJECT ROLE
```

### argocd proj role add-policy

```bash
argo-deployments proj role add-policy PROJECT ROLE [flags]

# Add policy
argo-deployments proj role add-policy myproject developer \
  -a sync -p allow -o '*'

# Add get permission
argo-deployments proj role add-policy myproject developer \
  -a get -p allow -o '*'

Flags:
  -a, --action string     Action (get, sync, override, delete)
  -o, --object string     Object pattern
  -p, --permission string Permission (allow, deny)
```

### argocd proj role remove-policy

```bash
argo-deployments proj role remove-policy PROJECT ROLE [flags]
```

### argocd proj role add-group

```bash
argo-deployments proj role add-group PROJECT ROLE GROUP

# Add SSO group
argo-deployments proj role add-group myproject developer team-developers
```

### argocd proj role remove-group

```bash
argo-deployments proj role remove-group PROJECT ROLE GROUP
```

### argocd proj role create-token

```bash
argo-deployments proj role create-token PROJECT ROLE [flags]

# Create token
argo-deployments proj role create-token myproject developer --expires-in 24h

Flags:
  --expires-in duration   Token expiration
  --id string            Token ID
```

### argocd proj role delete-token

```bash
argo-deployments proj role delete-token PROJECT ROLE IAT
```

### argocd proj windows add

```bash
argo-deployments proj windows add PROJECT [flags]

# Add sync window
argo-deployments proj windows add myproject \
  --kind allow \
  --schedule "0 22 * * *" \
  --duration 2h \
  --applications '*'

Flags:
  --applications stringArray Apps to match
  --clusters stringArray     Clusters to match
  --duration string          Window duration
  --kind string              Kind (allow, deny)
  --manual-sync              Allow manual sync
  --namespaces stringArray   Namespaces to match
  --schedule string          Cron schedule
  --time-zone string         Timezone
```

### argocd proj windows delete

```bash
argo-deployments proj windows delete PROJECT ID
```

### argocd proj windows list

```bash
argo-deployments proj windows list PROJECT
```

### argocd proj windows update

```bash
argo-deployments proj windows update PROJECT ID [flags]
```

## Repository Commands

### argocd repo add

```bash
argo-deployments repo add REPOURL [flags]

# HTTPS with token
argo-deployments repo add https://github.com/org/repo --username git --password $TOKEN

# SSH with key
argo-deployments repo add git@github.com:org/repo.git --ssh-private-key-path ~/.ssh/id_rsa

# GitHub App
argo-deployments repo add https://github.com/org/repo \
  --github-app-id 12345 \
  --github-app-installation-id 67890 \
  --github-app-private-key-path key.pem

# Helm repo
argo-deployments repo add https://charts.example.com --type helm --name stable

# OCI registry
argo-deployments repo add registry.example.com --type helm --enable-oci

Flags:
  --enable-lfs               Enable Git LFS
  --enable-oci               Enable OCI
  --force-http-basic-auth    Force HTTP basic auth
  --github-app-enterprise-base-url string GHE URL
  --github-app-id int        GitHub App ID
  --github-app-installation-id int GitHub App Installation ID
  --github-app-private-key-path string GitHub App key path
  --insecure-skip-server-verification Skip TLS verify
  --name string              Repository name
  --password string          Password/token
  --project string           Project
  --proxy string             Proxy URL
  --ssh-private-key-path string SSH key path
  --tls-client-cert-data string TLS cert
  --tls-client-cert-key string TLS key
  --type string              Type (git, helm)
  --upsert                   Update if exists
  --username string          Username
```

### argocd repo list

```bash
argo-deployments repo list [flags]

Flags:
  -o, --output string   Output format (url, json, yaml)
  --refresh             Refresh repos
```

### argocd repo get

```bash
argo-deployments repo get REPOURL [flags]
```

### argocd repo rm

```bash
argo-deployments repo rm REPOURL [flags]
```

### argocd repocreds add

```bash
argo-deployments repocreds add URLPREFIX [flags]

# Add credential template
argo-deployments repocreds add https://github.com/myorg/ --username git --password $TOKEN

# SSH credentials
argo-deployments repocreds add git@github.com:myorg/ --ssh-private-key-path ~/.ssh/id_rsa
```

### argocd repocreds list

```bash
argo-deployments repocreds list
```

### argocd repocreds rm

```bash
argo-deployments repocreds rm URLPREFIX
```

## Cluster Commands

### argocd cluster add

```bash
argo-deployments cluster add CONTEXT [flags]

# Add from kubeconfig context
argo-deployments cluster add my-context

# With custom name
argo-deployments cluster add my-context --name production

# To specific project
argo-deployments cluster add my-context --project myproject

# With namespace restrictions
argo-deployments cluster add my-context --namespace default --namespace app

# With labels
argo-deployments cluster add my-context --label environment=production

Flags:
  --annotation stringArray Annotations
  --aws-cluster-name string AWS EKS cluster name
  --aws-role-arn string  AWS role ARN
  --cluster-endpoint string Cluster endpoint override
  --in-cluster          In-cluster service account
  --kubeconfig string   Kubeconfig path
  --label stringArray   Labels
  --name string         Cluster name
  --namespace stringArray Namespaces
  --project string      Project
  --shard int           Shard number
  --system-namespace string System namespace
  --upsert              Update if exists
```

### argocd cluster list

```bash
argo-deployments cluster list [flags]

Flags:
  -o, --output string   Output format (wide, server, json, yaml)
```

### argocd cluster get

```bash
argo-deployments cluster get SERVER [flags]

Flags:
  -o, --output string   Output format (json, yaml)
```

### argocd cluster rm

```bash
argo-deployments cluster rm SERVER [flags]

Flags:
  -y, --yes   Skip confirmation
```

### argocd cluster rotate-auth

```bash
argo-deployments cluster rotate-auth SERVER [flags]

# Rotate credentials
argo-deployments cluster rotate-auth https://production.example.com
```

## Account Commands

### argocd account list

```bash
argo-deployments account list [flags]

Flags:
  -o, --output string   Output format (wide, json)
```

### argocd account get

```bash
argo-deployments account get [USERNAME] [flags]

# Get current user
argo-deployments account get

# Get specific user
argo-deployments account get admin

Flags:
  -o, --output string   Output format (json, yaml)
```

### argocd account generate-token

```bash
argo-deployments account generate-token [flags]

# Generate for current account
argo-deployments account generate-token

# For specific account
argo-deployments account generate-token --account cibot

# With expiration
argo-deployments account generate-token --account cibot --expires-in 7d

# With ID
argo-deployments account generate-token --account cibot --id deploy-token

Flags:
  --account string      Account name
  --expires-in duration Token expiration
  --id string           Token ID
```

### argocd account update-password

```bash
argo-deployments account update-password [flags]

# Update current password
argo-deployments account update-password

# Update specific account
argo-deployments account update-password --account admin

Flags:
  --account string      Account name
  --current-password string Current password
  --new-password string New password
```

### argocd account can-i

```bash
argo-deployments account can-i ACTION RESOURCE SUBRESOURCE [flags]

# Check sync permission
argo-deployments account can-i sync applications '*'

# Check specific app
argo-deployments account can-i get applications 'myproject/myapp'

# Check cluster resource
argo-deployments account can-i update clusters '*'
```

### argocd account get-user-info

```bash
argo-deployments account get-user-info [flags]

Flags:
  -o, --output string   Output format (json, yaml)
```

### argocd account bcrypt

```bash
argo-deployments account bcrypt --password PASSWORD

# Generate bcrypt hash
argo-deployments account bcrypt --password mysecret
```

## Certificate Commands

### argocd cert add-ssh

```bash
# Add SSH known hosts
ssh-keyscan github.com | argo-deployments cert add-ssh --batch

# Add single host
argo-deployments cert add-ssh --from /path/to/known_hosts
```

### argocd cert add-tls

```bash
# Add TLS cert
argo-deployments cert add-tls cd.example.com --from /path/to/cert.pem
```

### argocd cert list

```bash
argo-deployments cert list [flags]

Flags:
  --cert-type string    Type (ssh, https)
  --hostname-pattern string Pattern
  -o, --output string   Output format (wide, json)
```

### argocd cert rm

```bash
argo-deployments cert rm HOSTNAME [flags]

Flags:
  --cert-type string    Type (ssh, https)
  --cert-sub-type string Sub-type
```

## GPG Commands

### argocd gpg add

```bash
argo-deployments gpg add --from /path/to/key.asc
```

### argocd gpg list

```bash
argo-deployments gpg list [flags]

Flags:
  -o, --output string   Output format (json, yaml)
```

### argocd gpg get

```bash
argo-deployments gpg get KEYID [flags]

Flags:
  -o, --output string   Output format (json, yaml)
```

### argocd gpg rm

```bash
argo-deployments gpg rm KEYID
```

## Admin Commands

### argocd admin initial-password

```bash
# Get initial admin password
argo-deployments admin initial-password -n argo-deployments
```

### argocd admin settings

```bash
# Validate RBAC
argo-deployments admin settings rbac validate --policy-file policy.csv

# Test RBAC
argo-deployments admin settings rbac can role:developer get applications '*/*'
```

### argocd admin cluster

```bash
# Generate cluster config
argo-deployments admin cluster generate-spec CONTEXT
```

### argocd admin export

```bash
# Export all resources
argo-deployments admin export > backup.yaml
```

### argocd admin import

```bash
# Import resources
argo-deployments admin import < backup.yaml
```

### argocd admin notifications

```bash
# Test notification template
argo-deployments admin notifications template get app-deployed

# List triggers
argo-deployments admin notifications trigger list
```

## Version Command

```bash
# Show client version
argo-deployments version

# Show client only
argo-deployments version --client

# JSON output
argo-deployments version -o json
```
