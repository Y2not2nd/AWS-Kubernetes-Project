resource "aws_apigatewayv2_api" "yasn_api" {
  name          = "yasn-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "yasn_backend_integration" {
  api_id           = aws_apigatewayv2_api.yasn_api.id
  integration_type = "HTTP_PROXY"
  integration_uri  = var.backend_ingress_url
}

resource "aws_apigatewayv2_stage" "yasn_stage" {
  api_id      = aws_apigatewayv2_api.yasn_api.id
  name        = "prod"
  auto_deploy = true
}

output "api_url" {
  value = aws_apigatewayv2_stage.yasn_stage.invoke_url
}
