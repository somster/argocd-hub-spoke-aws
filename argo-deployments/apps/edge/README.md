# Edge Helm app

Single-path Helm application for spoke deployment via the hub `workloads` `ApplicationSet`.

This chart deploys:
- Kong ingress controller (DB-less) via chart dependency.

## Why this layout

The hub `workloads` `ApplicationSet` tracks one repo path per spoke workload app. This folder is dedicated to Kong (`apps/edge`).

The hello-world workload is managed separately from:

`apps/local-sync`

## Local render test

```bash
helm dependency build /Users/somnath.kapoor/vibes/argo-greenfield/argo-deployments/apps/edge
helm template edge /Users/somnath.kapoor/vibes/argo-greenfield/argo-deployments/apps/edge
```

## Path to configure on cluster annotations

Set workload repo path annotation to point at:

`apps/edge`

