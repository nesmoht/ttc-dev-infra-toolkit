# AI Agent Instructions — dataplatform

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
