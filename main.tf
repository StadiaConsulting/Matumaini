provider "aws" {
    region = var.AWSRegion
}


//resource "aws_s3_bucket" "AppCodeBucket" {
//    bucket  = "${var.CodeS3Bucket}"
//
//    lifecycle {
//      create_before_destroy = true
//    }
//}
//resource "aws_s3_bucket_policy" "AppCodeBucketPolicy" {
//  bucket = "${aws_s3_bucket.AppCodeBucket.id}"
//
//  policy = <<EOF
//{
//    "Statement": [
//      {
//        "Sid": "WhitelistedGet",
//        "Effect": "Allow",
//        "Principal": {
//          "AWS": [
//            "${data.aws_iam_role.CodeBuildRef.arn}",
//            "${data.aws_iam_role.CodePipelineRef.arn}"
//          ]
//        },
//        "Action": [
//          "s3:GetObject",
//          "s3:GetObjectVersion",
//          "s3:GetBucketVersioning"
//        ],
//        "Resource": [
//          "arn:aws:s3:::${data.aws_s3_bucket.AppCodeBucketRef.id}/*",
//          "arn:aws:s3:::${data.aws_s3_bucket.AppCodeBucketRef.id}"
//        ]
//      },
//      {
//        "Sid": "WhitelistedPut",
//        "Effect": "Allow",
//        "Principal": {
//          "AWS": [
//            "${data.aws_iam_role.CodeBuildRef.arn}",
//            "${data.aws_iam_role.CodePipelineRef.arn}"
//          ]
//        },
//        "Action": "s3:PutObject",
//        "Resource": [
//          "arn:aws:s3:::${data.aws_s3_bucket.AppCodeBucketRef.id}/*",
//          "arn:aws:s3:::${data.aws_s3_bucket.AppCodeBucketRef.id}"
//        ]
//      }
//    ]
//}
//  EOF
//}

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
  policy = "${file("Configs/dynamodb-endpoint-policy.json")}"
  service_name = "com.amazonaws.${data.aws_region.AWSRegion.name}.dynamodb"
}

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
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
					{
						"Effect": "Allow",
						"Principal": {
							"Service": [
								"ecs.amazonaws.com",
								"ecs-tasks.amazonaws.com"]
						},
						"Action": [
							"sts:AssumeRole"]
					}
				]
			}
EOF
}

resource "aws_iam_policy" "EcsServiceRolePolicy" {
  name = "ecs-service"
  path = "/"
//  role = "${aws_iam_role.EcsServiceRole.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:AttachNetworkInterface",
        "ec2:CreateNetworkInterface",
        "ec2:CreateNetworkInterfacePermission",
        "ec2:DeleteNetworkInterface",
        "ec2:DeleteNetworkInterfacePermission",
        "ec2:Describe*",
        "ec2:DetachNetworkInterface",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets",
        "iam:PassRole",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:DescribeLogStreams",
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "EcsServiceRoleAttachment" {
  name = "EcsServiceRoleAttachment"
  roles       = ["${aws_iam_role.EcsServiceRole.name}"]
  policy_arn = "${aws_iam_policy.EcsServiceRolePolicy.arn}"
}

resource "aws_iam_role" "ECSTaskRole" {
  name = "ECSTaskRole"
  path = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
					{
						"Effect": "Allow",
						"Principal": {
							"Service": [
								"ecs-tasks.amazonaws.com"]
						},
						"Action": [
							"sts:AssumeRole"]
					}
				]
			}

EOF
}

resource "aws_iam_policy" "ECSTaskRolePolicy" {
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"ecr:GetAuthorizationToken",
				"ecr:BatchCheckLayerAvailability",
				"ecr:GetDownloadUrlForLayer",
				"ecr:BatchGetImage",
				"logs:CreateLogStream",
				"logs:CreateLogGroup",
				"logs:PutLogEvents"
			],
			"Resource": "*"
		},
		{
			"Effect": "Allow",
			"Action": [
				"dynamodb:Scan",
				"dynamodb:Query",
				"dynamodb:UpdateItem",
				"dynamodb:GetItem"
			],
			"Resource": "arn:aws:dynamodb:*:*:table/KCHTable*"
		}
	]
}
EOF
}

resource "aws_iam_policy_attachment" "EcsServiceTaskRoleAttachment" {
  name = "EcsServiceTaskRoleAttachment"
  roles       = ["${aws_iam_role.ECSTaskRole.name}"]
  policy_arn = "${aws_iam_policy.ECSTaskRolePolicy.arn}"
}

// Break out CICD build from Matumaini infrastructure build
//resource "aws_iam_role" "KCHMatumainiServiceCodePipelineServiceRole" {
//  name = "KCHMatumainiServiceCodePipelineServiceRole"
//  assume_role_policy = <<EOF
//{
//  "Version": "2012-10-17",
//  "Statement": [
//					{
//						"Effect": "Allow",
//						"Principal": {
//							"Service": [
//								"codepipeline.amazonaws.com"]
//						},
//						"Action": [
//							"sts:AssumeRole"]
//					}
//				]
//			}
//EOF
//}
//resource "aws_iam_policy" "KCHMatumainiService-codepipeline-service-policy" {
//  path = "/"
//
//  policy = <<EOF
//{
//  "Version": "2012-10-17",
//	"Statement": [
//		{
//			"Action": [
//				"codecommit:GetBranch",
//				"codecommit:GetCommit",
//				"codecommit:UploadArchive",
//				"codecommit:GetUploadArchiveStatus",
//				"codecommit:CancelUploadArchive"
//			],
//			"Resource": "*",
//			"Effect": "Allow"
//		},
//		{
//			"Action": [
//				"s3:GetObject",
//				"s3:GetObjectVersion",
//				"s3:GetBucketVersioning"
//			],
//			"Resource": "*",
//			"Effect": "Allow"
//		},
//		{
//			"Action": [
//				"s3:PutObject"
//			],
//			"Resource": [
//				"arn:aws:s3:::*"
//			],
//			"Effect": "Allow"
//		},
//		{
//			"Action": [
//				"elasticloadbalancing:*",
//				"autoscaling:*",
//				"cloudwatch:*",
//				"ecs:*",
//				"codebuild:*",
//				"iam:PassRole"
//			],
//			"Resource": "*",
//			"Effect": "Allow"
//		}
//	]
//}
//EOF
//}

//resource "aws_iam_policy_attachment" "KCHMatumainiServiceCodePipelineServiceRoleAttachment" {
//  name = "KCHMatumainiServiceCodePipelineServiceRoleAttachment"
//  roles       = ["${aws_iam_role.KCHMatumainiServiceCodePipelineServiceRole.name}"]
//  policy_arn = "${aws_iam_policy.KCHMatumainiService-codepipeline-service-policy.arn}"
//}

//resource "aws_iam_role" "KCHMatumainiServiceCodeBuildServiceRole" {
//  name = "KCHMatumainiServiceCodeBuildServiceRole"
//  assume_role_policy = <<EOF
//{
//  "Version": "2012-10-17",
//  "Statement": [
//					{
//						"Effect": "Allow",
//						"Principal": {
//							"Service": [
//								"codebuild.amazonaws.com"]
//						},
//						"Action": [
//							"sts:AssumeRole"]
//					}
//				]
//			}
//
//EOF
//}

//resource "aws_iam_policy" "KCHMatumainiService-CodeBuildServicePolicy" {
//  path = "/"
//
//  policy = <<EOF
//{
//  "Version": "2012-10-17",
//	"Statement": [
//		{
//			"Effect": "Allow",
//			"Action": [
//				"codecommit:ListBranches",
//				"codecommit:ListRepositories",
//				"codecommit:BatchGetRepositories",
//				"codecommit:Get*",
//				"codecommit:GitPull"
//			],
//			"Resource":
//
//					"arn:aws:codecommit:${data.aws_region.AWSRegion.name}:${data.aws_billing_service_account.Account.id}:KCHMatumainiServiceRepository"
//		},
//		{
//			"Effect": "Allow",
//			"Action": [
//				"logs:CreateLogGroup",
//				"logs:CreateLogStream",
//				"logs:PutLogEvents"
//			],
//			"Resource": "*"
//		},
//		{
//			"Effect": "Allow",
//			"Action": [
//				"s3:PutObject",
//				"s3:GetObject",
//				"s3:GetObjectVersion",
//				"s3:ListBucket"
//			],
//			"Resource": "*"
//		},
//		{
//			"Effect": "Allow",
//			"Action": [
//				"ecr:InitiateLayerUpload",
//				"ecr:GetAuthorizationToken"
//			],
//			"Resource": "*"
//		}
//	]
//}
//EOF
//}

//resource "aws_iam_policy_attachment" "KCHMatumainiServiceCodeBuildServiceRoleAttachment" {
//  name = "KCHMatumainiServiceCodeBuildServiceRoleAttachment"
//  roles       = ["${aws_iam_role.KCHMatumainiServiceCodeBuildServiceRole.name}"]
//  policy_arn = "${aws_iam_policy.KCHMatumainiService-CodeBuildServicePolicy.arn}"
//}

//resource "aws_ecr_repository" "KCHMatumainiECR" {
//  name = "${var.DockerAppName}/service"
//}
resource "aws_ecs_cluster" "KCHMatumainiECSCluster" {
  name = "${var.ECSCluster}"
}


resource "aws_cloudwatch_log_group" "KCHMatumainiLogGroup" {
  name = "${var.DockerAppName}-logs"
}


//resource "aws_ecr_repository_policy" "KCHMatumainiECRPolicy" {
//  repository = "${aws_ecr_repository.KCHMatumainiECR.name}"
//
//  policy = <<EOF
//{
//  "Version": "2008-10-17",
//  "Statement": [
//    {
//      "Sid": "AllowPushPull",
//      "Effect": "Allow",
//      "Principal": {
//        "AWS": [
//         "${aws_iam_role.KCHMatumainiServiceCodeBuildServiceRole.arn}"
//        ]
//      },
//      "Action": [
//        "ecr:GetDownloadUrlForLayer",
//        "ecr:BatchGetImage",
//        "ecr:BatchCheckLayerAvailability",
//        "ecr:PutImage",
//        "ecr:InitiateLayerUpload",
//        "ecr:UploadLayerPart",
//        "ecr:CompleteLayerUpload"
//      ]
//    }
//  ]
//}
//EOF
//}


#resource "aws_ecs_task_definition" "KCHMatumainiECSTaskDef" {
#  family                = "kchmatumainiservice"
#  container_definitions = "${file("Configs/service-definition.json")}"
#}
resource "aws_ecs_task_definition" "KCHMatumainiECSTaskDef" {
  family = "kchmatumainiservice"
  network_mode ="awsvpc"
  cpu = 256
  memory = 512
  requires_compatibilities = ["FARGATE"]
  container_definitions =<<EOF
[
  {
    "cpu": 256,
    "image": "image",
    "memory": 512,
    "name": "kchmatumainiservice",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ]
  }
]
EOF
}

resource "aws_ecs_service" "main" {
  name            = "KCHMatumaini-Service"
  cluster         = "${aws_ecs_cluster.KCHMatumainiECSCluster.id}"
  task_definition = "${aws_ecs_task_definition.KCHMatumainiECSTaskDef.arn}"
  desired_count   = "1"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = ["${aws_security_group.FargateContainerSecurityGroup.id}"]
    subnets         = ["${aws_subnet.PrivateSubnetOne.id}",
                      "${aws_subnet.PrivateSubnetTwo.id}"]
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.AppNLBTargetGroup.id}"
    container_name   = "kchmatumainiservice"
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

resource "aws_lb_target_group" "AppNLBTargetGroup" {
  name     = "${var.NLBTargetGroup}"
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
    target_group_arn = "${aws_lb_target_group.AppNLBTargetGroup.arn}"
  }
}

# Created this service link out of band.
#aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com


//resource "aws_codecommit_repository" "AppCodeCommitRepo" {
//  repository_name = "${var.CodeCommitRepo}"
//  description     = "App Code Repository"
//}






output "REPLACE_ME_ECS_SERVICE_ROLE_ARN" {
  value = "${aws_iam_role.EcsServiceRole.arn}"
}
output "REPLACE_ME_ECS_TASK_ROLE_ARN" {
  value = "${aws_iam_role.ECSTaskRole.arn}"
}
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
output "REPLACE_ME_SECURITY_GROUP_ID" {
  value = "${aws_security_group.FargateContainerSecurityGroup.id}"
}
//output "REPLACE_ME_CODEBUILD_ROLE_ARN" {
//  value = "${aws_iam_role.KCHMatumainiServiceCodeBuildServiceRole.arn}"
//}
//output "REPLACE_ME_CODEPIPELINE_ROLE_ARN" {
//  value = "${aws_iam_role.KCHMatumainiServiceCodePipelineServiceRole.arn}"
//}
