## insecure-iam.tf

# --- Highly Insecure IAM User and Keys ---
resource "aws_iam_user" "insecure_user" {
  name = "insecure-user"
  # VULNERABILITY: No MFA enforced or required for the user.
}

resource "aws_iam_access_key" "insecure_user_key" {
  user = aws_iam_user.insecure_user.name
  # VULNERABILITY: No key rotation mechanisms or key age limitations are enforced.
  # This key will be created and printed to the Terraform state file.
}

# VULNERABILITY: A login profile with a simple, hardcoded password.
resource "aws_iam_user_login_profile" "insecure_login_profile" {
  user                    = aws_iam_user.insecure_user.name
  password_reset_required = false
  password                = "Password123!" # Hardcoded, weak password
}


# --- Overly Permissive Policy Attachment ---
resource "aws_iam_policy" "insecure_policy" {
  name        = "insecure-policy"
  description = "Overly permissive policy to trigger CNAPP findings"
  # VULNERABILITY: Use of '*' for both Action and Resource (Admin access)
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
}


# --- Insecure Role and Trust Policy ---
resource "aws_iam_role" "insecure_role" {
  name = "insecure-role"
  # VULNERABILITY: Allows *any* EC2 instance to assume this role.
  # A malicious party with control of *any* EC2 instance could assume it.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        # VULNERABILITY: Missing 'Condition' blocks to limit the assumption to specific instances (e.g., using source VPC or external ID).
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "insecure_role_attach" {
  role       = aws_iam_role.insecure_role.name
  policy_arn = aws_iam_policy.insecure_policy.arn
  # VULNERABILITY: Attaching the "insecure_policy" (full admin) to the "insecure_role".
}

resource "aws_iam_instance_profile" "insecure_instance_profile" {
  name = "insecure-instance-profile"
  role = aws_iam_role.insecure_role.name
  # VULNERABILITY: Making the admin-level role available to any instance using this profile.
}

# --- Resource-Based Policy with Wildcard Principal ---
resource "aws_iam_policy" "external_access_policy" {
  name        = "external-access-policy"
  description = "Policy allowing access from any AWS account"
  # VULNERABILITY: Allows access from *any* principal (unauthenticated or any AWS account)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*" # MAJOR VULNERABILITY: Allows access to the attached resource from any principal.
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::example-insecure-bucket-name/*"
      }
    ]
  })
}

# --- Role with Trust to an External AWS Account ---
resource "aws_iam_role" "external_trust_role" {
  name = "external-trust-role"
  # VULNERABILITY: Trusts a specific external AWS Account without using an ExternalId.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::111122223333:root" # Example external account, replace with a valid ID if needed.
        }
        Action = "sts:AssumeRole"
        # VULNERABILITY: Lack of an External ID makes this vulnerable to the confused deputy problem.
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_trust_attach" {
  role       = aws_iam_role.external_trust_role.name
  policy_arn = aws_iam_policy.insecure_policy.arn # Attaching the full admin policy again.
}