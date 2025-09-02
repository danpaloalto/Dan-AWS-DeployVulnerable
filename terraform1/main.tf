provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name      = "test-vpc-for-state-save"
    yor_trace = "3a479b73-ad38-4c05-9f98-ed504af5a719"
  }
}

resource "aws_subnet" "test_subnet" {
  vpc_id            = aws_vpc.test_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name      = "test-subnet-for-state-save"
    yor_trace = "b1a02c62-c116-4daf-ae99-d097b3723b4f"
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
    yor_trace = "11e08264-45a5-467d-afc5-53d9c2184275"
  }
}
