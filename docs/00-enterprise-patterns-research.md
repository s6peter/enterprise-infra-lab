# 00 — Research: how enterprises & banks run Terraform + Ansible

Reference notes behind this lab's design. Captured 2026-09-18. Sources at the
bottom.

## 1. The core model: two planes, one handoff

Enterprises split infrastructure automation into two planes and keep the
boundary clean. Mixing them (e.g. provisioning from Ansible, or configuring from
Terraform) is the most common anti-pattern.

| Plane | Tool | Owns | Answers |
|-------|------|------|---------|
| Provisioning | **Terraform** | Resources + **state** | "What exists?" |
| Configuration | **Ansible** | Packages, services, files, app deploy | "How is it set up?" |

**The handoff is an inventory.** Terraform creates the hosts and exposes their
names/IPs as outputs; those outputs become the inventory Ansible configures.
Terraform is the source of truth for *what exists*; Ansible takes it from there.

```
  TERRAFORM ──renders──▶ inventory ──consumed by──▶ ANSIBLE
  (infra + state)        (TF outputs)               (config)
```

## 2. Environment isolation & promotion

- **Separate everything per environment** — separate inventories, separate
  variables, and (critically) **separate Terraform state** for dev / qa / prod.
  A dev mistake must never be able to touch prod state. State is split by
  environment *and* by blast radius (small state files = faster, safer plans).
- **Same code, different inputs.** The same playbooks/modules run in every
  environment; only inventory + variables change. That sameness is what makes
  promotion (dev → qa → prod) trustworthy.
- **Prod carries the strictest controls:** tighter state access (RBAC), changes
  only via reviewed PR + *approved* apply, runs from a controller (not a laptop),
  least-privilege credentials.

## 3. Governance controls layered on top (what makes it "enterprise")

| Concern | How enterprises do it |
|---------|-----------------------|
| **State** | Remote, locked, encrypted, versioned, isolated per env, RBAC'd (HCP Terraform, or S3 + DynamoDB lock) |
| **Change workflow** | VCS-driven: PR → **speculative plan** posted on the PR → review/approval → merge → apply. Git is the single source of truth; every change is auditable |
| **Guardrails** | Policy-as-code — **Sentinel** (HashiCorp) or **OPA** — gates cost, tagging, security, compliance before apply |
| **Centralized execution** | Ansible runs from a controller (**AAP/AWX**), not laptops, using pinned **Execution Environments** + a credential store |
| **Reusable content** | Internal, versioned, "certified" collections/modules in a **private registry / Automation Hub** |
| **Separation of duties** | Distinct roles for who can *plan* vs *apply* vs *approve prod*; least privilege throughout |
| **Secrets** | Central secrets engine — **HashiCorp Vault** or **CyberArk** — with short-lived dynamic credentials; TF sensitive vars; `ansible-vault` at minimum |
| **Audit** | Remote runs + pipeline logs create a permanent, immutable trail for compliance/regulators |

**The load-bearing insight for banks:** prod state has stricter access than dev,
environments never share state, and nothing reaches prod without a reviewed PR +
an approved plan — an immutable audit trail is the whole point.

## 4. HCP Terraform (Terraform Cloud) specifics

Managed remote state + remote runs — the turnkey version of what a bank would
otherwise build from S3 + DynamoDB + pipelines.

- **Remote state:** stored, locked, encrypted server-side, with full version
  history for rollback and drift analysis.
- **Workspaces = one per environment/component.** A workspace bundles config,
  one state file, variables, run history, and access controls. Map dev/qa/prod to
  separate workspaces.
- **Three run workflows:**
  - **VCS-driven** (the flagship): connect a repo; a push to the tracked branch
    queues a run, and a **pull request gets a speculative (plan-only) preview**
    posted back for review before merge.
  - **CLI-driven:** run `terraform plan/apply` locally, execution happens
    remotely.
  - **API-driven:** trigger runs via API for custom automation.
- **Secrets:** sensitive workspace variables (never in the repo).

## 5. Ansible Automation Platform vs AWX

| | AWX | Ansible Automation Platform (AAP) |
|-|-----|-----------------------------------|
| Cost / support | Free, community-supported | Paid, Red Hat supported + compliance certifications |
| Runs on | Kubernetes (awx-operator) | RHEL / OpenShift |
| Relationship | Upstream project | Hardened releases of AWX become AAP's automation controller |
| Extras | Core controller | Private Automation Hub, Analytics, **Event-Driven Ansible**, certified content |

Key shared concept — **Execution Environments (EEs):** containerized runtimes
that carry pinned collections + Python deps so every run is reproducible ("the
runtime is versioned, not ad-hoc"). This is the enterprise answer to "works on my
laptop."

> Note (2025): AWX moved to a service-oriented refactor + nightly releases —
> great for learning, but pin a known-good tag for anything you depend on.
> Enterprises wanting support/compliance choose AAP; smaller/open-source teams
> use AWX.

## 6. How this maps into the lab

See [01-architecture.md](01-architecture.md) for the control-by-control mapping.
In short: local state + static dev inventory run today; the `cloud` block, VCS
workflow, EE build, and vault workflow are scaffolded as the documented upgrades
toward the enterprise picture above.

## Sources

- HashiCorp — [Terraform + Ansible Automation Platform integration pattern](https://developer.hashicorp.com/validated-patterns/terraform/terraform-integrate-ansible-automation-platform)
- HashiCorp — [Trigger HCP Terraform runs from VCS](https://developer.hashicorp.com/terraform/tutorials/cloud-get-started/cloud-create-vcs-workspace)
- HashiCorp — [Manage workspace state in HCP Terraform](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/state)
- Spacelift — [Terraform state management best practices](https://spacelift.io/blog/terraform-state)
- Red Hat — [AWX vs Ansible Automation Platform](https://www.redhat.com/en/technologies/management/ansible/compare-awx-vs-ansible-automation-platform)
- Scalr — [Ultimate guide to using Terraform with Ansible](https://scalr.com/learning-center/ultimate-guide-to-using-terraform-with-ansible)
