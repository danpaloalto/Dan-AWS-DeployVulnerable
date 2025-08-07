variable "vpc_id" {
  description = "The ID of the VPC where resources will be deployed."
  type        = string
  default     = "vpc-060788fed16db44f3"
}

variable "subnet_id" {
  description = "The ID of the public subnet where resources will be deployed."
  type        = string
  default     = "subnet-0cf91d99424e8500d"
}

variable "iam_instance_profile_name" {
  description = "The name of the IAM instance profile for the EC2 instance."
  type        = string
  default     = "insecure-instance-profile"
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance."
  type        = string
  default     = "ami-084a7d336e816906b"
}

variable "insecure_sg_id" {
  description = "The ID of the insecure security group to associate with resources."
  type        = string
  default     = "sg-0f6252efa77a0004a" 
}
