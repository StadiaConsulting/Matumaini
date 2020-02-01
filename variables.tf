variable "AWS-Region" {
  description = "Default region for Stadia Consulting's AWS services."
  default = "us-east-1"
}

data "aws_availability_zones" "AZ" {}
data "aws_region" "AWSRegion" {}
data "aws_billing_service_account" "Account" {}

variable "ProjectTag" {
  type = string
  default = "Matumaini"
  description = "Used to identify AWS resources used for this project"
}

variable "CIDR" {
    default = "10.0.0.0/16"
}
variable "PublicOne" {
    default = "10.0.0.0/24"
}
variable "PublicTwo" {
    default = "10.0.1.0/24"
}
variable "PrivateOne" {
    default = "10.0.2.0/24"
}
variable "PrivateTwo" {
    default = "10.0.3.0/24"
}
variable "DefaultRoute" {
    default = "0.0.0.0/0"
}

variable "BaseS3Bucket" {
    default = "matumaini"
}

variable "DBTable" {
    default = "MatumainiTable"
}
variable "DockerAppName" {
    default = "matumaini"
}
variable "ECSCluster" {
    default = "Matumaini-Cluster"
}

variable "CfgDir" {
  default = "configs"
  description = "Dirctory of all JSON configuration files used by AWS"
}

variable "ContainerService" {
    default = "matumaini"
}

variable "ECSService" {
    default = "MatumainiService"
}

variable "NLB_TG" {
    default = "Matumaini-TG"
}

# CICD variables
variable "CodeS3Bucket" {
    default = "matumaini-source"
}
variable "CodeCommitRepo" {
    default = "matumaini-repo"
}

data "aws_s3_bucket" "AppCodeBucketRef" {
    bucket = "${aws_s3_bucket.AppCodeBucket.id}"
}
data "aws_iam_role" "CodeBuildRef" {
    name = "${aws_iam_role.MatumainiServiceCodeBuildServiceRole.id}"
}
data "aws_iam_role" "CodePipelineRef" {
    name = "${aws_iam_role.MatumainiServiceCodePipelineServiceRole.id}"
}
#data "aws_iam_role" "ECSServiceRef" {
#    name = "${aws_iam_role.EcsServiceRole.arn}"
#}
#data "aws_iam_role" "ECSSTaskRef" {
#    name = "${aws_iam_role.ECSTaskRole.arn}"
#}
