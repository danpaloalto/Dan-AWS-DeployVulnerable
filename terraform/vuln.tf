###############################################
# INTENTIONALLY INSECURE TERRAFORM (AWS)
# - Public S3 bucket without enforced encryption
# - EC2 instance that does NOT require IMDSv2 (IMDSv1 allowed)
# NOTE: For testing CNAPP findings only. Do NOT use in prod.
###############################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_prefix" {
  description = "Name prefix for resources"
  type        = string
  default     = "insecure-minimal"
}

###############################################
# S3: PUBLIC, no default encryption configured
# (AWS encrypts data at rest by default service-side,
# but this bucket does NOT enforce SSE via a bucket policy
# or default encryption configuration, which most CNAPPs flag.)
###############################################
resource "random_id" "suffix" {
  byte_length = 2
}

locals {
  bucket_name = "${var.project_prefix}-${random_id.suffix.hex}"
}

resource "aws_s3_bucket" "public" {
  bucket        = local.bucket_name
  force_destroy = true
  tags = {
    Name   = local.bucket_name
    Intent = "INTENTIONALLY-INSECURE"
  }
}

# Disable the public access block (bad)
resource "aws_s3_bucket_public_access_block" "public" {
  bucket                  = aws_s3_bucket.public.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Legacy ACL to make objects public (bad)
resource "aws_s3_bucket_ownership_controls" "public" {
  bucket = aws_s3_bucket.public.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "public" {
  depends_on = [
    aws_s3_bucket_public_access_block.public,
    aws_s3_bucket_ownership_controls.public
  ]
  bucket = aws_s3_bucket.public.id
  acl    = "public-read"
}

# Bucket policy allowing anonymous reads (bad)
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.public.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "PublicReadGetObject",
      Effect    = "Allow",
      Principal = "*",
      Action    = ["s3:GetObject"],
      Resource  = ["${aws_s3_bucket.public.arn}/*"]
    }]
  })
}

# Upload a sample public object
resource "aws_s3_object" "sample" {
  bucket       = aws_s3_bucket.public.id
  key          = "README.txt"
  content      = "This is intentionally public."
  content_type = "text/plain"
  acl          = "public-read"
}

###############################################
# EC2: Public instance with IMDSv2 NOT required (IMDSv1 allowed)
###############################################
# Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.project_prefix}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${var.project_prefix}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = { Name = "${var.project_prefix}-public" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_prefix}-rt" }
}

resource "aws_route_table_association" "assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Minimal SG with SSH exposed to the world (optional but helps test)
resource "aws_security_group" "ssh_open" {
  name   = "${var.project_prefix}-ssh-open"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "no_imdsv2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ssh_open.id]
  associate_public_ip_address = true

  # IMDSv2 NOT required (bad): allows IMDSv1
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"   # <- this disables IMDSv2 enforcement
    http_put_response_hop_limit = 1
  }

  tags = {
    Name   = "${var.project_prefix}-ec2-no-imdsv2"
    Intent = "INTENTIONALLY-INSECURE"
  }
}

###############################################
# Outputs
###############################################
output "bucket_name" {
  value = aws_s3_bucket.public.bucket
}

output "sample_object_url" {
  value = "https://${aws_s3_bucket.public.bucket}.s3.amazonaws.com/${aws_s3_object.sample.key}"
}

output "ec2_public_ip" {
  value = aws_instance.no_imdsv2.public_ip
}
