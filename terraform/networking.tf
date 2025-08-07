provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "insecure_vpc" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "insecure-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.insecure_vpc.id

  tags = {
    Name = "insecure-igw"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "10.100.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "insecure-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "10.100.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "insecure-public-b"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.insecure_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "insecure-public-rt"
  }
}

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "insecure_sg" {
  name        = "insecure-sg"
  description = "Wide open security group"
  vpc_id      = aws_vpc.insecure_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
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
    Name = "insecure-open-sg"
  }
}

resource "aws_network_acl" "open_acl" {
  vpc_id = aws_vpc.insecure_vpc.id
  subnet_ids = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "insecure-acl"
  }
}
