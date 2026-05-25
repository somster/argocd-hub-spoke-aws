# EKS LoadBalancer Learning: Classic ELB with No Targets vs NLB with IP Targets

Date: 2026-05-15

## Context

We deployed the `helm-guestbook` app from `argoproj/argocd-example-apps` via Argo CD.
The chart production values set only:

- `service.type: LoadBalancer`

On this cluster (`test-cluster`), that initially created a Classic ELB with no registered targets.

## Observed Symptoms

- Kubernetes Service was healthy and had endpoints.
- Pod was running and ready.
- Service events showed:
  - `EnsuringLoadBalancer`
  - `EnsuredLoadBalancer`
- AWS side showed Classic ELB with:
  - `Instances: []`
  - `InstanceStates: []`

## Root Cause

The Service was using a legacy LoadBalancer path (Classic ELB behavior) instead of explicit EKS Auto Mode NLB settings.

Important: `spec.loadBalancerClass` is immutable after Service creation. It cannot be patched in place.

## What Worked

We did not change upstream chart code. Instead we used an Argo CD-side approach:

1. Added `ignoreDifferences` and `RespectIgnoreDifferences=true` in the Argo CD Application for LB-specific Service fields.
2. Recreated the Service (same name) with explicit NLB settings:
   - `spec.loadBalancerClass: eks.amazonaws.com/nlb`
   - `service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing`
   - `service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip`

## Verification Evidence

After recreate:

- New ELB hostname pattern was NLB/ELBv2 style.
- AWS `elbv2 describe-load-balancers` returned:
  - `Type: network`
  - `Scheme: internet-facing`
- Target group showed:
  - `TargetType: ip`
- Target health progressed from:
  - `initial / Elb.RegistrationInProgress`
  - to `healthy`

## Key Takeaways

- `service.type: LoadBalancer` alone is not always deterministic for desired AWS LB behavior.
- On EKS Auto Mode clusters, set `loadBalancerClass` explicitly when deterministic behavior is required.
- If migrating an existing Service, delete/recreate may be required due to immutable `loadBalancerClass`.
- Keep upstream chart untouched when needed by applying Argo CD-level overlays/patch strategies.

## AWS Documentation Used

- EKS Auto Mode NLB service configuration:
  - https://docs.aws.amazon.com/eks/latest/userguide/auto-configure-nlb.html
- EKS network load balancing guidance:
  - https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html
- ALB and Load Balancer Controller prerequisites:
  - https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
