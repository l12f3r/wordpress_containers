# lizferLinux on containers

For this small project, I want to bring back the [lizferLinux Wordpress blog](https://github.com/l12f3r/lizferLinux) (who went down due to lack of payment to Digital Ocean), but without all the hassle of configuring a LAMP environment - I will provision a Wordpress environment using containers, consuming from MariaDB (in AWS Aurora).

As usual:
- `providers.tf` contains data on the cloud services provider and region; 
- `variables.tf` has all variables declared; 
- `parameters.auto.tfvars` has all data to avoid hardcoding.

### 1. Create an IAM user

For security reasons, it's good practice to create an specific user on IAM with the proper permission to run the necessary tasks via command line. In order to not use the credentials for the AWS account, make sure to follow the [IAM account creation section](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/get-set-up-for-amazon-ecs.html#create-an-iam-user) on the "Setting up with Amazon ECS" guide.

Since that I am not intending to use the EC2 launch type, no key pair will be provisioned.

Thankfully, it is possible to create this user under your account (with all policy and group associations) using Terraform:

```terraform
#main.tf
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
```

### 2. Creating the network environment

I'll keep with a simple `aws_default_vpc` resource, that will change the default VPC. This must be enabled because we are accessing it via CLI, not the ECS console.

On top of that, I am adding the `aws_availability_zones` data source, so the access to the list of all available AZs on that region would be provided right away.

On `main.tf`, our main code file, we'll define networking by the following lines:

```terraform
#main.tf
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
```



