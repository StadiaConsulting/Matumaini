# Variables set in variables.tf file
provider "aws" {
    region = var.AWS-Region
}

// Create static S3 website
resource "aws_s3_bucket" "StaticWebBucket" {
    bucket  = "${var.BaseS3Bucket}"
    acl = "public-read"
    // references static resource "matumaini" S3 bucket.  [FIX-LATER]
    policy = "${file("${var.CfgDir}/website-bucket-policy.json")}"

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

  // Always tag AWS resources
  tags = {
    Project = "${var.ProjectTag}"
  }
}
resource "aws_subnet" "PublicSubnetOne" {
  vpc_id = "${aws_vpc.VPC.id}"
  cidr_block = "${var.PublicOne}"
  availability_zone_id = "${data.aws_availability_zones.AZ.zone_ids[0]}"
  map_public_ip_on_launch = true
  // Always tag AWS resources
  tags = {
    Project = "${var.ProjectTag}"
  }
}
resource "aws_subnet" "PublicSubnetTwo" {
  vpc_id = "${aws_vpc.VPC.id}"
  cidr_block = "${var.PublicTwo}"
  availability_zone_id = "${data.aws_availability_zones.AZ.zone_ids[1]}"
  map_public_ip_on_launch = true
  // Always tag AWS resources
  tags = {
    Project = "${var.ProjectTag}"
  }
}
resource "aws_subnet" "PrivateSubnetOne" {
  vpc_id = "${aws_vpc.VPC.id}"
  cidr_block = "${var.PrivateOne}"
  availability_zone_id = "${data.aws_availability_zones.AZ.zone_ids[0]}"
  // Always tag AWS resources
  tags = {
    Project = "${var.ProjectTag}"
  }
}
resource "aws_subnet" "PrivateSubnetTwo" {
  vpc_id = "${aws_vpc.VPC.id}"
  cidr_block = "${var.PrivateTwo}"
  availability_zone_id = "${data.aws_availability_zones.AZ.zone_ids[1]}"
  // Always tag AWS resources
  tags = {
    Project = "${var.ProjectTag}"
  }
}

// Create Internet Gateway
resource "aws_internet_gateway" "InternetGateway" {
  // Always tag AWS resources
  tags = {
    Project = "${var.ProjectTag}"
  }
  vpc_id = "${aws_vpc.VPC.id}"
}
// Missing "VPC Gateway Attachment"

resource "aws_route_table" "PublicRouteTable" {
  // Always tag AWS resources
  tags = {
    Project = "${var.ProjectTag}"
  }
  vpc_id = "${aws_vpc.VPC.id}"
  route {
    cidr_block = "${var.DefaultRoute}"
    gateway_id = "${aws_internet_gateway.InternetGateway.id}"
  }
}

resource "aws_route" "PublicRoute" {
  route_table_id= "${aws_route_table.PublicRouteTable.id}"
  destination_cidr_block = "${var.DefaultRoute}"
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
  // Always tag AWS resources
  tags = {
    Project = "${var.ProjectTag}"
  }
  depends_on = ["aws_internet_gateway.InternetGateway"]
  vpc      = true
}
resource "aws_eip" "NatGatewayTwoAttachment" {
  // Always tag AWS resources
  tags = {
    Project = "${var.ProjectTag}"
  }
  depends_on = ["aws_internet_gateway.InternetGateway"]
  vpc      = true
}
resource "aws_nat_gateway" "NatGatewayOne" {
  // Always tag AWS resources
  tags = {
    Project = "${var.ProjectTag}"
  }
  allocation_id = "${aws_eip.NatGatewayOneAttachment.id}"
  subnet_id     = "${aws_subnet.PublicSubnetOne.id}"
}
resource "aws_nat_gateway" "NatGatewayTwo" {
  // Always tag AWS resources
  tags = {
    Project = "${var.ProjectTag}"
  }
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
  destination_cidr_block = "${var.DefaultRoute}"
  nat_gateway_id = "${aws_nat_gateway.NatGatewayOne.id}"
  depends_on = ["aws_nat_gateway.NatGatewayOne"]
}
resource "aws_route" "PrivateRouteTwo" {
  route_table_id= "${aws_route_table.PrivateRouteTableTwo.id}"
  destination_cidr_block = "${var.DefaultRoute}"
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
  policy = "${file("${var.CfgDir}/dynamodb-endpoint-policy.json")}"
  service_name = "com.amazonaws.${data.aws_region.AWSRegion.name}.dynamodb"
}
# End of Core infrastructure build

# Start ot build ECS Services for Matumaini Application
resource "aws_security_group" "FargateContainerSecurityGroup" {
  // Always tag AWS resources
  tags = {
    Project = "${var.ProjectTag}"
  }
  vpc_id      = "${aws_vpc.VPC.id}"
  description = "Allow Internet access to the fargate containers"
  name = "Matumaini SecurityGroup"
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
  // No need to change JSON for application instance.
  assume_role_policy = "${file("${var.CfgDir}/ecs-service-assume-role-policy.json")}"
}

resource "aws_iam_policy" "EcsServiceRolePolicy" {
  name = "ecs-service"
  path = "/"
  #role = "${aws_iam_role.EcsServiceRole.id}" # is is not a valid attr to set
  // No need to change JSON for application instance.
  policy = "${file("${var.CfgDir}/ecs-service-role-policy.json")}"
}
resource "aws_iam_policy_attachment" "EcsServiceRoleAttachment" {
  name = "EcsServiceRoleAttachment"
  roles       = ["${aws_iam_role.EcsServiceRole.name}"]
  policy_arn = "${aws_iam_policy.EcsServiceRolePolicy.arn}"
}

resource "aws_iam_role" "ECSTaskRole" {
  name = "ECSTaskRole"
  path = "/"
  // No need to change JSON for application instance.
  assume_role_policy = "${file("${var.CfgDir}/ecs-task-assume-role-policy.json")}"
}

resource "aws_iam_policy" "ECSTaskRolePolicy" {
  path = "/"
  // Table is hard coded into this JSON config file.  [FIX-LATER]
  policy = "${file("${var.CfgDir}/ecs-task-role-policy.json")}"
}

resource "aws_iam_policy_attachment" "EcsServiceTaskRoleAttachment" {
  name = "EcsServiceTaskRoleAttachment"
  roles       = ["${aws_iam_role.ECSTaskRole.name}"]
  policy_arn = "${aws_iam_policy.ECSTaskRolePolicy.arn}"
}

resource "aws_ecs_cluster" "ECSCluster" {
  name = "${var.ECSCluster}"
}

resource "aws_cloudwatch_log_group" "LogGroup" {
  name = "${var.DockerAppName}-logs"
}

module "ecs-task-def" {
  source = "../modules/terraform-aws-ecs-container-definition"
  container_name = "${var.ContainerService}"
  container_image = "${data.aws_billing_service_account.Account.id}.dkr.ecr.${data.aws_region.AWSRegion.name}.amazonaws.com/${var.DockerAppName}/service"
  essential = "true"
  port_mappings = [
    {
      containerPort = 8080
      hostPort      = 8080
      protocol      = "http"
    }
  ]
}

resource "aws_ecs_task_definition" "ECSTaskDef" {
  family = "${var.ContainerService}"
  network_mode ="awsvpc"
  cpu = 256
  memory = 512
  requires_compatibilities = ["FARGATE"]
  execution_role_arn = "${aws_iam_role.EcsServiceRole.arn}"
  task_role_arn =  "${aws_iam_role.ECSTaskRole.arn}"
  container_definitions = module.ecs-task-def.json
}

resource "aws_ecs_service" "main" {
  name            = "${var.ECSService}"
  cluster         = "${aws_ecs_cluster.ECSCluster.id}"
  task_definition = "${aws_ecs_task_definition.ECSTaskDef.arn}"
  desired_count   = "1"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = ["${aws_security_group.FargateContainerSecurityGroup.id}"]
    subnets         = ["${aws_subnet.PrivateSubnetOne.id}",
                      "${aws_subnet.PrivateSubnetTwo.id}"]
  }
  load_balancer {
    target_group_arn = "${aws_lb_target_group.AppNLB_TG.id}"
    container_name   = "${var.ContainerService}"
    container_port   = "8080"
  }
  depends_on = [
    "aws_lb_listener.AppNLBListener",
    ]
  }

  resource "aws_lb" "AppNLB" {
    name               = "${var.DockerAppName}-nlb"
    internal           = false
    load_balancer_type = "network"
    subnets            = ["${aws_subnet.PublicSubnetOne.id}", "${aws_subnet.PublicSubnetTwo.id}"]
    enable_deletion_protection = false
  }

  resource "aws_lb_target_group" "AppNLB_TG" {
    name     = "${var.NLB_TG}"
    port     = 8080
    protocol = "TCP"
    vpc_id   = "${aws_vpc.VPC.id}"
    target_type = "ip"
    health_check {
      interval = 10
      path = "/"
      protocol = "HTTP"
      healthy_threshold = 3
      unhealthy_threshold = 3
    }
  }

  resource "aws_lb_listener" "AppNLBListener" {
    load_balancer_arn = "${aws_lb.AppNLB.arn}"
    port              = "80"
    protocol          = "TCP"

    default_action {
      type             = "forward"
      target_group_arn = "${aws_lb_target_group.AppNLB_TG.arn}"
    }
  }
# Created this service link out of band.
#aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com

# Create CICD Resource
resource "aws_s3_bucket" "AppCodeBucket" {
    bucket  = "${var.CodeS3Bucket}"

    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_s3_bucket_policy" "AppCodeBucketPolicy" {
  bucket = "${aws_s3_bucket.AppCodeBucket.id}"

  policy = <<EOF
{
    "Statement": [
      {
        "Sid": "WhitelistedGet",
        "Effect": "Allow",
        "Principal": {
          "AWS": [
            "${data.aws_iam_role.CodeBuildRef.arn}",
            "${data.aws_iam_role.CodePipelineRef.arn}"
          ]
        },
        "Action": [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning"
        ],
        "Resource": [
          "arn:aws:s3:::${data.aws_s3_bucket.AppCodeBucketRef.id}/*",
          "arn:aws:s3:::${data.aws_s3_bucket.AppCodeBucketRef.id}"
        ]
      },
      {
        "Sid": "WhitelistedPut",
        "Effect": "Allow",
        "Principal": {
          "AWS": [
            "${data.aws_iam_role.CodeBuildRef.arn}",
            "${data.aws_iam_role.CodePipelineRef.arn}"
          ]
        },
        "Action": "s3:PutObject",
        "Resource": [
          "arn:aws:s3:::${data.aws_s3_bucket.AppCodeBucketRef.id}/*",
          "arn:aws:s3:::${data.aws_s3_bucket.AppCodeBucketRef.id}"
        ]
      }
    ]
}
EOF
}



resource "aws_iam_role" "MatumainiServiceCodePipelineServiceRole" {
  name = "MatumainiServiceCodePipelineServiceRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
					{
						"Effect": "Allow",
						"Principal": {
							"Service": [
								"codepipeline.amazonaws.com"]
						},
						"Action": [
							"sts:AssumeRole"]
					}
				]
			}
EOF
}

resource "aws_iam_policy" "MatumainiService-codepipeline-service-policy" {
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
	"Statement": [
		{
			"Action": [
				"codecommit:GetBranch",
				"codecommit:GetCommit",
				"codecommit:UploadArchive",
				"codecommit:GetUploadArchiveStatus",
				"codecommit:CancelUploadArchive"
			],
			"Resource": "*",
			"Effect": "Allow"
		},
		{
			"Action": [
				"s3:GetObject",
				"s3:GetObjectVersion",
				"s3:GetBucketVersioning"
			],
			"Resource": "*",
			"Effect": "Allow"
		},
		{
			"Action": [
				"s3:PutObject"
			],
			"Resource": [
				"arn:aws:s3:::*"
			],
			"Effect": "Allow"
		},
		{
			"Action": [
				"elasticloadbalancing:*",
				"autoscaling:*",
				"cloudwatch:*",
				"ecs:*",
				"codebuild:*",
				"iam:PassRole"
			],
			"Resource": "*",
			"Effect": "Allow"
		}
	]
}
EOF
}

resource "aws_iam_policy_attachment" "MatumainiServiceCodePipelineServiceRoleAttachment" {
  name = "MatumainiServiceCodePipelineServiceRoleAttachment"
  roles       = ["${aws_iam_role.MatumainiServiceCodePipelineServiceRole.name}"]
  policy_arn = "${aws_iam_policy.MatumainiService-codepipeline-service-policy.arn}"
}

resource "aws_iam_role" "MatumainiServiceCodeBuildServiceRole" {
  name = "MatumainiServiceCodeBuildServiceRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
					{
						"Effect": "Allow",
						"Principal": {
							"Service": [
								"codebuild.amazonaws.com"]
						},
						"Action": [
							"sts:AssumeRole"]
					}
				]
			}

EOF
}

resource "aws_iam_policy" "MatumainiService-CodeBuildServicePolicy" {
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"codecommit:ListBranches",
				"codecommit:ListRepositories",
				"codecommit:BatchGetRepositories",
				"codecommit:Get*",
				"codecommit:GitPull"
			],
			"Resource":

					"arn:aws:codecommit:${data.aws_region.AWSRegion.name}:${data.aws_billing_service_account.Account.id}:MatumainiServiceRepository"
		},
		{
			"Effect": "Allow",
			"Action": [
				"logs:CreateLogGroup",
				"logs:CreateLogStream",
				"logs:PutLogEvents"
			],
			"Resource": "*"
		},
		{
			"Effect": "Allow",
			"Action": [
				"s3:PutObject",
				"s3:GetObject",
				"s3:GetObjectVersion",
				"s3:ListBucket"
			],
			"Resource": "*"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ecr:InitiateLayerUpload",
				"ecr:GetAuthorizationToken"
			],
			"Resource": "*"
		}
	]
}
EOF
}

resource "aws_iam_policy_attachment" "MatumainiServiceCodeBuildServiceRoleAttachment" {
  name = "MatumainiServiceCodeBuildServiceRoleAttachment"
  roles       = ["${aws_iam_role.MatumainiServiceCodeBuildServiceRole.name}"]
  policy_arn = "${aws_iam_policy.MatumainiService-CodeBuildServicePolicy.arn}"
}

resource "aws_ecr_repository" "MatumainiECR" {
  name = "${var.DockerAppName}/service"
}

resource "aws_ecr_repository_policy" "MatumainiECRPolicy" {
  repository = "${aws_ecr_repository.MatumainiECR.name}"

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "AllowPushPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
         "${aws_iam_role.MatumainiServiceCodeBuildServiceRole.arn}"
        ]
      },
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
    }
  ]
}
EOF
}


# Created this service link out of band.
#aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com


resource "aws_codecommit_repository" "AppCodeCommitRepo" {
  repository_name = "${var.CodeCommitRepo}"
  description     = "App Code Repository"
}






output "REPLACE_ME_CODEBUILD_ROLE_ARN" {
  value = "${aws_iam_role.MatumainiServiceCodeBuildServiceRole.arn}"
}
output "REPLACE_ME_CODEPIPELINE_ROLE_ARN" {
  value = "${aws_iam_role.MatumainiServiceCodePipelineServiceRole.arn}"
}


# Core Invfrastructure Outputs
output "REPLACE_ME_VPC_ID" {
  value = aws_vpc.VPC.id
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
output "REPLACE_ME_DBTABLE" {
  value = "${var.DBTable}"
}
output "ECS_JSON" {
  description = "JSON encoded list of container definitions for use with other terraform resources such as aws_ecs_task_definition"
  value = module.ecs-task-def.json
}

output "ECS_JSON_MAP" {
  description = "JSON encoded container definitions for use with other terraform resources such as aws_ecs_task_definition"
  value = module.ecs-task-def.json_map
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
