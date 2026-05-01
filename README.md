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

Create an empty folder, open Claude Code in it, and paste this prompt (adjust the path to where you cloned the toolkit):

```
Read the SKILL.md file from <TOOLKIT_PATH> and follow it to set up this project.
```

Replace `<TOOLKIT_PATH>` with the path to your local clone, e.g. `~/dev/git/ttc-dev-infra-toolkit`.

Claude will ask you:
- Workload name
- Which environments (dev / prd / etc.)
- Which modules (networking, data, security)

Then it will scaffold the full Terraform structure and create project-level Claude config.

## Onboard an existing project

Open Claude Code in an existing Terraform repo and paste this prompt (adjust the path to where you cloned the toolkit):

```
Read the SKILL.md file from <TOOLKIT_PATH> and onboard this existing Terraform project.
```

Claude will read your existing code and add `AGENTS.md` and `.claude/CLAUDE.md` without touching your Terraform files.

---

## Setup (one-time global config)

Run this once to install the global agents and commands into Claude Code:

```bash
# Clone the toolkit
git clone <repo-url> ~/ttc-dev-infra-toolkit
cd ~/ttc-dev-infra-toolkit

# Install (symlinks into ~/.claude)
./install.sh
```

Or manually:

```bash
TOOLKIT=$(pwd)
ln -sf "$TOOLKIT/CLAUDE.md" ~/.claude/CLAUDE.md
ln -sf "$TOOLKIT/agents"   ~/.claude/agents
ln -sf "$TOOLKIT/commands" ~/.claude/commands
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
| `caf-compliance` | CAF management group hierarchy + security policy baseline |

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

```
