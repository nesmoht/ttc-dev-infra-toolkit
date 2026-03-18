Plan and scaffold Azure infrastructure from a description.

Take the argument (or ask the user to describe) what needs to be built, then:

1. **Summarize** what you understood needs to be built — confirm with the user before continuing

2. **Design the architecture** — list the required Azure resources with rationale

3. **Suggest directory structure**:
```
{project}/
  modules/
    networking/     # If VNet/subnets are needed
    data/           # Storage, SQL, Cosmos
    security/       # Key Vault, private endpoints
  environments/
    dev/
      main.tf
      variables.tf
      outputs.tf
      terraform.tfvars
      backend.tf
    prd/
      ...
```

4. **Scaffold the files** — create the full structure with working Terraform code:
   - Follow naming conventions from CLAUDE.md
   - Include Azure Blob backend configuration
   - Tag all resources
   - Use Managed Identity where possible

5. **Identify next steps** — what is missing (credentials, state storage, pipeline etc.)

Keep the code simple and functional. Use `terraform validate`-compatible syntax. Offer to run the terraform-reviewer agent on the output when done.
