###############################################
# ⚠️ INTENTIONALLY INSECURE AWS TERRAFORM ⚠️
# Purpose: Trigger CNAPP findings (Prisma/Cortex, etc.)
# DO NOT USE IN PROD. EXPECT BILLING CHARGES.
# Destroy when done:  terraform destroy -auto-approve
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

###############################################
# Variables
###############################################
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_prefix" {
  description = "Name prefix for resources"
  type        = string
  default     = "insecure-demo"
}

###############################################
# Networking (public VPC)
###############################################
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.project_prefix}-vpc"
    yor_trace = "ff75b5fd-78b3-4db2-b601-4628bf001cad"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${var.project_prefix}-igw"
    yor_trace = "856749e2-e822-40e9-8fb2-aeada2ad265b"
  }
}

# Two public subnets (so RDS subnet group is valid)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = { Name = "${var.project_prefix}-public-a"
    yor_trace = "13028472-34a1-4f4b-a9a9-9c97fe852b9a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = { Name = "${var.project_prefix}-public-b"
    yor_trace = "88834c53-97d6-46c5-b59d-afc238400ac4"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_prefix}-public-rt"
    yor_trace = "87b11a2e-360e-4656-a8fc-a12366e328c0"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

###############################################
# Security Groups (overly permissive)
###############################################
resource "aws_security_group" "insecure_all" {
  name        = "${var.project_prefix}-insecure-sg"
  description = "INTENTIONALLY open to the world"
  vpc_id      = aws_vpc.main.id

  # Wide-open TCP
  ingress {
    description = "All TCP open to the world"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Wide-open UDP
  ingress {
    description = "All UDP open to the world"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Wide-open ICMP
  ingress {
    description = "All ICMP open to the world"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_prefix}-insecure-sg"
    yor_trace = "6623684f-2a26-4e6e-8816-42316e855740"
  }
}

###############################################
# IAM (over-privileged instance role and user WITHOUT MFA)
###############################################
resource "aws_iam_role" "ec2_admin_role" {
  name               = "${var.project_prefix}-ec2-admin-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
  tags = {
    yor_trace = "7df76a7e-c9db-47d5-81bc-12d9d4b094e7"
  }
}

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Attach full AdministratorAccess (very bad on purpose)
resource "aws_iam_role_policy_attachment" "admin_attach" {
  role       = aws_iam_role.ec2_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_prefix}-ec2-profile"
  role = aws_iam_role.ec2_admin_role.name
  tags = {
    yor_trace = "a5424da1-3684-4cf4-ab14-fed1725fd540"
  }
}

# Break-glass user without MFA and with admin wildcard policy (bad)
resource "aws_iam_user" "breakglass" {
  name = "${var.project_prefix}-breakglass"
  tags = { Purpose = "INTENTIONALLY-INSECURE"
    yor_trace = "fc49ceb3-fb9c-4063-9d44-59060a63f122"
  }
}

resource "aws_iam_user_policy" "breakglass_admin" {
  name = "${var.project_prefix}-breakglass-admin"
  user = aws_iam_user.breakglass.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "*",
      Resource = "*"
    }]
  })
}

###############################################
# EC2 (public, IMDSv1 enabled, user-data with plaintext secret)
###############################################
# Latest Ubuntu 22.04 LTS
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

resource "aws_instance" "insecure" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.insecure_all.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  # IMDSv1 enabled (bad):
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional" # allows IMDSv1
    http_put_response_hop_limit = 1
  }

  user_data = <<-EOT
              #!/bin/bash
              echo "PLAINTEXT_API_KEY=sk-test-1234567890" >> /etc/environment
              echo "SSN: 123-45-6789" > /home/ubuntu/pii.txt
              chmod 644 /home/ubuntu/pii.txt
              EOT

  tags = {
    Name      = "${var.project_prefix}-ec2-public"
    Intent    = "INTENTIONALLY-INSECURE"
    yor_trace = "c46299eb-eded-4570-a851-c390c0058faa"
  }
}

###############################################
# S3 (public bucket, no encryption/versioning, public policy)
###############################################
resource "random_id" "suffix" {
  byte_length = 2
}

locals {
  bucket_name = "${var.project_prefix}-${random_id.suffix.hex}"
}

resource "aws_s3_bucket" "insecure" {
  bucket        = local.bucket_name
  force_destroy = true
  tags = { Name = local.bucket_name, Intent = "INTENTIONALLY-INSECURE"
    yor_trace = "a9e259e3-f2c4-4a14-8440-15d693551389"
  }
}

# Disable recommended public access blocks (bad)
resource "aws_s3_bucket_public_access_block" "insecure" {
  bucket                  = aws_s3_bucket.insecure.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Grant public read via ACL (legacy/bad)
resource "aws_s3_bucket_ownership_controls" "insecure" {
  bucket = aws_s3_bucket.insecure.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "insecure" {
  depends_on = [
    aws_s3_bucket_public_access_block.insecure,
    aws_s3_bucket_ownership_controls.insecure
  ]
  bucket = aws_s3_bucket.insecure.id
  acl    = "public-read"
}

# Public bucket policy (bad)
resource "aws_s3_bucket_policy" "public" {
  bucket = aws_s3_bucket.insecure.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "PublicReadGetObject",
      Effect    = "Allow",
      Principal = "*",
      Action    = ["s3:GetObject"],
      Resource  = ["${aws_s3_bucket.insecure.arn}/*"]
    }]
  })
}

# Upload object with fake PII/secret
resource "aws_s3_object" "pii" {
  bucket       = aws_s3_bucket.insecure.id
  key          = "sample-pii.txt"
  content      = "Name: John Doe\nSSN: 123-45-6789\nAPI_KEY=sk-live-DO_NOT_USE"
  content_type = "text/plain"
  acl          = "public-read"
}

###############################################
# RDS (public, no encryption, weak creds stored in tfstate)
###############################################
resource "aws_db_subnet_group" "public" {
  name       = "${var.project_prefix}-db-subnets"
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  tags = {
    yor_trace = "4e8a56d2-0063-4f1e-ada6-d30c1516fef4"
  }
}

resource "aws_security_group" "rds_open" {
  name   = "${var.project_prefix}-rds-open"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    yor_trace = "7a3db01f-3f20-4d8d-8393-61f09db7a297"
  }
}

resource "aws_db_instance" "insecure" {
  identifier             = "${var.project_prefix}-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "P@ssw0rd123" # stored in state (bad)
  allocated_storage      = 20
  db_subnet_group_name   = aws_db_subnet_group.public.name
  vpc_security_group_ids = [aws_security_group.rds_open.id]
  publicly_accessible    = true  # bad
  storage_encrypted      = false # bad
  skip_final_snapshot    = true
  deletion_protection    = false
  apply_immediately      = true
  tags = {
    yor_trace = "7ef502a0-b7c6-4360-b279-db9c8b41e4a5"
  }
}

###############################################
# CloudWatch Logs (no retention)
###############################################
resource "aws_cloudwatch_log_group" "default" {
  name = "/aws/${var.project_prefix}/app"
  # no retention set (never expires)
  tags = {
    yor_trace = "6433d510-71a9-42c8-9344-045a2c5aaae6"
  }
}

###############################################
# KMS (no rotation)
###############################################
resource "aws_kms_key" "noration" {
  description         = "${var.project_prefix} key without rotation (bad)"
  enable_key_rotation = false
  tags = {
    yor_trace = "13afa3c3-7892-4e38-9ab7-8bfbe7d56fef"
  }
}

###############################################
# Outputs (helpful for testing & dashboards)
###############################################
output "ec2_public_ip" {
  value = aws_instance.insecure.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.insecure.bucket
}

output "rds_endpoint" {
  value = aws_db_instance.insecure.address
}

output "breakglass_user" {
  value = aws_iam_user.breakglass.name
}
