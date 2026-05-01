# Changelog

All notable changes to this toolkit are documented here.

## [1.1.0] — 2026-04-29

### Added
- `install.sh` — one-command setup that symlinks agents, commands, and CLAUDE.md into `~/.claude`; skips targets that are already real files
- `examples/webapp/` — fully-worked example project (networking + data + security, dev + prd) showing what the toolkit generates
- `examples/README.md` — table of all resources created by the example and quick-start instructions
- Format check hook now supports both `tofu` and `terraform` (prefers `tofu` if both are installed)

### Fixed
- Hardcoded local paths in `README.md` and `SKILL.md` replaced with `<TOOLKIT_PATH>` placeholder so the toolkit is portable across machines and users

## [1.0.0] — 2026-04-28

### Added
- Initial release
- `CLAUDE.md` — Azure CAF naming conventions, Terraform best practices, hub-spoke networking patterns, Key Vault and SQL hardening standards
- `SKILL.md` — onboarding flow for new and existing Terraform projects
- `agents/azure-architect.md` — agent for designing Azure infrastructure from requirements
- `agents/terraform-reviewer.md` — agent for reviewing Terraform code (40+ checks across security, networking, naming, CAF)
- `commands/new-tf-module.md` — `/new-tf-module` command to scaffold a module with standard structure
- `commands/plan-infra.md` — `/plan-infra` command to plan and scaffold full infrastructure from a description
- `presets/networking.md` — hub-spoke VNet, subnets, NSG, peering
- `presets/data-platform.md` — Storage Account, SQL Server/DB, Cosmos DB, Key Vault
- `presets/caf-compliance.md` — CAF management group hierarchy and security policy baseline
