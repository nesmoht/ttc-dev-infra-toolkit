#!/bin/bash
# Warn if any .tf file would be changed by terraform fmt
if echo "$CLAUDE_TOOL_INPUT" | grep -q '\.tf"'; then
  if command -v terraform &>/dev/null; then
    terraform fmt -check -recursive . 2>/dev/null \
      && echo "✓ Terraform format OK" \
      || echo "⚠ Run 'terraform fmt' to fix formatting"
  fi
fi
