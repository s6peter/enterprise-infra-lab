# 07 — Using Ansible Automation Platform (hands-on runbook)

You have a real AAP at <https://192.168.122.49/overview>. This runbook drives it
with **this repo** so you learn every component by using it: wire the lab in,
then run `site.yml` against the dev VMs (`192.168.122.203/.204`).

## The mental model

AAP has two halves (both in the left nav):

### Automation Execution (Automation Controller) — *run playbooks*

| Component | What it is | In this lab |
|-----------|-----------|-------------|
| **Project** | A Git repo (or manual dir) of playbooks/roles/collections; syncs from SCM | `enterprise-infra-lab` |
| **Inventory** | Hosts + groups + vars (static import or dynamic) | import `inventories/dev/hosts.ini` |
| **Hosts** | Individual managed nodes inside an inventory | `app01`, `db01` |
| **Credentials** | Encrypted secrets: **Machine** (SSH), **Source Control** (git), **Vault** (ansible-vault pw), cloud… | `vms` + `vms-ai` key |
| **Credential Types** | Templates for custom credential fields | (advanced) |
| **Execution Environments (EE)** | Container image jobs run inside (pinned deps) | default EE, or `company-ee` |
| **Instances / Instance Groups** | The compute that executes jobs (control/execution mesh) | the single node you installed |
| **Templates → Job Template** | Binds Project + Playbook + Inventory + Credentials + EE into one runnable unit | "dev - site" |
| **Templates → Workflow Template** | Chains job templates with success/fail branches + approvals | baseline → docker → deploy |
| **Jobs** | Run history + streamed output (your audit trail) | every launch |
| **Schedules** | Cron-like triggers for templates | nightly site run |

The unit of execution is the **Job Template**: it's the AAP equivalent of one
`ansible-playbook -i <inv> <playbook> --ask-become-pass` command, but with the
inventory, credentials, and runtime all managed and logged.

### Automation Decisions (Event-Driven Ansible) — *react to events*

| Component | What it is |
|-----------|-----------|
| **Project** (EDA) | Git repo of **rulebooks** (event → condition → action) |
| **Decision Environment** | Container image that runs rulebooks |
| **Rulebook Activation** | A running rulebook listening to an event source; fires actions (e.g. launch a Job Template) |
| **Event Streams** | Inbound endpoints that feed events in |
| **Rule Audit** | History of which rules fired |

Use EDA for **auto-remediation** (event happens → AAP runs a playbook without a
human). Learn Automation Execution first; EDA builds on it.

## Warm-up (5 min): launch the built-in demo

AAP ships a **Demo Project**, **Demo Inventory**, and **Demo Job Template**.
Before wiring your own, run the demo end-to-end so you've seen the mechanics:

1. **Templates** → open **Demo Job Template** → **Launch**.
2. Watch the streamed output, then look at it under **Jobs**.

That's the whole loop: template → job → output → audit. Now build the real one.

## Wire in this lab

> **Prerequisite:** AAP's Project pulls from Git, so the repo needs to be
> reachable. Easiest path: push it to GitHub (`s6peter/enterprise-infra-lab`)
> and point the Project at that URL. (A "manual" project — files dropped on the
> controller — also works but is clunkier.)

### 1. Machine credential (how AAP logs into the VMs)

**Infrastructure → Credentials → Create credential**
- Credential type: **Machine**
- Username: `vms`
- SSH Private Key: paste the contents of `~/.ssh/vms-ai` (the **private** key)
- Privilege Escalation Method: `sudo`
- Privilege Escalation Password: the `vms` sudo password (your VMs have no
  passwordless sudo, so this is required for `become`)

> This is the enterprise win: the key lives in AAP's encrypted store, not on a
> laptop. In this repo the same key/user also appear in group_vars for laptop
> runs — they match, so nothing conflicts (AAP injects the key via
> `--private-key`, which wins).

### 2. Source Control credential (only if the GitHub repo is private)

**Credentials → Create** → type **Source Control** → username + a GitHub PAT (or
an SSH key). Skip for a public repo.

### 3. Project

**Automation Execution → Projects → Create project**
- Name: `enterprise-infra-lab`
- Source Control Type: **Git**
- Source Control URL: your repo URL (e.g. `https://github.com/s6peter/enterprise-infra-lab.git`)
- Source Control Credential: the one from step 2 (if private)
- Options: check **Update Revision on Launch** (always run latest), **Clean**,
  **Delete**
- **Save**, then **Sync**. On sync AAP auto-installs the collections listed in
  `collections/requirements.yml` (that's why that file exists).

### 4. Inventory

**Infrastructure → Inventories → Create inventory**
- Name: `dev`
- Save, open it → **Sources → Add source**
  - Source: **Sourced from a Project**
  - Project: `enterprise-infra-lab`
  - Inventory file: `inventories/dev/hosts.ini`
- **Sync** the source → `app01` and `db01` appear under **Hosts**.

### 5. (Optional) Vault credential

If you encrypt `group_vars/.../vault.yml`, add a **Vault** credential with the
vault password so playbooks decrypt at runtime.

### 6. First job template — connectivity

**Automation Execution → Templates → Create → Job Template**
- Name: `dev - ping`
- Inventory: `dev`
- Project: `enterprise-infra-lab`
- Playbook: `playbooks/ping.yml`
- Execution Environment: default
- Credentials: the **Machine** credential
- **Save → Launch** → expect green `ping: pong` for both hosts. This proves
  AAP → VM connectivity before you run anything privileged.

### 7. The real job template — configure the fleet

Create another Job Template:
- Name: `dev - site`
- Inventory: `dev`, Project: `enterprise-infra-lab`, Playbook: `playbooks/site.yml`
- Credentials: Machine (+ Vault if used)
- **Privilege Escalation**: enable **Run as (become)** (site.yml needs sudo)
- Optional: **Verbosity** 1, a **Limit**, a **Survey** for prompt-driven vars
- **Save → Launch** → this is the managed equivalent of
  `ansible-playbook playbooks/site.yml --ask-become-pass`: baseline on all hosts,
  Docker on the app/db tiers.

## Level up

- **Workflow Template** (Templates → Create → Workflow Job Template): chain
  `baseline → docker → deploy`, add an **Approval node** before a prod branch —
  that models separation of duties and the "nothing hits prod unapproved" gate.
- **Schedules**: attach a schedule to `dev - site` to run nightly.
- **RBAC** (Access): make a Team, grant **Execute** on templates to devs, keep
  prod **Approve** with leads. Least privilege, enforced.
- **EDA**: create an EDA **Project** (rulebooks repo) + a **Decision
  Environment**, then a **Rulebook Activation** that launches `dev - site` (or a
  remediation playbook) when an event arrives.

## Suggested learning order

1. Launch the **Demo Job Template** (see the loop).
2. Wire Project + Inventory + Machine credential; run **dev - ping**.
3. Run **dev - site** (become).
4. Build a **Workflow** with an approval node.
5. Add a **Schedule**.
6. Set up **RBAC** teams/roles.
7. Explore **EDA** last.

Each step teaches one component by using it — the fastest way to actually learn
AAP.
