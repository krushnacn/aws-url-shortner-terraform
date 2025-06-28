output "api_endpoint" {
  value = aws_apigatewayv2_api.api.api_endpoint
}

output "db_endpoint" {
  value = aws_db_instance.mysql.address
}