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

resource "aws_default_security_group" "sg" {
  vpc_id = aws_default_vpc.vpc.id

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidr_blocks = var.shSSHCIDRBlock
  }

  ingress {
    protocol  = "tcp"
    self      = true
    from_port = 443
    to_port   = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol  = "tcp"
    self      = true
    from_port = 80
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
}
