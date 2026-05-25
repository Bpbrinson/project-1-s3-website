# Project-1 S3 Static Site

A simple portfolio project demonstrating how to deploy a static website using Terraform, an S3 bucket, and CloudFront.

## Overview
- Terraform provisions the S3 bucket, CloudFront distribution, and optional Route53 record.
- The S3 module can upload local website files into the bucket during `terraform apply`.

## Local preview
From the repository root, preview the site locally:

```powershell
cd app\website
python -m http.server 8000
# then open http://localhost:8000
```

Live preview pages included:
- `index.html` — main test page: [app/website/index.html](app/website/index.html#L1)
- `features.html` — explains benefits of Terraform+S3+CloudFront: [app/website/features.html](app/website/features.html#L1)

## Terraform (dev environment)
The development environment configuration is in `infrastructure/terraform/environments/dev`.

Key files:
- [infrastructure/terraform/environments/dev/main.tf](infrastructure/terraform/environments/dev/main.tf#L1)
- [infrastructure/terraform/environments/dev/terraform.tfvars](infrastructure/terraform/environments/dev/terraform.tfvars#L1)

The S3 module supports optional file uploads. To upload the `app/website` files on `terraform apply` ensure in `terraform.tfvars`:

```hcl
upload_files = true
website_directory = "../../../../app/website"
```

Apply the dev environment:

```powershell
cd infrastructure\terraform\environments\dev
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

After a successful apply the module will create the S3 bucket and upload `index.html`, `features.html`, and any other files under `app/website`.

### Automatic CloudFront invalidation

When `upload_files = true` the Terraform setup will upload files and automatically request a CloudFront invalidation so updated content is served. Requirements:

- The machine running `terraform apply` must have the AWS CLI installed and configured with credentials that allow `cloudfront:CreateInvalidation`.
- The invalidation is implemented via a `null_resource` that calls `aws cloudfront create-invalidation` after objects are uploaded. This runs locally during `terraform apply` and will not execute if `upload_files` is `false`.

Notes and recommendations:
- In CI, inject AWS credentials using repository secrets and the `aws-actions/configure-aws-credentials` action before running Terraform.
- Consider using cache-busting (versioned asset filenames) for frequent updates to avoid heavy invalidation usage.
- CloudFront invalidations may incur costs if used excessively; prefer targeted invalidation paths or versioned assets when possible.

## Files & structure
- app/website/index.html — Main test page showing deployment status. ([app/website/index.html](app/website/index.html#L1))
- app/website/features.html — Benefits of using Terraform + S3 + CloudFront. ([app/website/features.html](app/website/features.html#L1))
- infrastructure/terraform/modules/s3-static-site — S3 module that optionally uploads files.

## Next steps (suggestions)
- Add a CI/CD workflow to run Terraform and/or publish files automatically.
- Add a `Makefile` or script to sync local files to S3 for quick testing.
- Add automated invalidation for CloudFront when files change.

If you want, I can add a GitHub Actions workflow to run Terraform and publish files on push.

## Configuring `terraform.tfvars`

This project requires a `terraform.tfvars` file in the environment folder to provide environment-specific values. Do NOT commit your `terraform.tfvars` into source control — it can contain sensitive configuration. Use `.gitignore` (already provided) or store values in CI secrets.

Example `terraform.tfvars` (replace the sample values below with your own):

```hcl
# development environment
environment = "dev"

# s3 configuration
versioning_enabled = true
upload_files       = true

# Website Location
website_directory = "../../../../app/website"

# CloudFront configuration
default_root_object = "index.html"
price_class         = "PriceClass_100"
enable_spa_routing  = false
tags = {
	Owner = "YourName"
}

# Required values to enable a public site with a custom domain
project_name          = "my-portfolio"
bucket_name           = "my-unique-bucket-name"
domain_name           = "example.com"                       # your domain
acm_certificate_arn   = "arn:aws:acm:us-east-1:123456789012:certificate/EXAMPLE"  # ACM cert ARN (must be in us-east-1)
route53_zone_id       = "Z123456ABCDEF"                    # Hosted Zone ID where the domain is managed
create_route53_record = true                                   # set to true to create the alias record

# Optional
acm_certificate_arn   = ""  # leave blank if you don't use a custom domain
route53_zone_id       = ""  # leave blank if you don't create a Route53 record
```

Notes on the important fields:
- `domain_name` — the DNS name you want to serve the site from (e.g., `example.com`). Leave blank to use CloudFront's default domain.
- `acm_certificate_arn` — the ARN for an ACM certificate for your domain. Important: CloudFront requires the certificate to be in the `us-east-1` (N. Virginia) region.
- `route53_zone_id` — the Hosted Zone ID in Route53 where the domain record will be created. Required when `create_route53_record = true`.
- `project_name` — used for resource tagging and naming.
- `bucket_name` — base name used for the S3 bucket. The module appends a short random suffix to guarantee uniqueness; avoid including secret or identifying information in the bucket name.
- `create_route53_record` — must be `true` to instruct Terraform to create an alias A record pointing your domain to the CloudFront distribution. If `true`, also provide `route53_zone_id` and `domain_name`.

Security recommendations:
- Keep `terraform.tfvars` out of version control. Use CI secrets or environment variables for sensitive values when running in CI.
- If you want to store Terraform state for team collaboration, configure a remote backend (S3 + DynamoDB) instead of local `terraform.tfstate`.
- When running in CI (GitHub Actions), inject sensitive values via repository secrets and avoid printing them in logs.
