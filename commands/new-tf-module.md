Create a new Terraform module with standard structure.

Use the argument as the module name. Example: `/new-tf-module networking` or `/new-tf-module storage`.

Create the module in `modules/{module-name}/` relative to the current directory.

Create the following files:

**versions.tf**
```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
```

**variables.tf** — with relevant variables for the module type, all with `description`. Always include:
- `workload` (string) — Workload/project name
- `environment` (string) with validation: `["dev", "test", "stg", "prd"]`
- `location` (string) — Azure region, default `"West Europe"`
- `tags` (map(string)) — Additional tags, default `{}`

**main.tf** — with an example core resource appropriate for the module name. Always include a `locals` block:
```hcl
locals {
  common_tags = merge({
    environment  = var.environment
    workload     = var.workload
    managed-by   = "terraform"
  }, var.tags)
}
```

**outputs.tf** — with relevant outputs (id, name) for the created resources, all with `description`.

**README.md** — with:
- Module description
- Usage example
- Inputs table
- Outputs table

After creating: show the file structure and ask if there are specific resources to add to the module.
