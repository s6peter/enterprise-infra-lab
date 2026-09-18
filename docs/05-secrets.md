# 05 — Secrets handling

Rule: **no plaintext secrets in Git, ever.** This lab uses `ansible-vault` as the
baseline; the table at the bottom shows what each platform uses in production.

## ansible-vault workflow

Each environment has a `group_vars/all/vault.yml` (encrypted) alongside the
plaintext `main.yml`. Start from the example:

```bash
cd inventories/dev/group_vars/all
cp vault.yml.example vault.yml
# edit real values, then encrypt:
ansible-vault encrypt vault.yml
```

Edit later with `ansible-vault edit vault.yml`. Reference variables normally
(`{{ vault_postgres_password }}`) — Ansible decrypts at runtime when you pass a
password:

```bash
ansible-playbook playbooks/site.yml --ask-become-pass --ask-vault-pass
```

For unattended/CI runs use a password **file** (never committed):

```bash
echo 'my-vault-password' > ~/.vault-pass-dev   # outside the repo, chmod 600
ansible-playbook playbooks/site.yml --vault-password-file ~/.vault-pass-dev
```

## What `.gitignore` protects

Already ignored: `*.vault-pass`, `.vault_pass*`, `*.pem`, `*.key`, `*.tfvars`
(real values), `*.tfstate*` (state can contain secrets). The **encrypted**
`vault.yml` is safe to commit; the plaintext `.example` must stay a template.

## How each platform stores secrets in production

| Layer | Mechanism |
|-------|-----------|
| Ansible (this lab) | `ansible-vault` encrypted files |
| Ansible controller | AAP/AWX **Credential** store (encrypted, RBAC'd), or a Vault credential lookup |
| Terraform | HCP **sensitive workspace variables**; state stored encrypted server-side |
| Bank standard | HashiCorp **Vault** or **CyberArk** as the central secrets engine, with short-lived dynamic credentials |

Never echo a decrypted secret into logs. Keep `no_log: true` on tasks that
handle them.
