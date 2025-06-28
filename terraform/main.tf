terraform {
  required_version = ">= 1.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "local" {}
}

provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role_${terraform.workspace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_db_subnet_group" "default" {
  name       = "rds_subnet_group_${terraform.workspace}"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "mysql" {
  identifier         = "mysql-db-${terraform.workspace}"
  engine             = "mysql"
  instance_class     = "db.t3.micro"
  allocated_storage  = 20
  name               = var.db_name
  username           = var.db_user
  password           = var.db_password
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.default.name
  publicly_accessible = true
  vpc_security_group_ids = [var.db_sg_id]
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../src"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "url_shortener" {
  function_name = "url_shortener_${terraform.workspace}"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_exec.arn
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DB_HOST     = aws_db_instance.mysql.address
      DB_USER     = var.db_user
      DB_PASS     = var.db_password
      DB_NAME     = var.db_name
      API_KEY     = var.api_key
    }
  }
}

resource "aws_apigatewayv2_api" "api" {
  name          = "url-shortener-api-${terraform.workspace}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.url_shortener.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.url_shortener.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}