# 04 — Ansible Automation Platform / AWX

Running Ansible from a laptop is fine for a lab. Banks instead run it from a
**controller** (Red Hat **Ansible Automation Platform**, or its upstream
**AWX**) so that: credentials live in a vault, runs are logged and RBAC'd,
schedules and approvals exist, and every run uses a pinned **Execution
Environment** rather than "whatever is on my machine".

## AAP vs AWX

| | AWX | Ansible Automation Platform |
|-|-----|-----------------------------|
| Cost | Free, community | Paid, Red Hat supported |
| Runs on | Kubernetes (awx-operator) | RHEL or OpenShift |
| Extras | Core controller | Private Automation Hub, Analytics, Event-Driven Ansible, certified content |
| Use here | **Local substitute** | What you'd use at a bank |

> Note (2025): AWX moved to a nightly-release, service-oriented refactor. Great
> for learning; pin a known-good tag for anything you rely on.

## Execution Environment

`execution-environment/execution-environment.yml` defines the container image
that carries our collections + Python deps. Build it once:

```bash
pip install --user ansible-builder
ansible-builder build -t company-ee:1.0 \
  -f execution-environment/execution-environment.yml
```

Push `company-ee:1.0` to a registry and select it in AAP/AWX. This is the single
most important enterprise habit: **the runtime is versioned, not ad-hoc**.

## Run AWX locally (optional, heavy)

AWX needs Kubernetes. On a home machine, `minikube` or `k3s` + the awx-operator:

```bash
minikube start --cpus=4 --memory=6g
kubectl apply -k "github.com/ansible/awx-operator/config/default?ref=2.19.1"
# create an AWX CR (see the awx-operator README), then:
minikube service awx-service --url
```

Then, in the AWX UI, wire up the same pieces this repo already provides:

1. **Project** → this Git repo (SCM).
2. **Inventory** → import `inventories/dev/hosts.ini` (or a dynamic source).
3. **Credential** → the `vms` SSH key (machine credential) + a vault credential.
4. **Execution Environment** → `company-ee:1.0`.
5. **Job Template** → runs `playbooks/site.yml` against the inventory.

> You authenticate to AWX/AAP in its own UI. No AWX/AAP credentials are stored
> in this repo.
