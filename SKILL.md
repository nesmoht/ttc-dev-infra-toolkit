# Azure Infrastructure Toolkit — Setup Instructions

You are helping set up a project using the ttc-dev-infra-toolkit.

## Step 1: Determine project type

First, check whether this is a **new** or **existing** Terraform project by looking at the current directory contents.

- If the directory is empty or has no `.tf` files → **New project** → follow Steps 2–7
- If the directory already contains Terraform files → **Existing project** → skip to [Existing Project Onboarding](#existing-project-onboarding)

---

# New Project Setup

## Step 2: Gather project information

Ask the user:
1. **Workload name** — short identifier for this project (e.g., `dataplatform`, `analytics`, `webapp`)
2. **Environments** — which environments are needed? (dev / test / stg / prd)
3. **Modules** — which of these are needed:
   - Networking (VNet, subnets, NSG, hub-spoke peering)
   - Data (Storage Account, SQL, Cosmos DB)
   - Security (Key Vault, private endpoints)
   - CAF Compliance (management group hierarchy + policy baseline — separate root module)
4. **Region** — primary Azure region (default: West Europe)

## Step 3: Apply the correct preset

Based on the modules selected, apply the matching preset from `presets/`:
- Networking only → `presets/networking.md`
- Data + Security → `presets/data-platform.md`
- All three → apply both presets

## Step 4: Create project structure

Scaffold the following in the current directory:

```
modules/
  networking/     # if selected
  data/           # if selected
  security/       # if selected
environments/
  {env}/          # one folder per environment
    main.tf
    variables.tf
    outputs.tf
    terraform.tfvars
    backend.tf
```

Use the naming conventions and standards from the global CLAUDE.md.

## Step 5: Create project-level Claude config

Create a `.claude/` folder in the project root with:

**`.claude/CLAUDE.md`** — project-specific context:
```markdown
# {WorkloadName} — Azure Infrastructure

Workload: {workload}
Environments: {env list}
Region: {region}
Toolkit version: {VERSION}

## Project Modules
{list of modules in use}

## Key Resources
{list the main Azure resources in this project once known}

## State Backend
Resource group: rg-tfstate-shared
Storage account: sttfstate{suffix}
Container: tfstate
Keys: {workload}-{env}.terraform.tfstate
```

**`.claude/settings.json`** — enable hooks:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": "bash .claude/scripts/tf-format-check.sh" }]
      }
    ]
  }
}
```

**`.claude/scripts/tf-format-check.sh`** — format check hook:
```bash
#!/bin/bash
# Check if edited file is a .tf file and warn if terraform fmt would change it
if echo "$CLAUDE_TOOL_INPUT" | grep -q '\.tf"'; then
  if command -v tofu &>/dev/null; then
    tofu fmt -check -recursive . 2>/dev/null && echo "✓ Format OK" || echo "⚠ Run 'tofu fmt' to fix formatting"
  elif command -v terraform &>/dev/null; then
    terraform fmt -check -recursive . 2>/dev/null && echo "✓ Format OK" || echo "⚠ Run 'terraform fmt' to fix formatting"
  fi
fi
```

**`.claude/ttc-dev-infra-toolkit-version`** — version tracking:
```
{VERSION}
```

## Step 6: Create AGENTS.md

Create `AGENTS.md` in the project root:

```markdown
# AI Agent Instructions — {WorkloadName}

This project uses the ttc-dev-infra-toolkit for Azure infrastructure with Terraform.

## Available Agents
- **azure-architect**: Design and plan Azure infrastructure changes
- **terraform-reviewer**: Review Terraform code for security and best practices

## Project Standards
- Follow naming conventions in ~/.claude/CLAUDE.md
- All resources must be tagged with environment, workload, managed-by=terraform
- Use private endpoints for all data services in prd
- State backend: Azure Blob Storage (see .claude/CLAUDE.md for details)

## When to use agents
- Before adding new Azure resources → @azure-architect
- Before committing Terraform changes → @terraform-reviewer
```

## Step 7: Summary

When done, show the user:
1. The created file structure (tree view)
2. What each module contains
3. Manual steps remaining:
   - `az login` to authenticate with Azure
   - Create state storage account if it doesn't exist
   - Run `terraform init` in each environment folder
   - Review `terraform.tfvars` and fill in values
   - Run `terraform validate` to check for errors
   - Run `terraform fmt -recursive` to fix formatting
   - Run `terraform plan` to preview changes before applying

---

# Existing Project Onboarding

Use this path when the project already has Terraform files.

## Step 1: Understand the existing project

Read the existing files to understand:
- What Azure resources are defined
- What environments exist (dev/prd/etc.)
- What the workload name is
- Whether a state backend is already configured

## Step 2: Create `.claude/CLAUDE.md`

Create a project-specific context file based on what you found:

```markdown
# {WorkloadName} — Azure Infrastructure

Workload: {workload}
Environments: {env list}
Region: {region}
Toolkit version: {VERSION}

## Project Modules
{list modules/folders that exist}

## Key Resources
{list the main Azure resources found in the code}

## State Backend
{copy backend config from existing backend.tf, or note if not yet configured}
```

## Step 3: Create AGENTS.md

Create `AGENTS.md` in the project root:

```markdown
# AI Agent Instructions — {WorkloadName}

This project uses the ttc-dev-infra-toolkit for Azure infrastructure with Terraform.

## Available Agents
- **azure-architect**: Design and plan Azure infrastructure changes
- **terraform-reviewer**: Review Terraform code for security and best practices

## Project Standards
- Follow naming conventions in ~/.claude/CLAUDE.md
- All resources must be tagged with environment, workload, managed-by=terraform
- Use private endpoints for all data services in prd
- State backend: Azure Blob Storage (see .claude/CLAUDE.md for details)

## When to use agents
- Before adding new Azure resources → @azure-architect
- Before committing Terraform changes → @terraform-reviewer
```

## Step 4: Create `.claude/ttc-dev-infra-toolkit-version`

```
{VERSION}
```

## Step 5: Summary

Show the user:
1. What you found in the existing project (modules, environments, resources)
2. The files you created
3. Optional next steps:
   - Run `@terraform-reviewer` to review existing code for issues
   - Run `terraform validate` to check for errors
   - Run `terraform fmt -recursive` to fix formatting
   - Run `terraform plan` to preview changes before applying
