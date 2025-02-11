terraform {
  #backend "s3" {
  #bucket = "mybucket"
  #key    = "terraform_exercises/import-bootstrap/terraform.tfstate"
  #region = "us-east-1"
  # }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.85.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}


resource "aws_s3_bucket" "terraform_state" {
  bucket        = "terraform-exercises-tf-state"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_bucket_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Lock_ID"

  attribute {
    name = "Lock_ID"
    type = "S"
  }
}