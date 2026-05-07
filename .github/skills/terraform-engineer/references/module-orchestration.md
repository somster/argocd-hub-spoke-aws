# Multi-Module Orchestration Patterns

Advanced patterns for organizing and orchestrating multiple Terraform modules to build cohesive infrastructure solutions.

## Problem Statement

As infrastructure grows, single-module designs become difficult to maintain:
- Mixed concerns in one module
- Unclear dependencies between resources
- Hard to test components independently
- Difficult to reuse or share modules across projects

## Solution: Hierarchical Module Architecture

Organize infrastructure into independent, layered modules orchestrated at the root level.

### Layered Pattern

```
root (orchestrator)
 ├── layer-1 (foundational)
 │    └── Base infrastructure (networking, storage, etc.)
 ├── layer-2 (middle)
 │    └── Identity, configuration, or middleware services
 └── layer-3 (application)
      └── Application workloads and services
```

**Benefits:**
- Clear separation of concerns
- Each module independently testable
- Explicit dependency declarations
- Easy to swap or upgrade individual layers
- Straightforward to add new modules (monitoring, logging, etc.)

## Implementation Pattern

### Root Level: Module Orchestration

```terraform
# root/main.tf - Orchestrate modules with explicit dependencies

module "layer_1" {
  source = "./layer-1"
  
  project_name = var.project_name
  environment  = var.environment
  region       = var.region
  tags         = var.tags
}

module "layer_2" {
  source = "./layer-2"
  
  configuration_param_1 = var.configuration_param_1
  configuration_param_2 = var.configuration_param_2
  region                = var.region
}

module "layer_3" {
  source = "./layer-3"
  
  # Must wait for layer_1 and layer_2 to complete
  depends_on = [module.layer_1, module.layer_2]
  
  # Pass layer_1 module outputs
  base_resource_id   = module.layer_1.base_resource_id
  base_resource_arn  = module.layer_1.base_resource_arn
  
  # Pass layer_2 module outputs
  identity_config = module.layer_2.identity_config
  
  # Direct inputs
  project_name  = var.project_name
  environment   = var.environment
  tags          = var.tags
}
```

### Root Level: Variable Pass-Through

```terraform
# root/variables.tf - Consolidate all module inputs

variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name (dev, staging, prod)"
}

variable "region" {
  type        = string
  description = "Cloud region"
}

variable "configuration_param_1" {
  type        = string
  description = "First configuration parameter passed to layer-2"
}

variable "configuration_param_2" {
  type        = string
  default     = ""
  description = "Optional configuration parameter for layer-2"
}

# ... more variables passed to submodules
```

### Root Level: Output Aggregation

```terraform
# root/outputs.tf - Expose module outputs to end users

# From layer_1 module
output "base_resource_id" {
  value       = module.layer_1.base_resource_id
  description = "Primary resource ID from foundational layer"
}

output "base_resource_arn" {
  value       = module.layer_1.base_resource_arn
  description = "ARN of primary resource"
}

# From layer_2 module
output "identity_config" {
  value       = module.layer_2.identity_config
  description = "Identity/configuration output from layer-2"
}

# From layer_3 module
output "application_endpoint" {
  value       = module.layer_3.application_endpoint
  description = "Application layer service endpoint"
}

output "application_status" {
  value       = module.layer_3.application_status
  description = "Status information from application layer"
}
```

## Module Design Rules

### 1. Clear Inputs and Outputs

Each module must declare all dependencies as input variables, never relying on implicit access to parent module values:

```terraform
# ❌ BAD: Direct reference to parent values
resource "aws_eks_cluster" "main" {
  vpc_config {
    subnet_ids = var.root_private_subnets  # Fragile!
  }
}

# ✅ GOOD: Module declares its dependency explicitly
variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for cluster"
  validation {
    condition     = length(var.subnet_ids) >= 3
    error_message = "At least 3 subnets required"
  }
}
```

### 2. No Cross-Module Locals

If one module needs a value computed by another, expose it as an output:

```terraform
# ❌ BAD: Trying to access layer_2/locals.tf from layer_3/
computed_config = module.layer_2.local.internal_config  # Not exposed!

# ✅ GOOD: Use layer_2 module outputs
computed_config = module.layer_2.computed_config_output
```

### 3. Explicit Dependency Declaration

Use `depends_on` to ensure execution order:

```terraform
module "layer_3" {
  # ...
  
  # Ensures layer_1 and layer_2 complete before layer_3 starts
  depends_on = [module.layer_1, module.layer_2]
}
```

### 4. Module-Internal Naming Context

All resources include module context for clarity:

```terraform
# layer_2/main.tf
data "aws_service_discovery" "primary_service" {
  # Named to indicate: Layer 2 module, service discovery
}

resource "aws_resource_config" "application_config" {
  # Named to indicate: Layer 3 module, application, configuration
}
```

## Adding a New Module

### Step 1: Create Module Directory

```bash
mkdir -p new-layer/{
  main.tf
  variables.tf
  locals.tf
  outputs.tf
}
```

### Step 2: Define Module Interface

```terraform
# new-layer/variables.tf
variable "dependency_resource_id" {
  type        = string
  description = "Resource ID from upstream module"
}

variable "feature_flag" {
  type    = bool
  default = false
}

variable "namespace" {
  type    = string
  default = "default"
}
```

### Step 3: Implement Resources

```terraform
# new-layer/main.tf
resource "aws_resource_type" "primary" {
  parent_id = var.dependency_resource_id
  
  dynamic "config_block" {
    for_each = var.feature_flag ? [1] : []
    content {
      # Conditional configuration
    }
  }
}

# ... more resources
```

### Step 4: Export Outputs

```terraform
# new-layer/outputs.tf
output "resource_id" {
  value = aws_resource_type.primary.id
}

output "resource_endpoint" {
  value = aws_resource_type.primary.endpoint
}
```

### Step 5: Integrate at Root

```terraform
# root/main.tf
module "new_layer" {
  source = "./new-layer"
  
  dependency_resource_id = module.layer_1.base_resource_id
  depends_on             = [module.layer_1]  # Explicit dependency
}
```

### Step 6: Update Root Outputs

```terraform
# root/outputs.tf
output "new_layer_resource_endpoint" {
  value = module.new_layer.resource_endpoint
}
```

## Testing Individual Modules

Each module can be tested in isolation by creating a test configuration:

```terraform
# test-layer-2/main.tf
module "layer_2" {
  source = "../layer-2"
  
  configuration_param_1 = "test-value"
  region                = "us-east-1"
}

output "identity_config" {
  value = module.layer_2.identity_config
}
```

Run validation:

```bash
terraform init
terraform validate
terraform plan
```

## Dependency Management

Use `depends_on` strategically to model execution order:

```
layer-1 (no deps)
   ↓
 ┌──────────────┐
 │  layer-2     │ (can run in parallel with layer-1)
 │  (no deps)   │
 └──────────────┘
   ↓
 layer-3 (depends_on: layer-1, layer-2)
   ↓
 layer-4 (depends_on: layer-3)
```

```terraform
# This allows layer-1 and layer-2 to execute in parallel
module "layer_3" {
  depends_on = [module.layer_1, module.layer_2]
}
```

## Common Patterns

### Data Sourcing Across Modules

When one module needs to discover existing resources:

```terraform
# layer_2/main.tf - Discover external resource
data "aws_service_discovery" "upstream" {}

output "discovered_resource_arn" {
  value = data.aws_service_discovery.upstream.arn
}

# layer_3/main.tf - Use discovered resource
variable "discovered_resource_arn" {
  type = string
}

resource "aws_resource" "application" {
  # References discovered resource
  upstream_arn = var.discovered_resource_arn
}
```

### Conditional Resource Creation

Enable/disable resources based on input flags:

```terraform
# Root declares feature flag
variable "enable_optional_feature" {
  type    = bool
  default = true
}

# Modules honor the flag
# layer_2/main.tf
resource "aws_resource" "optional" {
  count = var.enable_optional_feature ? 1 : 0
  # ...
}

output "optional_resource_id" {
  value = try(aws_resource.optional[0].id, null)
}
```

### Chained Outputs

Pass outputs from one module as inputs to another:

```terraform
module "layer_3" {
  # ...
  upstream_config    = module.layer_2.computed_config        # From layer_2
  foundation_id      = module.layer_1.base_resource_id       # From layer_1
  project_name       = var.project_name                      # From root
}
```

## Directory Structure Template

```
infra/
├── main.tf                    # Root orchestrator
├── variables.tf               # All module variables
├── outputs.tf                 # Aggregated outputs
├── providers.tf               # Provider config
├── versions.tf                # Version constraints
├── terraform.tfvars.example   # Sample values
│
├── layer-1/                   # Foundation layer
│   ├── main.tf
│   ├── variables.tf
│   ├── locals.tf
│   └── outputs.tf
│
├── layer-2/                   # Middle layer
│   ├── main.tf
│   ├── variables.tf
│   ├── locals.tf
│   └── outputs.tf
│
├── layer-3/                   # Application layer
│   ├── main.tf
│   ├── variables.tf
│   ├── locals.tf
│   └── outputs.tf
│
└── layer-4/                   # Additional layer (optional)
    ├── main.tf
    ├── variables.tf
    ├── locals.tf
    └── outputs.tf
```

## When NOT to Use This Pattern

- Very simple infrastructure (single resource, minimal dependencies) → Use single module
- Temporary proof-of-concept → Use examples directory instead
- Infrastructure with deeply coupled state requirements → Consider alternative architecture
- Rapid prototyping where iteration speed matters more than structure → Start simple, refactor later

## Related Patterns

- **Module Registry**: Store reusable modules in Terraform Registry or private registry
- **Workspaces**: Use workspaces for multi-environment orchestration (dev, staging, prod)
- **Remote Backends**: Combine with remote state for team collaboration
- **Policy as Code**: Add OPA/Sentinel policies to orchestration layer for governance
