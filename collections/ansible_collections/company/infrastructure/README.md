# company.infrastructure

Internal Ansible collection — reusable building blocks for the company platform.
Models how a bank ships **certified content** through a private Automation Hub so
every team automates the same, reviewed way.

## Roles

| Role | Purpose | Key variables |
|------|---------|---------------|
| `company.infrastructure.baseline` | Common host baseline: packages, timezone, managed MOTD | `baseline_timezone`, `baseline_extra_packages` |
| `company.infrastructure.docker_host` | Install Docker Engine + Compose plugin, manage the `docker` group | `docker_host_users` |

## Usage

```yaml
- hosts: all
  become: true
  roles:
    - role: company.infrastructure.baseline
    - role: company.infrastructure.docker_host
```

## Build & publish

```bash
ansible-galaxy collection build . --output-path ../../../../dist/ --force
# In a bank this tarball is pushed to a private Automation Hub / Galaxy NG:
# ansible-galaxy collection publish dist/company-infrastructure-1.0.0.tar.gz
```

Bump `version:` in `galaxy.yml` on every release.
