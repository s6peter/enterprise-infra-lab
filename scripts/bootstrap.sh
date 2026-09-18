#!/usr/bin/env bash
# One-shot local setup for the enterprise-infra-lab.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Creating .venv with lint/build tooling (PEP 668-safe)"
python3 -m venv .venv
./.venv/bin/pip install --quiet --upgrade pip ansible-lint yamllint ansible-builder

echo "==> Installing Ansible collection dependencies"
ansible-galaxy collection install -r requirements.yml

echo "==> Listing the company.infrastructure collection"
ansible-galaxy collection list 2>/dev/null | grep -i company \
  || echo "   (company.infrastructure is used in-repo via collections_path=./collections)"

echo "==> Smoke test: ping the dev fleet"
ansible all -m ping || echo "   Ping failed -- check the VMs are up and key auth works."

echo "==> Done. Next: make lint && make syntax && make site"
