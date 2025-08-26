provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name      = "test-vpc-for-state-save"
    yor_trace = "2b15f376-cf5f-458f-ab3f-62d6ed07117c"
  }
}

resource "aws_subnet" "test_subnet" {
  vpc_id            = aws_vpc.test_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name      = "test-subnet-for-state-save"
    yor_trace = "d043c27e-7a95-4de9-a553-2a20536be74e"
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
    yor_trace = "8be4d9a2-8967-497e-97f8-3ca9fb6f42d8"
  }
}
