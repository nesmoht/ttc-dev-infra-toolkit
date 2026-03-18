# MCP Server: Terraform Registry

The official HashiCorp Terraform MCP server gives Claude real-time access to the Terraform Registry — provider documentation, module details, and current versions.

## What it enables

- Look up accurate `azurerm` resource arguments (no hallucinated attributes)
- Get the latest `azurerm` provider version
- Search for existing community/official Terraform modules
- Retrieve full resource schema before writing Terraform code

## Installation

Requires Docker.

```bash
docker pull hashicorp/terraform-mcp-server
```

## Project config (`.mcp.json`)

```json
{
  "mcpServers": {
    "terraform": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "hashicorp/terraform-mcp-server"]
    }
  }
}
```

No authentication needed for registry-only access (provider docs, modules, versions).

## Usage examples

Once active in a Claude Code session:

- *"What arguments does azurerm_mssql_server accept?"*
- *"What is the latest version of the azurerm provider?"*
- *"Find a Terraform module for Azure VNet hub-spoke"*
- *"Show me the schema for azurerm_private_endpoint"*

## Notes

- Registry tools work without a HCP Terraform account or token
- If you also use HCP Terraform / Terraform Enterprise, add `TFE_ADDRESS` and `TFE_TOKEN` env vars to unlock workspace management tools
- Source: [hashicorp/terraform-mcp-server](https://github.com/hashicorp/terraform-mcp-server)
