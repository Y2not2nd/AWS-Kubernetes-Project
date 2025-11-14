resource "aws_dynamodb_table" "yasn_ticket_metadata" {
  name         = "yasn_ticket_metadata"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "ticket_id"

  attribute {
    name = "ticket_id"
    type = "S"
  }
}
