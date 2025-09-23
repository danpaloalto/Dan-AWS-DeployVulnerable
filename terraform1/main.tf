provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name      = "test-vpc-for-state-save"
    yor_trace = "9604c7f2-4c39-4735-b9d2-3f8a861bca9b"
  }
}

resource "aws_subnet" "test_subnet" {
  vpc_id            = aws_vpc.test_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name      = "test-subnet-for-state-save"
    yor_trace = "54388110-d61b-4f34-aa50-6b17ba03b582"
  }
}

resource "aws_security_group" "test_sg" {
  name        = "test-state-save-sg"
  description = "Security group to test Terraform state saving"
  vpc_id      = aws_vpc.test_vpc.id

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
    cidr_blocks = ["0.0.0.0/0"] # Allows all outbound traffic
  }

  tags = {
    Name      = "test-state-save-sg"
    yor_trace = "26951bd0-01ea-482d-a414-2575b7770870"
  }
}
