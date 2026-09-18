terraform {
  required_version = ">= 1.6.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  # ---------------------------------------------------------------------------
  # HCP Terraform (Terraform Cloud) -- remote state + remote runs.
  # Disabled by default so `terraform init` works locally with NO credentials.
  #
  # To enable (see docs/03-hcp-terraform-setup.md):
  #   1. Create an HCP Terraform org and run `terraform login`.
  #   2. Uncomment the block below and set your org name.
  #   3. `terraform init` will offer to migrate local state to HCP.
  #
  # cloud {
  #   organization = "REPLACE_WITH_YOUR_HCP_ORG"
  #   workspaces {
  #     tags = ["enterprise-infra-lab"]
  #   }
  # }
  # ---------------------------------------------------------------------------
}
