variable "vpc_id" {
  description = "The ID of the VPC where resources will be deployed."
  type        = string
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance."
  type        = string
}

variable "subnet_id" {
  description = "The ID of the public subnet where resources will be deployed."
  type        = string
}

variable "iam_instance_profile_name" {
  description = "The name of the IAM instance profile for the EC2 instance."
  type        = string
}

variable "insecure_sg_id" {
  description = "The ID of the insecure security group."
  type        = string
}
