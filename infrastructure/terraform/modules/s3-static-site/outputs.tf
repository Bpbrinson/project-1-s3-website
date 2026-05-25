output "bucket_id" {
  description = "The ID of the S3 bucket."
  value       = aws_s3_bucket.bucket_name.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = aws_s3_bucket.bucket_name.arn
}

output "bucket_name" {
  description = "The name of the S3 bucket."
  value       = aws_s3_bucket.bucket_name.bucket
}

output "bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket."
  value       = aws_s3_bucket.bucket_name.bucket_regional_domain_name
}

output "website_object_keys" {
  description = "List of uploaded website object keys (when upload_files = true)."
  value       = var.upload_files ? [for o in values(aws_s3_object.website_files) : o.key] : []
}

output "website_object_etags" {
  description = "List of uploaded website object etags (when upload_files = true)."
  value       = var.upload_files ? [for o in values(aws_s3_object.website_files) : o.etag] : []
}