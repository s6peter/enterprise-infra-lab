# 03 — HCP Terraform (Terraform Cloud) setup

HCP Terraform gives you **remote, locked, encrypted, versioned state** and
**remote runs** with plan/apply history — the managed version of what banks build
with S3 + DynamoDB + pipelines. Free tier is enough for this lab.

> You must authenticate yourself. No credentials are baked into this repo.

## 1. Create an org and log in

1. Sign up at <https://app.terraform.io> and create an **organization**.
2. Authenticate the CLI (opens a browser, stores a token in
   `~/.terraform.d/credentials.tfrc.json`):

   ```bash
   terraform login
   ```

## 2. Enable the cloud backend

Edit `terraform/versions.tf`, uncomment the `cloud` block, set your org:

```hcl
cloud {
  organization = "your-org-name"
  workspaces {
    tags = ["enterprise-infra-lab"]
  }
}
```

Then:

```bash
cd terraform
terraform init      # offers to migrate local state to HCP — accept
```

## 3. One workspace per environment

The `tags` form lets you keep dev/qa/prod as separate workspaces (separate
state, separate access):

```bash
terraform workspace new dev
terraform workspace new qa
terraform workspace new prod
```

Map each workspace's `environment` variable (`dev`/`qa`/`prod`) in the HCP UI
under **Workspace → Variables**, or pass `-var environment=...` for CLI runs.

## 4. VCS-driven workflow (the enterprise default)

In the HCP UI: **Workspace → Settings → Version Control → Connect to VCS**, pick
your GitHub repo. From then on:

- A **pull request** triggers a **speculative plan** posted back on the PR.
- A **merge to `main`** queues a real run; prod is set to **manual apply** so a
  human approves.

## 5. Secrets

Store sensitive values (API tokens, passwords) as **sensitive workspace
variables** in HCP — never in the repo. This is HCP's equivalent of a secrets
manager for Terraform-managed resources.

## Reference

- Remote state: <https://developer.hashicorp.com/terraform/cloud-docs/workspaces/state>
- VCS workflow: <https://developer.hashicorp.com/terraform/cloud-docs/run/ui>
