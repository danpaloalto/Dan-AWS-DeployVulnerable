terraform {
  backend "s3" {
    bucket         = "terraform-state-dan-vuln"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-dan-vuln"
    encrypt        = true
  }
}
