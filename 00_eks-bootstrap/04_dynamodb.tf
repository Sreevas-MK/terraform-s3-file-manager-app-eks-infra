resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table
  billing_mode = "PAY_PER_REQUEST" # pay only when Terraform uses it
  hash_key     = "LockID"          # This table will be indexed using a primary key called LockID

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-terraform-locks"
    Project     = var.project_name
    Environment = var.project_environment
  }
}

