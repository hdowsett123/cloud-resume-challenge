variable "region" {}
variable "domain_name" {
  type        = string
  description = "The domain name for the website"
}
variable "bucket_name" {
  type        = string
  description = "The name of the bucket wihtout the www. prefix."
}
variable "common_tags" {
  description = "Common tags you want applied to all components"
}
variable "customer_full_name" {}
variable "cloudfront_price_class" {}
