resource "aws_dynamodb_table" "mission" {
  name           = "mission"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "rocketName"
    type = "S"
  }

  hash_key = "rocketName"
}

