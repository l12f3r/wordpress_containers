resource "aws_iam_user" "admin_ecs_user" {
  name = "Administrator"
}

resource "aws_iam_group" "admin_ecs_user_group" {
  name = "Administrators"
}

resource "aws_iam_policy" "admin_ecs_policy" {
  name = "AdministratorAccess"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_group_policy_attachment" "admin_ecs_group_policy_attachment" {
  group      = aws_iam_group.admin_ecs_user_group.name
  policy_arn = aws_iam_policy.admin_ecs_policy.arn
}

resource "aws_iam_group_membership" "admin_ecs_group_membership" {
  name = "ECS IAM group"
  users = aws_iam_user.admin_ecs_user.name
  group = aws_iam_group.admin_ecs_user_group.name
}

data "aws_availability_zones" "azs" {
  all_availability_zones = true

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "aws_default_vpc" "vpc" {
  tags = {
    Name = "Default VPC for ECS usage"
  }
}

