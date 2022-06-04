#Github Workspace
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

#s3
resource "aws_s3_bucket" "resume-website" {
  bucket        = var.bucket_name
  acl           = "private"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Name = "${var.customer_full_name} Assets"
  }

  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Sid" : "AddPerm",
      "Effect" : "Allow",
      "Principal" : "*",
      "Action" : ["s3:GetObject"],
      "Resource" : ["arn:aws:s3:::${var.bucket_name}/*"]
    }
  ]
}
  EOF
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_s3_bucket_object" "index_html" {
  bucket       = var.bucket_name
  key          = "index.html"
  source       = "cloud-resume-challenge/website"
  content_type = "text/html"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() fu>
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5(path.join(process.env.GITHUB_WORKSPACE, "website", "index.html"))
}

resource "aws_s3_bucket_object" "index_css" {
  bucket       = var.bucket_name
  key          = "index.css"
  source       = "cloud-resume-challenge/website/"
  content_type = "text/css"


  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() fu>
  # etag = "${md5(file("path/to/file"))}"
  # etag = filemd5("cloud-resume-challenge/website/")
}

resource "aws_s3_bucket_object" "error_html" {
  bucket       = var.bucket_name
  key          = "error.html"
  source       = "cloud-resume-challenge/website/"
  content_type = "text/html"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() fu>
  # etag = "${md5(file("path/to/file"))}"
  # etag = filemd5("cloud-resume-challenge/website/")
}

resource "aws_iam_policy" "api_gw-policy" {
  name = "api_gw_s3"

  policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:Put*"
             ],
            "Resource": "*"
        }
    ]
}
EOF
}

#route53
resource "aws_acm_certificate" "harry-dowsett-resume" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "zone" {
  name = var.domain_name
}

data "aws_route53_zone" "zone" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.harry-dowsett-resume.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.harry-dowsett-resume.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

#cloudfront
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "myId"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.resume-website.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.origin_access_identity.id}"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.customer_full_name} Distro"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "${var.bucket_name}.s3.amazonaws.com"
    prefix          = "myprefix"
  }

  aliases = [var.domain_name]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = var.cloudfront_price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    acm_certificate_arn            = aws_acm_certificate.harry-dowsett-resume.arn
    ssl_support_method             = "sni-only"
  }
}

#Dynamodb
resource "aws_dynamodb_table_item" "item" {
  table_name = aws_dynamodb_table.harry-resume-database.name
  hash_key   = aws_dynamodb_table.harry-resume-database.hash_key

  item = <<ITEM
{
  "ID": {"S": "Count"},
  "Visitors": {"N": "0"}
}
ITEM
}

resource "aws_dynamodb_table" "harry-resume-database" {
  name         = "cloud-resume-challenge"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ID"

  attribute {
    name = "ID"
    type = "S"
  }

}

#Lambda
resource "aws_lambda_function" "put-resume" {
  function_name = "ResumePut"

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = "harry-resume-website"
  s3_key    = "put-function.zip"

  # "main" is the filename within the zip file (main.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "put-function.lambda_handler"
  runtime = "python3.9"

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_lambda_function" "get-resume" {
  function_name = "ResumeGet"

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = "harry-resume-website"
  s3_key    = "get-function.zip"

  # "main" is the filename within the zip file (main.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "get-function.lambda_handler"
  runtime = "python3.9"

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role" "lambda_exec" {
  name = "resume_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"},
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "dynamo-policy" {
  name = "dynamodb_lambda"

  policy = <<-EOF
{
  "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "dynamodb:BatchGetItem",
              "dynamodb:GetItem",
              "dynamodb:Scan",
              "dynamodb:Query",
              "dynamodb:BatchWriteItem",
              "dynamodb:PutItem",
              "dynamodb:UpdateItem",
              "dynamodb:DeleteItem"
            ],
            "Resource": "arn:aws:dynamodb:us-east-1:640138429565:table/cloud-resume-challenge"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dynamodb-attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.dynamo-policy.arn
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.resume-api.id
  parent_id   = aws_api_gateway_rest_api.resume-api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.resume-api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_lambda_permission" "get_allow_api" {
  statement_id  = "Allowresume-apiInvokation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get-resume.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.resume-api.execution_arn}/*/*/*"
}


resource "aws_lambda_permission" "put_allow_api" {
  statement_id  = "Allowresume-apiInvokation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.put-resume.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.resume-api.execution_arn}/*/*/*"
}

#APIGateway
resource "aws_api_gateway_rest_api" "resume-api" {
  name = "ResumeAPI"
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "resume-api"
      version = "1.0"
    }
    paths = {
      "/path1" = {
        get = {
          x-amazon-apigateway-integration = {
            httpMethod           = "GET"
            payloadFormatVersion = "1.0"
            type                 = "HTTP_PROXY"
            uri                  = "https://ip-ranges.amazonaws.com/ip-ranges.json"
          }
        }
      }
    }
  })

  endpoint_configuration {
    types = ["EDGE"]
  }
}

resource "aws_api_gateway_integration" "put-lambda" {
  rest_api_id = aws_api_gateway_rest_api.resume-api.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.put-resume.invoke_arn
}

resource "aws_api_gateway_method" "put-proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.resume-api.id
  resource_id   = aws_api_gateway_rest_api.resume-api.root_resource_id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "put-lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.resume-api.id
  resource_id = aws_api_gateway_method.put-proxy_root.resource_id
  http_method = aws_api_gateway_method.put-proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.put-resume.invoke_arn
}

resource "aws_api_gateway_deployment" "put-api" {
  depends_on = [
    aws_api_gateway_integration.put-lambda,
    aws_api_gateway_integration.put-lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.resume-api.id
  stage_name  = "Put-Function"
}

resource "aws_api_gateway_integration" "get-lambda" {
  rest_api_id = aws_api_gateway_rest_api.resume-api.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get-resume.invoke_arn
}

resource "aws_api_gateway_method" "get-proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.resume-api.id
  resource_id   = aws_api_gateway_rest_api.resume-api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get-lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.resume-api.id
  resource_id = aws_api_gateway_method.get-proxy_root.resource_id
  http_method = aws_api_gateway_method.get-proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get-resume.invoke_arn
}

resource "aws_api_gateway_deployment" "get-api" {
  depends_on = [
    aws_api_gateway_integration.get-lambda,
    aws_api_gateway_integration.get-lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.resume-api.id
  stage_name  = "Get-Function"
}

