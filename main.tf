terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "random_pet" "lambda_bucket" {
  prefix = "lambda-bucket-"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket.id
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

data "archive_file" "lambda_is_prime" {
  type = "zip"
  source_dir = "${path.module}/is-prime"
  output_path = "${path.module}/is-prime.zip"
}

data "archive_file" "lambda_is_par" {
  type = "zip"
  source_dir = "${path.module}/is-par"
  output_path = "${path.module}/is-par.zip"
}

resource "aws_s3_object" "lambda_is_prime" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key = "is-prime.zip"
  source = data.archive_file.lambda_is_prime.output_path
  etag = filemd5(data.archive_file.lambda_is_prime.output_path)
}

resource "aws_s3_object" "lambda_is_par" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key = "is-par.zip"
  source = data.archive_file.lambda_is_par.output_path
  etag = filemd5(data.archive_file.lambda_is_par.output_path)
}

resource "aws_lambda_function" "is_prime" {
  function_name = "is-prime"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key = aws_s3_object.lambda_is_prime.key
  runtime = "nodejs14.x"
  handler = "is-prime.handler"
  source_code_hash = data.archive_file.lambda_is_prime.output_base64sha256
  role = aws_iam_role.lambda_exec.arn
}

resource "aws_lambda_function" "is_par" {
  function_name = "is-par"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key = aws_s3_object.lambda_is_par.key
  runtime = "nodejs14.x"
  handler = "is-par.handler"
  source_code_hash = data.archive_file.lambda_is_par.output_base64sha256
  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "is_prime" {
  name = "/aws/lambda/${aws_lambda_function.is_prime.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "is_par" {
  name = "/aws/lambda/${aws_lambda_function.is_par.function_name}"
  retention_in_days = 14
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda_api" {
  api_id = aws_apigatewayv2_api.lambda_api.id

  name        = "lambda_api_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "is_prime" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_method = "POST"
  integration_uri  = aws_lambda_function.is_prime.invoke_arn
} 

resource "aws_apigatewayv2_integration" "is_par" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_method = "POST"
  integration_uri  = aws_lambda_function.is_par.invoke_arn
}

resource "aws_apigatewayv2_route" "is_prime" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /is-prime"
  target = "integrations/${aws_apigatewayv2_integration.is_prime.id}"
}

resource "aws_apigatewayv2_route" "is_par" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /is-par"
  target = "integrations/${aws_apigatewayv2_integration.is_par.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda_api.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.is_prime.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda_api.execution_arn}//"
}

resource "aws_lambda_permission" "api_gw_is_par" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.is_par.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda_api.execution_arn}//"
}