# Security Guidelines for This Project

## Overview
This project is publicly available on GitHub. Below are security concerns and best practices.

## Critical: Never Commit

❌ **Do NOT commit these files:**
- `terraform.tfstate` and `terraform.tfstate.*` — Contains resource IDs, sensitive data, and potentially encrypted credentials
- `.terraform/` — Contains downloaded provider binaries and modules
- `.terraform.lock.hcl` — Not strictly sensitive but should be in git (see recommendations)
- `*.tfvars` files with secrets — Use environment variables or separate secrets management instead
- `.aws/` credentials files — Never store AWS credentials in the repo
- `.env` files — May contain API keys or secrets

All of these are already configured in `.gitignore`.

## AWS Security Best Practices

### 1. **Credentials Management**
- **Current state:** No hardcoded credentials in this repo ✅
- **Best practice:** Use AWS credentials from environment or AWS profiles
  - GitHub Actions: Use [AWS credentials action](https://github.com/aws-actions/configure-aws-credentials) with OIDC or short-lived tokens
  - Local development: Use `~/.aws/credentials` and `~/.aws/config` (not in repo)
- **Never:**
  - Commit AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY
  - Use long-lived access keys in CI/CD (use temporary STS credentials)

### 2. **ACM Certificates & Domain ARNs**
- The `acm_certificate_arn` variable can store sensitive ARNs
- If you set a custom domain, store the certificate ARN in GitHub Secrets, not in `terraform.tfvars`
- Example GitHub Actions workflow:
  ```yaml
  env:
    TF_VAR_acm_certificate_arn: ${{ secrets.ACM_CERT_ARN }}
  ```

### 3. **Route53 Zone IDs**
- The `route53_zone_id` variable exposes your zone configuration
- Keep it in `terraform.tfvars` only for local testing
- In CI/CD, pass via environment or secrets

### 4. **S3 Bucket Naming**
- S3 bucket names are globally unique and publicly visible
- The module appends a random suffix to avoid collisions
- Don't use sensitive info in bucket names (e.g., company name, environment type)

### 5. **CloudFront & Public Access**
- S3 bucket is **private** — only accessible via CloudFront OAC ✅
- CloudFront distribution is public by design (serves your website)
- Files in S3 cannot be accessed directly; they're protected by bucket policy ✅

### 6. **State File Security (When You Run Terraform)**
- Local state files (`terraform.tfstate`) contain sensitive data
- For team/CI workflows, migrate to remote state:
  ```hcl
  # Add to environments/dev/backend.tf
  terraform {
    backend "s3" {
      bucket         = "your-terraform-state-bucket"
      key            = "dev/terraform.tfstate"
      region         = "us-east-1"
      encrypt        = true
      dynamodb_table = "terraform-locks"
    }
  }
  ```
- Enable S3 versioning and server-side encryption on the state bucket

## Terraform Module Security

### S3 Module ([infrastructure/terraform/modules/s3-static-site](infrastructure/terraform/modules/s3-static-site))
- ✅ Block all public access by default
- ✅ Enable server-side encryption (AES-256)
- ✅ Enable versioning (configurable)
- ✅ Ownership controls enforced

### CloudFront Module ([infrastructure/terraform/modules/cloudfront-static-site](infrastructure/terraform/modules/cloudfront-static-site))
- Uses Origin Access Control (OAC) to restrict S3 access
- S3 bucket policy only allows CloudFront to read objects ✅
- Verify in [infrastructure/terraform/environments/dev/main.tf](infrastructure/terraform/environments/dev/main.tf#L88) that the policy restricts by distribution ARN

## GitHub Repository Settings

### Recommended Actions
1. **Protect main branch:**
   - Enable branch protection rules
   - Require pull request reviews
   - Dismiss stale reviews when new commits are pushed

2. **Limit access:**
   - Make repository private if it contains company/sensitive infrastructure details
   - Use GitHub Teams for access control

3. **Secret scanning:**
   - Enable GitHub's built-in secret scanning
   - Consider third-party tools like `TruffleHog` in CI

4. **Dependency scanning:**
   - Enable Dependabot alerts for Terraform providers

## CI/CD Best Practices (When You Add GitHub Actions)

```yaml
# Example: Safe secrets handling in GitHub Actions
jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::ACCOUNT:role/GitHubActionsRole
          aws-region: us-east-1
      - run: |
          cd infrastructure/terraform/environments/dev
          terraform init
          terraform plan -var-file=terraform.tfvars
          # Do NOT output sensitive values in logs
```

## Content Security Recommendations

### For `index.html` & `features.html`
- ✅ No sensitive data is served
- Ensure no analytics or tracking that exposes user data
- Add security headers via CloudFront:
  ```hcl
  # In CloudFront module
  custom_header {
    header_name  = "Strict-Transport-Security"
    header_value = "max-age=31536000; includeSubDomains"
  }
  ```

## Audit Checklist Before Public Release

- [ ] No AWS credentials in any committed files
- [ ] No `.tfstate` files in repo history (check `git log`)
- [ ] `.gitignore` is properly configured
- [ ] CloudFront distribution restricts S3 access to OAC only
- [ ] S3 bucket has versioning and encryption enabled
- [ ] Website content (`app/website/`) is public-safe (no internal URLs or secrets)
- [ ] Consider adding a LICENSE file if needed
- [ ] Review AGENTS.md and README.md for any secrets

## Clean Up (Already Done)

The following cleanup was performed:
- ❌ Removed `.terraform/` folder
- ❌ Removed `terraform.tfstate` and backups
- ❌ Removed `.terraform.lock.hcl`
- ✅ Created `.gitignore` with proper rules

## Questions or Additional Hardening?

For sensitive infrastructure, consider:
- Using AWS Secrets Manager for certificate ARNs and zone IDs
- Implementing cost alerts to catch unexpected resource provisioning
- Regularly rotating credentials (if using long-lived keys)
- Using HashiCorp Vault or AWS Secrets Manager for multi-environment secret management
