resource "aws_dynamodb_table" "AppDB" {
  name           = "KCHMatumainiDB"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "ChildId"

  attribute {
    name = "ChildId"
    type = "S"
  }

  attribute {
    name = "PrimarySecondary"
    type = "S"
  }

  attribute {
    name = "Sponsored"
    type = "S"
  }


  global_secondary_index {
    name               = "SponsoredIndex"
    hash_key           = "Sponsored"
    range_key          = "ChildId"
    write_capacity     = 5
    read_capacity      = 5
    projection_type    = "INCLUDE"
    non_key_attributes = ["ChildId"]
  }
  
    global_secondary_index {
    name               = "PrimarySecondaryIndex"
    hash_key           = "PrimarySecondary"
    range_key          = "ChildId"
    write_capacity     = 5
    read_capacity      = 5
    projection_type    = "INCLUDE"
    non_key_attributes = ["ChildId"]
  }

}