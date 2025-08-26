## insecure-iam.tf

resource "aws_iam_user" "insecure_user" {
  name = "insecure-user"
  # No MFA enforced
  tags = {
    yor_trace = "049a8186-bfb7-4dec-b2e6-9905cadb4306"
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
    yor_trace = "ab6fb8ff-49bd-440b-a181-57357211f893"
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
    yor_trace = "660e2f4a-008e-4a15-8596-a57fb496f5de"
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
    yor_trace = "80173d8f-3e88-49b1-93ba-6e15027fa5b5"
  }
}
