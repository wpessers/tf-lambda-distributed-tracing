resource "aws_dynamodb_table" "mission" {
  name           = "Mission"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "RocketName"
    type = "S"
  }

  hash_key = "RocketName"
}

