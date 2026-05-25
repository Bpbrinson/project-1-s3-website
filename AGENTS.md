# AGENTS.md — AI Agent Guide for this Repository

Purpose: help AI coding agents understand this repository quickly and perform common tasks (preview site, run Terraform, upload site files).

## Quick commands
- Local preview (from repo root):

```powershell
cd app\website
python -m http.server 8000
# open http://localhost:8000
```

- Terraform (dev environment):

```powershell
cd infrastructure\terraform\environments\dev
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Important locations
- Project README: [README.md](README.md#L1)
- Static site files: [app/website/index.html](app/website/index.html#L1), [app/website/features.html](app/website/features.html#L1)
- Terraform env (dev): [infrastructure/terraform/environments/dev/main.tf](infrastructure/terraform/environments/dev/main.tf#L1)
- S3 module: [infrastructure/terraform/modules/s3-static-site/main.tf](infrastructure/terraform/modules/s3-static-site/main.tf#L1)
- CloudFront module: [infrastructure/terraform/modules/cloudfront-static-site/main.tf](infrastructure/terraform/modules/cloudfront-static-site/main.tf#L1)

## Conventions & notes for agents
- Use the `dev` environment under `infrastructure/terraform/environments/dev` for examples and testing.
- The S3 module optionally uploads files when `upload_files = true` and `website_directory` points to the local site folder. See `terraform.tfvars` in the dev env.
- The module uses `fileset()` and creates `aws_s3_object` resources for each file — avoid reimplementing file uploads outside Terraform unless explicitly requested.
- Do not commit secrets or AWS credentials. Tests and automation should rely on environment-backed credentials (e.g., GitHub Actions secrets, local AWS profile).

## Typical tasks agents will perform
- Preview the site locally by serving `app/website`.
- Update or add static content under `app/website` and verify uploads by running Terraform in the dev environment (respect `upload_files` var).
- Inspect and modify Terraform modules under `infrastructure/terraform/modules` — keep changes minimal and preserve module interfaces.

## When to ask the user
- If a Terraform change requires AWS credentials, ask the user for confirmation before suggesting commands that will modify real cloud resources.
- If a requested change affects naming, tags, or domains, ask which values to use (project_name, environment, domain_name, bucket_name).

If you'd like, I can also:
- Add a `.github/workflows/ci.yml` to run `terraform fmt`/`plan` and optionally publish site files on push.
- Create small task-specific skills (e.g., `publish-site`, `invalidate-cloudfront`).

Please review and tell me if you'd like more instructions added or a different filename/location for agent guidance.