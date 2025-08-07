# insecure-iam.tf

resource "aws_iam_user" "insecure_user" {
  name = "insecure-user"
  # No MFA enforced
  tags = {
    yor_trace = "f7b76719-2081-4a03-89c7-e7513139bb5a"
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
    yor_trace = "492ae23e-af82-4d9d-8105-4192b765bba6"
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
    yor_trace = "0a78404e-ac00-415b-adef-b2ed90d372aa"
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
    yor_trace = "d0486cfa-1ec8-4a37-b3f5-ef5426fd28fa"
  }
}
