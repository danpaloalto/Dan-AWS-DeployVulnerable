provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "insecure_vpc" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name      = "insecure-vpc"
    yor_trace = "44c40a11-a18d-432a-8352-9efa387c5838"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.insecure_vpc.id

  tags = {
    Name      = "insecure-igw"
    yor_trace = "9dd95fd2-2476-41f8-86f4-bb8e69a74c85"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "10.100.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name      = "insecure-public-a"
    yor_trace = "8621760f-a52c-46e5-871d-7233affa8afe"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "10.100.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name      = "insecure-public-b"
    yor_trace = "303a06fb-c9ed-4e01-a36c-d8cbbd6d8c07"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.insecure_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name      = "insecure-public-rt"
    yor_trace = "af5cfee3-02c0-441f-8420-082162d78ca5"
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

# Renamed from open_sg to insecure_open_sg to avoid resource name conflicts
resource "aws_security_group" "insecure_open_sg" {
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
    Name      = "insecure-open-sg"
    yor_trace = "2f096223-29f0-41fe-9e78-3cc440177065"
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
    Name      = "insecure-acl"
    yor_trace = "eea72900-08e1-4d52-9b1b-9de6b9c888bd"
  }
}
