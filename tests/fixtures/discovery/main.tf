provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "acme-tfstate"
  }
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "acme-artifacts"
}
