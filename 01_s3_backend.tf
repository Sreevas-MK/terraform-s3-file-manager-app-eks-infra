terraform {
  backend "s3" {
    bucket         = "s3-nodeapp-project-terraform-state-0001"
    key            = "s3-node-app/s3-node-app.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "s3-nodeapp-project-terraform-locks-0001"
    encrypt        = true
  }
}

