# vulnerableinst

provider "aws" {
  region = "us-east-1"
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "pii_bucket" {
  bucket        = "prisma-pii-demo-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_object" "pii_file" {
  bucket  = aws_s3_bucket.pii_bucket.id
  key     = "ssn_data.csv"
  content = <<CSV
name,ssn
Alice,123-45-6789
Bob,987-65-4321
CSV
}

resource "aws_iam_role" "vuln_role" {
  name = "vuln-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "vuln_policy" {
  name        = "VulnEC2Policy"
  description = "Overprivileged policy for EC2 instance"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.pii_bucket.arn,
          "${aws_s3_bucket.pii_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "secretsmanager:ListSecrets",
          "iam:ListRoles"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.vuln_role.name
  policy_arn = aws_iam_policy.vuln_policy.arn
}

resource "aws_iam_instance_profile" "vuln_profile" {
  name = "vuln-instance-profile"
  role = aws_iam_role.vuln_role.name
}

resource "aws_vpc" "vuln_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vuln_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vuln_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vuln_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "vuln_sg" {
  name        = "vuln-sg"
  description = "Open SSH and HTTP"
  vpc_id      = aws_vpc.vuln_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_instance" "vuln_box" {
  ami                         = "ami-0fc5d935ebf8bc3bc"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.vuln_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.vuln_profile.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  user_data = <<EOF
#!/bin/bash
apt-get update -y
apt-get install -y python2 openssl nginx curl awscli
curl -o /tmp/ssn_data.csv https://s3.amazonaws.com/${aws_s3_bucket.pii_bucket.bucket}/ssn_data.csv
aws s3 cp s3://${aws_s3_bucket.pii_bucket.bucket}/ssn_data.csv /tmp/
EOF

  tags = {
    Name = "vuln-ubuntu"
  }
}

output "instance_public_ip" {
  value = aws_instance.vuln_box.public_ip
}

output "bucket_name" {
  value = aws_s3_bucket.pii_bucket.bucket
}
