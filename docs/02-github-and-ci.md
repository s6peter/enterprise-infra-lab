# 02 — GitHub source control & CI

Git is the single source of truth: nothing reaches an environment except through
a reviewed, CI-checked commit.

## Create the repository

You are already authenticated as `s6peter` (`gh auth status`). From the repo
root:

```bash
git init -b main
git add .
git commit -m "Initial enterprise-infra-lab scaffold"
```

Create the remote and push (**this is a remote mutation — only run when you are
ready**):

```bash
gh repo create s6peter/enterprise-infra-lab --private --source=. --remote=origin --push
```

> Prefer to review first? Create it empty in the GitHub UI, then
> `git remote add origin git@github.com:s6peter/enterprise-infra-lab.git` and
> `git push -u origin main`.

## Branch protection (models separation of duties)

Require PRs and green CI before anything lands on `main`:

```bash
gh api -X PUT repos/s6peter/enterprise-infra-lab/branches/main/protection \
  --input - <<'JSON'
{
  "required_status_checks": { "strict": true, "contexts": ["ansible", "terraform"] },
  "enforce_admins": true,
  "required_pull_request_reviews": { "required_approving_review_count": 1 },
  "restrictions": null
}
JSON
```

## The PR → CI workflow

`.github/workflows/ci.yml` runs on every push and PR:

| Job | Steps |
|-----|-------|
| `ansible` | install tooling → install collections → **yamllint** → **ansible-lint** → **syntax-check** (dev/qa/prod) → **build** the collection (uploaded as an artifact) |
| `terraform` | `terraform fmt -check` → `init -backend=false` → `validate` |

Day-to-day:

```bash
git checkout -b feature/add-postgres-tuning
# ...edit...
git commit -am "baseline: tune kernel params"
git push -u origin HEAD
gh pr create --fill
```

CI must pass and a reviewer must approve before merge — the same gate a bank puts
in front of production.
