# Variables set in variables.tf file
provider "aws" {
    region = var.AWSRegion
}

// Create static S3 website
resource "aws_s3_bucket" "StaticWebBucket" {
    bucket  = "${var.BaseS3Bucket}"
    acl = "public-read"
    policy = "${file("configs/website-bucket-policy.json")}"

    website {
    index_document = "index.html"
    error_document = "error.html"
  }
    lifecycle {
      create_before_destroy = true
    }
}

# Build Core Infrastructure:
# VPC with two Availaibility Zones.  Each AZ has one Private subnet, one Public subnet, one NAT Gateway.  Shared route table.
resource "aws_vpc" "VPC" {
  cidr_block = "${var.CIDR}"
  enable_dns_support = true
  enable_dns_hostnames = true
}
resource "aws_subnet" "PublicSubnetOne" {
  vpc_id = "${aws_vpc.VPC.id}"
  cidr_block = "${var.PublicOne}"
  availability_zone_id = "${data.aws_availability_zones.AZ.zone_ids[0]}"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "PublicSubnetTwo" {
  vpc_id = "${aws_vpc.VPC.id}"
  cidr_block = "${var.PublicTwo}"
  availability_zone_id = "${data.aws_availability_zones.AZ.zone_ids[1]}"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "PrivateSubnetOne" {
  vpc_id = "${aws_vpc.VPC.id}"
  cidr_block = "${var.PrivateOne}"
  availability_zone_id = "${data.aws_availability_zones.AZ.zone_ids[0]}"
}
resource "aws_subnet" "PrivateSubnetTwo" {
  vpc_id = "${aws_vpc.VPC.id}"
  cidr_block = "${var.PrivateTwo}"
  availability_zone_id = "${data.aws_availability_zones.AZ.zone_ids[1]}"
}

// Create Internet Gateway
resource "aws_internet_gateway" "InternetGateway" {
  vpc_id = "${aws_vpc.VPC.id}"
}
// Missing "VPC Gateway Attachment"

resource "aws_route_table" "PublicRouteTable" {
  vpc_id = "${aws_vpc.VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.InternetGateway.id}"
  }
}

resource "aws_route" "PublicRoute" {
  route_table_id= "${aws_route_table.PublicRouteTable.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.InternetGateway.id}"
  depends_on = ["aws_internet_gateway.InternetGateway"]
}

resource "aws_route_table_association" "PublicSubnetOneRouteTableAssociation" {
  subnet_id      = "${aws_subnet.PublicSubnetOne.id}"
  route_table_id = "${aws_route_table.PublicRouteTable.id}"
}
resource "aws_route_table_association" "PublicSubnetTwoRouteTableAssociation" {
  subnet_id      = "${aws_subnet.PublicSubnetTwo.id}"
  route_table_id = "${aws_route_table.PublicRouteTable.id}"
}
resource "aws_eip" "NatGatewayOneAttachment" {
  depends_on = ["aws_internet_gateway.InternetGateway"]
  vpc      = true
}
resource "aws_eip" "NatGatewayTwoAttachment" {
  depends_on = ["aws_internet_gateway.InternetGateway"]
  vpc      = true
}
resource "aws_nat_gateway" "NatGatewayOne" {
  allocation_id = "${aws_eip.NatGatewayOneAttachment.id}"
  subnet_id     = "${aws_subnet.PublicSubnetOne.id}"
}
resource "aws_nat_gateway" "NatGatewayTwo" {
  allocation_id = "${aws_eip.NatGatewayTwoAttachment.id}"
  subnet_id     = "${aws_subnet.PublicSubnetTwo.id}"
}
resource "aws_route_table" "PrivateRouteTableOne" {
  vpc_id = "${aws_vpc.VPC.id}"
}
resource "aws_route_table" "PrivateRouteTableTwo" {
  vpc_id = "${aws_vpc.VPC.id}"
}
resource "aws_route" "PrivateRouteOne" {
  route_table_id= "${aws_route_table.PrivateRouteTableOne.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.NatGatewayOne.id}"
  depends_on = ["aws_nat_gateway.NatGatewayOne"]
}
resource "aws_route" "PrivateRouteTwo" {
  route_table_id= "${aws_route_table.PrivateRouteTableTwo.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.NatGatewayTwo.id}"
  depends_on = ["aws_nat_gateway.NatGatewayTwo"]
}

resource "aws_route_table_association" "PrivateRouteTableOneAssociation" {
  subnet_id = "${aws_subnet.PrivateSubnetOne.id}"
  route_table_id = "${aws_route_table.PrivateRouteTableOne.id}"
}

resource "aws_route_table_association" "PrivateRouteTableTwoAssociation" {
  subnet_id = "${aws_subnet.PrivateSubnetTwo.id}"
  route_table_id = "${aws_route_table.PrivateRouteTableTwo.id}"
}

resource "aws_vpc_endpoint" "DynamoDBEndpoint" {
  vpc_id = "${aws_vpc.VPC.id}"
  route_table_ids = [
    "${aws_route_table.PrivateRouteTableOne.id}",
    "${aws_route_table.PrivateRouteTableTwo.id}"
   ]
  policy = "${file("configs/dynamodb-endpoint-policy.json")}"
  service_name = "com.amazonaws.${data.aws_region.AWSRegion.name}.dynamodb"
}
# End of Core infrastructure build

# Start ot build ECS Services for Matumaini Application
resource "aws_security_group" "FargateContainerSecurityGroup" {
  vpc_id      = "${aws_vpc.VPC.id}"
  description = "Access to the fargate containers from the Internet"
  name = "KCH Matumaini SG"
}

resource "aws_security_group_rule" "FargateContainerSecurityGroupRule" {
  type = "ingress"
  protocol = "-1"
  from_port = 0
  to_port = 0
  cidr_blocks = ["${var.CIDR}"]
  security_group_id = "${aws_security_group.FargateContainerSecurityGroup.id}"
}

resource "aws_iam_role" "EcsServiceRole" {
  name = "EcsServiceRole"
  path = "/"
  assume_role_policy = "${file("configs/ecs-service-assume-role-policy.json")}"
}

resource "aws_iam_policy" "EcsServiceRolePolicy" {
  name = "ecs-service"
  path = "/"
//  role = "${aws_iam_role.EcsServiceRole.id}"
  policy = "${file("configs/ecs-service-role-policy.json")}"
}
resource "aws_iam_policy_attachment" "EcsServiceRoleAttachment" {
  name = "EcsServiceRoleAttachment"
  roles       = ["${aws_iam_role.EcsServiceRole.name}"]
  policy_arn = "${aws_iam_policy.EcsServiceRolePolicy.arn}"
}

resource "aws_iam_role" "ECSTaskRole" {
  name = "ECSTaskRole"
  path = "/"
  assume_role_policy = "${file("configs/ecs-task-assume-role-policy.json")}"
}

resource "null_resource" "dynamodb-json" {
  provisioner "local-exec" {
    command = "touch /tmp/foobar"
  }
}

# Created this service link out of band.
#aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com







# Core Invfrastructure Outputs
output "REPLACE_ME_VPC_ID" {
  value = "${aws_vpc.VPC.id}"
}
output "REPLACE_ME_PUBLIC_SUBNET_ONE" {
  value = "${aws_subnet.PublicSubnetOne.id}"
}
output "REPLACE_ME_PUBLIC_SUBNET_TWO" {
  value = "${aws_subnet.PublicSubnetTwo.id}"
}
output "REPLACE_ME_PRIVATE_SUBNET_ONE" {
  value = "${aws_subnet.PrivateSubnetOne.id}"
}
output "REPLACE_ME_PRIVATE_SUBNET_TWO" {
  value = "${aws_subnet.PrivateSubnetTwo.id}"
}

#output "REPLACE_ME_ECS_SERVICE_ROLE_ARN" {
#  value = "${aws_iam_role.EcsServiceRole.arn}"
#}
#output "REPLACE_ME_ECS_TASK_ROLE_ARN" {
#  value = "${aws_iam_role.ECSTaskRole.arn}"
#}
#output "REPLACE_ME_SECURITY_GROUP_ID" {
#  value = "${aws_security_group.FargateContainerSecurityGroup.id}"
#}
