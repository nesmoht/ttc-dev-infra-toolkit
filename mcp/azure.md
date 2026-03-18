# MCP Server: Azure

The official Microsoft Azure MCP server lets Claude query your actual Azure resources directly — no need to copy-paste `az` CLI output.

## What it enables

- List resources in a resource group
- Read current configuration of any Azure resource
- Compare deployed state vs. Terraform code
- Check NSG rules, subnet configs, storage settings
- Inspect SQL servers, Cosmos accounts, Key Vaults

## Installation

Requires Node.js (npx). No separate install needed — runs on demand via npx.

You must be logged in to Azure:
```bash
az login
```

## Project config (`.mcp.json`)

Place this in the project root:

```json
{
  "mcpServers": {
    "azure": {
      "command": "npx",
      "args": ["-y", "@azure/mcp@latest", "server", "start"]
    }
  }
}
```

## Usage examples

Once the server is running in a Claude Code session:

- *"List all resource groups in my subscription"*
- *"Show the config of sql-dataplatform-prd-we"*
- *"What NSG rules are on nsg-data-dataplatform-prd?"*
- *"Does rg-dataplatform-prd-we exist yet?"*

## Notes

- Requires `az login` — uses your current Azure CLI session
- Reads only — does not create or modify Azure resources
- If you have multiple subscriptions, set the active one first:
  ```bash
  az account set --subscription "{name or id}"
  ```
