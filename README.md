# enterprise-infra-lab

A minimal but **realistic** bank-style infrastructure-automation lab you can run
on a home machine. It models how enterprises combine **Terraform** (provisioning
+ state) with **Ansible** (configuration), promoted through **dev → qa → prod**,
governed by **Git + CI**, and centrally executed by **Ansible Automation
Platform / AWX**.

The runnable path uses your two existing libvirt VMs
(`192.168.122.203`, `192.168.122.204`) as the **dev** fleet. HCP Terraform and
AAP/AWX are scaffolded and documented as upgrades — no cloud account required to
start.

```
  TERRAFORM ──renders──▶ inventory ──consumed by──▶ ANSIBLE
  (infra + state)                                   (config)
        │                                               │
        └────────── Git (source of truth) ──────────────┘
                    PR ▶ CI ▶ plan ▶ review ▶ apply
```

## Quickstart (dev, runs today)

```bash
cd ~/ansible/enterprise-infra-lab
./scripts/bootstrap.sh          # installs lint tools + deps, then pings dev
# or step by step:
make deps                       # ansible-galaxy collection install
make ping                       # ansible all -m ping   (dev VMs)
make lint                       # yamllint + ansible-lint
make syntax                     # ansible-playbook --syntax-check
make site                       # baseline + docker_host  (prompts for sudo pw)
make build                      # build the company.infrastructure collection
```

> `make site` runs privileged tasks and will prompt for the `vms` sudo password
> (your VMs have no passwordless sudo).

## Layout

```
enterprise-infra-lab/
├── ansible.cfg                 # dev inventory default, collection path, ssh tuning
├── Makefile                    # deps / lint / syntax / ping / site / build
├── requirements.yml            # collection dependencies
├── inventories/{dev,qa,prod}/  # one inventory + group_vars per environment
├── playbooks/                  # ping.yml, baseline.yml, site.yml
├── collections/ansible_collections/company/infrastructure/
│   ├── galaxy.yml              # the reusable, versioned collection
│   └── roles/{baseline,docker_host}/
├── terraform/                  # provisioning plane + inventory handoff (HCP-ready)
├── execution-environment/      # AAP/AWX containerized runtime definition
├── .github/workflows/ci.yml    # yamllint, ansible-lint, syntax, TF validate, build
└── docs/                       # architecture + step-by-step platform setup
```

## Docs

| Doc | What |
|-----|------|
| [docs/01-architecture.md](docs/01-architecture.md) | The two-plane model, environments, how enterprise controls map here |
| [docs/02-github-and-ci.md](docs/02-github-and-ci.md) | Create the GitHub repo, branch protection, the PR→CI workflow |
| [docs/03-hcp-terraform-setup.md](docs/03-hcp-terraform-setup.md) | Sign up for HCP Terraform, remote state, dev/qa/prod workspaces |
| [docs/04-awx-aap-setup.md](docs/04-awx-aap-setup.md) | AAP vs AWX, execution environments, running AWX locally |
| [docs/05-secrets.md](docs/05-secrets.md) | ansible-vault, `.gitignore`, and how each platform stores secrets |

## Authentication you must do yourself

This repo assumes **no** credentials. You authenticate where noted:
GitHub (`gh auth`/SSH), HCP Terraform (`terraform login`), AAP/AWX (its own UI),
and any private registry. See the docs above.
