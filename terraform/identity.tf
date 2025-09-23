## insecure-iam.tf

resource "aws_iam_user" "insecure_user" {
  name = "insecure-user"
  # No MFA enforced
  tags = {
    yor_trace = "dafed4c1-f19b-4b7c-a95d-161a4dae36f2"
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
    yor_trace = "8d6ab2fc-b01f-42ff-9f1a-7ddcaba7f08c"
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
    yor_trace = "b6b25f65-9ced-4df2-bbaf-eddc8e26b620"
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
    yor_trace = "614af9a8-9a19-4820-996c-4db24ca0f86d"
  }
}
