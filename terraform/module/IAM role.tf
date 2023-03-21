data "aws_iam_policy_document" "s3_policy" {
  statement {
    effect  = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "S3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.zyrnj.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.zyrnj.bucket}/*"
    ]
  }
}

resource "aws_iam_policy" "s3_access_policy" {
  name   = "s3-access-policy"
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_attachment" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "example-instance-profile"
  role = aws_iam_role.ec2_role.name
}
