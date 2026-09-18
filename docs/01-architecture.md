# 01 — Architecture

## The two-plane model

Enterprises split infrastructure automation into two planes with one clean
handoff. Mixing them is the most common anti-pattern.

| Plane | Tool | Owns | Answers |
|-------|------|------|---------|
| Provisioning | **Terraform** | Resources + **state** | "What exists?" |
| Configuration | **Ansible** | Packages, services, files | "How is it set up?" |

The **handoff** is an inventory: Terraform's outputs (host names + IPs) become
the hosts Ansible configures. In this lab, `terraform/` renders
`generated/<env>-hosts.ini` to make that explicit; the committed
`inventories/dev/hosts.ini` is the same idea, kept static so dev runs offline.

## Environments and promotion

```
  dev  ──promote──▶  qa  ──promote──▶  prod
  (home VMs)         (placeholder)     (placeholder, strictest controls)
```

- **Separate inventories** (`inventories/<env>/`) and, in HCP, **separate state
  per environment** — a dev mistake can never touch prod state.
- The **same** playbooks and the **same** collection run everywhere; only the
  inventory and variables change. That is what makes promotion trustworthy.
- **prod** carries the tightest controls: reviewed PR + approved plan, runs from
  AAP/AWX rather than a laptop, least-privilege credentials.

## Where each enterprise control lives here

| Control | Enterprise | This lab |
|---------|-----------|----------|
| Remote, locked, per-env state | HCP Terraform / S3+DynamoDB | HCP `cloud` block (`terraform/versions.tf`) |
| Change workflow + audit trail | VCS-driven runs, speculative plans on PRs | GitHub + CI (`.github/workflows/ci.yml`) |
| Policy as code | Sentinel / OPA gates | CI lint/validate (free-tier stand-in) |
| Central execution, no laptop secrets | AAP/AWX + Execution Environments | `execution-environment/` + docs |
| Reusable, certified content | Private Automation Hub | `company.infrastructure` collection |
| Secrets | Vault / CyberArk / sensitive TF vars | `ansible-vault` + `docs/05-secrets.md` |
| Separation of duties | plan vs apply vs approve-prod roles | modeled via env split + docs |

## Request flow (how a change reaches prod)

1. Engineer opens a PR.
2. CI runs yamllint, ansible-lint, syntax-check, `terraform validate`, builds
   the collection. HCP posts a **speculative plan** on the PR.
3. Reviewer approves; merge to `main`.
4. HCP applies (dev auto, prod gated on manual approval).
5. AAP/AWX runs the Ansible `site.yml` against the new inventory.

Every step is logged — the immutable audit trail compliance teams require.
