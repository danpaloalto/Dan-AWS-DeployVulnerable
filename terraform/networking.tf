provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "insecure_vpc" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name      = "insecure-vpc"
    yor_trace = "b86e6a19-bdcd-463d-a18a-540895758821"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.insecure_vpc.id

  tags = {
    Name      = "insecure-igw"
    yor_trace = "e624302d-1d74-4551-bd90-3b43884ba0e2"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "10.100.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name      = "insecure-public-a"
    yor_trace = "ec769d04-39b8-4769-b885-915534d7c363"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "10.100.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name      = "insecure-public-b"
    yor_trace = "8c0fc281-8708-4bec-8cde-016c929546f7"
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
    yor_trace = "057125d3-3b22-4bd7-851a-545d52f9e7a9"
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
    yor_trace = "d84809de-6d11-43a2-bf16-a04099cdf65c"
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
    yor_trace = "2e5118f3-f039-4a12-be4d-24e1aaae0585"
  }
}
