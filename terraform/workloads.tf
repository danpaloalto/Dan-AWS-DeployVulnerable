# insecure-compute.tf

# Security Group: open inbound and outbound traffic (insecure)
resource "aws_security_group" "insecure_sg" {
  name        = "insecure-sg"
  description = "Allow all inbound and outbound traffic (insecure)"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    yor_trace = "93c71c81-b9f0-4e6b-ad8c-cfcead4964ed"
  }
}

# EC2 instance with vulnerable packages installed via user_data
resource "aws_instance" "insecure_ec2" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.insecure_sg.id]
  iam_instance_profile        = var.iam_instance_profile_name
  associate_public_ip_address = true

  root_block_device {
    volume_type = "standard" # Unencrypted magnetic storage
    volume_size = 8
    encrypted   = false
  }

  user_data = <<-EOF
              #!/bin/bash
              # Install vulnerable versions of packages (example for Ubuntu)
              apt-get update -y
              apt-get install -y --allow-downgrades \
                openssh-server=1:7.2p2-4ubuntu2.8 \
                nginx=1.10.3-0ubuntu0.16.04.5 \
                curl=7.47.0-1ubuntu2.19
              # Disable automatic updates to keep vulnerabilities
              systemctl stop apt-daily.timer
              systemctl disable apt-daily.timer
              systemctl stop apt-daily-upgrade.timer
              systemctl disable apt-daily-upgrade.timer
              EOF

  tags = {
    Name      = "insecure-ec2"
    yor_trace = "c3841d8d-1b02-42d4-8afd-27200751653d"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "insecure_cluster" {
  name = "insecure-ecs-cluster"
  tags = {
    yor_trace = "ab4dc167-f730-4d89-94b3-400d5d6b58a6"
  }
}

# ECS Task Definition using a basic sample image
resource "aws_ecs_task_definition" "insecure_task" {
  family                   = "insecure-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "insecure-container"
      image     = "amazon/amazon-ecs-sample"
      essential = true
      portMappings = [{
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }]
    }
  ])
  tags = {
    yor_trace = "9e2d9b75-e1e1-468d-b295-a6f5c4ddcf53"
  }
}

# ECS Service with open network config
resource "aws_ecs_service" "insecure_service" {
  name            = "insecure-service"
  cluster         = aws_ecs_cluster.insecure_cluster.id
  task_definition = aws_ecs_task_definition.insecure_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.subnet_id]
    security_groups  = [aws_security_group.insecure_sg.id]
    assign_public_ip = true
  }
  tags = {
    yor_trace = "4416dd23-1c7f-4ab3-960e-0074a7621973"
  }
}
