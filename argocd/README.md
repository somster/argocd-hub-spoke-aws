# ArgoCD GitOps Bootstrap Templates

This folder contains bootstrap templates for a simple multi-environment GitOps layout.

## Structure

- apps/dev: Deployable sample workload for development.
- apps/test: Placeholder Kustomize base for test.
- apps/prod: Placeholder Kustomize base for prod.
- projects/platform-project.yaml: ArgoCD project scope.
- applications/platform-appset.yaml: ApplicationSet generating one ArgoCD Application per environment.

## Required Placeholders

Update these values before using:

- `repoURL` in `applications/platform-appset.yaml`
- `sourceRepos` in `projects/platform-project.yaml`

## Post-Deploy Validation

After the cluster and EKS ArgoCD capability have been deployed by an operator, use the following workflow to confirm ArgoCD is actually working.

### 1. Confirm the EKS capability exists

Run:

```bash
aws eks describe-capability \
	--cluster-name <cluster_name> \
	--capability-name argocd \
	--region <region>
```

What to look for:

- The capability is returned successfully.
- A version is present.
- The ArgoCD server URL is present in the response.

### 2. Confirm ArgoCD components exist in the cluster

First update kubeconfig:

```bash
aws eks update-kubeconfig --name <cluster_name> --region <region>
```

Then inspect the ArgoCD namespace:

```bash
kubectl get ns argocd
kubectl get pods -n argocd
kubectl get svc -n argocd
```

What to look for:

- Namespace `argocd` exists.
- ArgoCD control plane pods are in `Running` or `Completed` state.
- A service is exposed for the ArgoCD API/server.

### 3. Confirm ArgoCD can see the GitOps definitions

Apply or register the project and ApplicationSet definitions only after the operator has finished provisioning the cluster and access is working.

Files to use:

- `projects/platform-project.yaml`
- `applications/platform-appset.yaml`

Then validate:

```bash
kubectl get applicationsets -n argocd
kubectl get applications -n argocd
```

What to look for:

- `platform-appset` exists.
- ArgoCD Applications are generated for `dev`, `test`, and `prod`.

### 4. Confirm ArgoCD reports healthy sync state

If ArgoCD CLI is available:

```bash
argocd app list
argocd app get dev-platform-app
```

If CLI is not available, inspect the Kubernetes resources:

```bash
kubectl get applications -n argocd -o wide
kubectl describe application dev-platform-app -n argocd
```

What to look for:

- Sync status is `Synced`.
- Health status is `Healthy`.
- No repeated reconciliation or repo access errors are shown in events.

## Deployment Test Workflow

Use the sample guestbook workload under `apps/dev` as the first smoke test.

### 1. Test initial deployment

Confirm the generated application created the namespace and workload:

```bash
kubectl get ns guestbook-dev
kubectl get deploy,po,svc -n guestbook-dev
```

Expected result:

- Namespace `guestbook-dev` exists.
- Deployment `guestbook` exists.
- Two pods become `Running`.
- Service `guestbook` exists.

### 2. Test a GitOps change

Make a small change in Git, for example in `apps/dev/guestbook/deployment.yaml`:

- change replicas from `2` to `3`, or
- change the container image tag to another valid nginx tag.

Commit and push the change, then verify ArgoCD reconciles it.

Check ArgoCD status:

```bash
kubectl get application dev-platform-app -n argocd -o yaml
kubectl rollout status deployment/guestbook -n guestbook-dev
kubectl get pods -n guestbook-dev
```

Expected result:

- ArgoCD detects the Git revision change.
- The application returns to `Synced` and `Healthy`.
- The deployment rolls out successfully.
- The live cluster matches the desired Git state.

### 3. Test self-heal behavior

After the application is healthy, introduce drift manually:

```bash
kubectl scale deployment/guestbook -n guestbook-dev --replicas=1
kubectl get deployment guestbook -n guestbook-dev -w
```

Expected result:

- ArgoCD detects drift.
- Replica count is reconciled back to the Git-defined value.

### 4. Test failure visibility

Intentionally push a bad image tag to `apps/dev/guestbook/deployment.yaml`.

Then check:

```bash
kubectl describe application dev-platform-app -n argocd
kubectl get pods -n guestbook-dev
kubectl describe pod -n guestbook-dev <failing-pod-name>
```

Expected result:

- Application health degrades.
- Pods show image pull or startup failure.
- ArgoCD surfaces the failure instead of falsely reporting healthy state.

## Minimum Success Criteria

Treat ArgoCD as working only if all of the following are true:

- The EKS ArgoCD capability is returned successfully by AWS.
- The ArgoCD control plane is running in the cluster.
- The ApplicationSet generates applications from the Git repo.
- A Git commit produces a matching rollout in the cluster.
- Manual drift is corrected automatically.
- A broken deployment becomes visibly unhealthy.
