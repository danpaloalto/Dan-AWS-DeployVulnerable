## insecure-iam.tf

resource "aws_iam_user" "insecure_user" {
  name = "insecure-user"
  # No MFA enforced
  tags = {
    yor_trace = "2d8608b9-6783-4bbc-85b6-4ca74fa0b3ed"
  }
}

resource "aws_iam_access_key" "insecure_user_key" {
  user = aws_iam_user.insecure_user.name
}

resource "aws_iam_policy" "insecure_policy" {
  name        = "insecure-policy"
  description = "Overly permissive policy to trigger CNAPP findings"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
  tags = {
    yor_trace = "6c0d5f01-0e11-4dc2-8bf0-bd6a30f58475"
  }
}

resource "aws_iam_role" "insecure_role" {
  name = "insecure-role"
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
  tags = {
    yor_trace = "0dd751cf-4618-4731-9348-238f8fd793f8"
  }
}

resource "aws_iam_role_policy_attachment" "insecure_role_attach" {
  role       = aws_iam_role.insecure_role.name
  policy_arn = aws_iam_policy.insecure_policy.arn
}

resource "aws_iam_instance_profile" "insecure_instance_profile" {
  name = "insecure-instance-profile"
  role = aws_iam_role.insecure_role.name
  tags = {
    yor_trace = "397a4973-380f-477b-a895-8f630c4acf46"
  }
}
