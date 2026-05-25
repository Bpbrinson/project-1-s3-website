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

## Files & structure
- app/website/index.html — Main test page showing deployment status. ([app/website/index.html](app/website/index.html#L1))
- app/website/features.html — Benefits of using Terraform + S3 + CloudFront. ([app/website/features.html](app/website/features.html#L1))
- infrastructure/terraform/modules/s3-static-site — S3 module that optionally uploads files.

## Next steps (suggestions)
- Add a CI/CD workflow to run Terraform and/or publish files automatically.
- Add a `Makefile` or script to sync local files to S3 for quick testing.
- Add automated invalidation for CloudFront when files change.

If you want, I can add a GitHub Actions workflow to run Terraform and publish files on push.
