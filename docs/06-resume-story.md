# 06 — Resume & interview walkthrough

A ready-to-deliver answer for: *"Walk me through your infrastructure automation
with Terraform and Ansible — your best practices, and what makes it
enterprise-level."* Grounded in the lab in this repo, so it holds up to
follow-up questions.

> Honest framing: this is a **portfolio lab that models bank-grade patterns
> end-to-end on real VMs** — provisioning handoff, GitOps change control, state
> isolation, CI, secrets. Present it as "I designed and built a pipeline that
> models how a bank runs this," not as production at a named employer.

## Resume bullets (pick / trim)

- Designed and built a bank-style infrastructure-automation pipeline with
  **Terraform** (provisioning + remote state) and **Ansible** (configuration)
  across isolated **dev/qa/prod** environments, driven by **GitOps** change
  control.
- Implemented **CI validation** (yamllint, ansible-lint, playbook syntax checks,
  `terraform validate`, collection build) as a merge gate, with **HCP Terraform**
  speculative plans posted on every pull request.
- Authored a **reusable, versioned Ansible collection** (`company.infrastructure`)
  and modeled **centralized execution** via Ansible Automation Platform / AWX
  **execution environments**; secrets via **ansible-vault** with a path to
  HashiCorp Vault.

## The spoken walkthrough

> At a high level I treat infrastructure automation as **two planes with a clean
> handoff**. Terraform owns provisioning and state — *what exists* — and Ansible
> owns configuration — *how it's set up*. The connective tissue is the inventory:
> Terraform creates the hosts and its outputs **become** the Ansible inventory,
> so there's one explicit handoff instead of the two tools stepping on each
> other.

> Everything is driven from **Git as the single source of truth**. A change
> starts as a pull request. CI runs yamllint, ansible-lint, playbook
> syntax-checks, `terraform fmt`/`validate`, and it builds our internal Ansible
> collection. In parallel, HCP Terraform posts a **speculative plan right on the
> PR**, so a reviewer sees exactly what infrastructure would change *before*
> anything is applied. Only after review and merge does Terraform apply — and
> **production is gated behind a manual approval**.

> **State** is where a lot of the enterprise discipline lives. Each environment
> has its own **isolated, remote, locked, encrypted, versioned** state. A mistake
> in dev can't touch prod, and every run is logged — that's the immutable audit
> trail compliance needs.

> For configuration, the **same playbooks and the same reusable collection run in
> every environment**; only the inventory and variables change. That sameness is
> what makes promotion from dev to prod trustworthy. **Secrets never sit in the
> repo** — they're in ansible-vault, and in a real deployment they'd come from a
> central engine like HashiCorp Vault, with the controller (AAP/AWX) holding
> credentials and running everything from **pinned execution environments**
> rather than someone's laptop.

> What makes it **enterprise-level** isn't any one tool — it's the **governance**
> wrapped around them: per-environment state isolation, GitOps change control
> with reviewed plans, policy-as-code guardrails, **separation of duties**
> between who can plan, apply, and approve prod, centralized execution with a
> credential store, and an end-to-end audit trail.

## Best practices in place (talking points)

- **Separation of concerns** — Terraform provisions, Ansible configures; the
  inventory is the handoff.
- **Environment isolation** — separate inventories *and* separate state for
  dev/qa/prod; blast radius stays small.
- **GitOps** — no change reaches an environment except through a reviewed,
  CI-checked PR; branch protection enforces it.
- **Remote, locked, versioned state** — HCP Terraform (or S3 + DynamoDB lock).
- **Reusable content** — a versioned internal collection instead of copy-pasted
  roles; one `site.yml`, many inventories.
- **Secrets hygiene** — ansible-vault, `no_log`, nothing sensitive in Git or in
  URLs; sensitive TF vars server-side.
- **Reproducible runtime** — execution environments pin collections + Python
  deps so runs aren't "works on my machine."

## What makes it enterprise-level (the differentiators)

| Home-lab automation | Enterprise / bank pipeline |
|---------------------|----------------------------|
| Run from a laptop | Centralized execution (AAP/AWX) + credential store |
| One shared state | Per-environment isolated, RBAC'd, encrypted state |
| Push to main | PR → speculative plan → review → gated apply |
| "Looks fine" | Policy-as-code (Sentinel/OPA) gates cost/security/compliance |
| Ad-hoc secrets | Central secrets engine, short-lived dynamic credentials |
| No paper trail | Immutable, auditable run history for regulators |

## Likely follow-up questions — crisp answers

- **Why both Terraform and Ansible?** Different jobs: Terraform is declarative and
  owns resource lifecycle + state; Ansible is great at in-place, ordered
  configuration and app deploy. Using each where it's strong beats forcing one to
  do both.
- **How do you keep state safe?** Remote, locked (no concurrent applies),
  encrypted, versioned, and **isolated per environment** so dev can't corrupt
  prod. Access is RBAC'd; prod is tighter than dev.
- **How do you stop a bad change reaching prod?** Branch protection → CI must pass
  → reviewer approves → speculative plan is inspected → merge → apply, with prod
  set to **manual approval**.
- **How is it DRY?** A versioned collection of roles is the single source of
  truth for logic; environments differ only by inventory + variables.
- **What would you add at true bank scale?** Sentinel/OPA policy-as-code, drift
  detection, Vault dynamic credentials, Event-Driven Ansible for
  auto-remediation, a private Automation Hub, and change-ticket integration.
