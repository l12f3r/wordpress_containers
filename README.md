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

### 3. Creating the security group

Once again, I am using a default resource (`default_security_group`) in order to keep things simple and use the default security group. Whenever this resource is used, it removes all ingress and egress rules for the SG and adopts the rules stated on this code.

HTTP and HTTPS ingress rules have public `cidr_blocks` values, but only for testing purposes - on a production environment, such values must be switched to a specific range of IP addresses.

```terraform
#main.tf
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
```

### 4. ECR repository provisioning

The Docker images should be stored on an Elastic Container Registry repository. Those can be provided and configured on Terraform as well.

Image tag mutability (define if images can be overwritten or not) and scan on push (configure image scans whenever images are pushed) are defined on the code excerpt below:

```terraform
#main.tf
resource "aws_ecr_repository" "ecr_repo" {
  name = "ECS ECR Repository"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
```