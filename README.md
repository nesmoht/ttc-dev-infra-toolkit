# Azure Infrastructure Toolkit

Shared Claude Code configuration for Azure infrastructure projects with Terraform. Provides standardized agents, commands, naming conventions, and project presets.

Works with Claude Code.

## Start a new project

### Terraform or OpenTofu?

This toolkit works with both. Here's the difference:

| | Terraform | OpenTofu |
|---|---|---|
| License | BSL (restricted) | MPL 2.0 (open-source) |
| Governed by | HashiCorp / IBM | Linux Foundation |
| CLI command | `terraform` | `tofu` |
| Syntax / providers | HCL, same providers | 100% compatible |
| Cost | Free CLI, paid cloud platform | Free |

**Recommendation:** Use OpenTofu for new projects. It is fully compatible with Terraform — your `.tf` files, modules, and Azure backend config work without any changes. Simply install `tofu` and use it instead of `terraform`.

---

Open Claude Code in an empty project folder and paste this prompt:

```
Read the SKILL.md file from /home/jaht.linux/dev/git/ttc-dev-infra-toolkit and follow it to set up this project.
```

Claude will ask you:
- Workload name
- Which environments (dev / prd / etc.)
- Which modules (networking, data, security)

Then it will scaffold the full Terraform structure and create project-level Claude config.

## Onboard an existing project

Open Claude Code in an existing Terraform repo and paste this prompt:

```
Read the SKILL.md file from /home/jaht.linux/dev/git/ttc-dev-infra-toolkit and onboard this existing Terraform project.
```

Claude will read your existing code and add `AGENTS.md`, `.claude/CLAUDE.md`, and `.mcp.json` without touching your Terraform files.

---

## Setup (one-time global config)

Run this once to install the global agents and commands into Claude Code:

```bash
# Clone or locate the toolkit
cd /home/jaht.linux/dev/git/ttc-dev-infra-toolkit

# Symlink into ~/.claude (already done if you set this up with Claude)
ln -s $(pwd)/CLAUDE.md ~/.claude/CLAUDE.md
ln -s $(pwd)/agents ~/.claude/agents
ln -s $(pwd)/commands ~/.claude/commands
```

---

## What's included

### Agents (`agents/`)
| Agent | Description |
|---|---|
| `azure-architect` | Designs Azure infrastructure from requirements |
| `terraform-reviewer` | Reviews Terraform code for security and best practices |

### Commands (`commands/`)
| Command | Description |
|---|---|
| `/new-tf-module {name}` | Scaffolds a new Terraform module with standard structure |
| `/plan-infra {description}` | Plans and scaffolds full Azure infrastructure from a description |

### Presets (`presets/`)
| Preset | Description |
|---|---|
| `networking` | Hub-spoke VNet, subnets, NSG, peering |
| `data-platform` | Storage Account, SQL Server, Cosmos DB, Key Vault |

### MCP Servers (`mcp/`)
| Server | Description | Requires |
|---|---|---|
| `azure` | Query live Azure resources directly from Claude | Node.js, `az login` |
| `terraform` | Real-time azurerm provider docs + Terraform Registry access | Docker |

Config is created as `.mcp.json` in the project root during setup.

---

## Standards

All projects follow:
- **Azure CAF naming conventions** — `rg-`, `vnet-`, `snet-`, `sql-`, `st-`, `kv-` etc.
- **Terraform module structure** — `modules/{name}/main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
- **Azure Blob state backend** — centralized state per environment
- **Managed Identity** — no connection strings or passwords in code
- **Private endpoints** — for all data services in prd
- **Tagging** — `environment`, `workload`, `managed-by = "terraform"` on all resources

See `CLAUDE.md` for full standards reference.

---

## Repository Structure

```
ttc-dev-infra-toolkit/
  SKILL.md          ← Paste prompt to set up any new project
  CLAUDE.md         ← Azure/Terraform standards (always active via symlink)
  README.md         ← How to use
  VERSION           ← 1.0

  agents/
    azure-architect.md      → @azure-architect
    terraform-reviewer.md   → @terraform-reviewer

  commands/
    new-tf-module.md        → /new-tf-module {name}
    plan-infra.md           → /plan-infra {description}

  presets/
    networking.md           → Hub-spoke VNet, subnets, NSG
    data-platform.md        → Storage, SQL, Cosmos, Key Vault

  mcp/
    azure.md                → Live Azure resource queries
    terraform.md            → Real-time azurerm docs + Registry

  examples/configured-project/
    AGENTS.md, .claude/, .mcp.json, environments/dev/, modules/
```
