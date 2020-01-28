variable "AWSRegion" {
  description = "Default region for Stadia Consulting's AWS services."
  default = "us-east-1"
}

data "aws_availability_zones" "AZ" {}
data "aws_region" "AWSRegion" {}
data "aws_billing_service_account" "Account" {}

//data "aws_s3_bucket" "AppCodeBucketRef" {
//    bucket = "${aws_s3_bucket.AppCodeBucket.id}"
//}
//data "aws_iam_role" "CodeBuildRef" {
//    name = "${aws_iam_role.KCHMatumainiServiceCodeBuildServiceRole.id}"
//}
//data "aws_iam_role" "CodePipelineRef" {
//    name = "${aws_iam_role.KCHMatumainiServiceCodePipelineServiceRole.id}"
//}
#data "aws_iam_role" "ECSServiceRef" {
#    name = "${aws_iam_role.EcsServiceRole.arn}"
#}
#data "aws_iam_role" "ECSSTaskRef" {
#    name = "${aws_iam_role.ECSTaskRole.arn}"
#}


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

variable "BaseS3Bucket" {
    default = "kch-matumaini"
}
variable "DBTable" {
    default = "KCHTable"
}
//variable "CodeS3Bucket" {
//    default = "kch-matumaini-source"
//}
//variable "CodeCommitRepo" {
//    default = "kch-matumaini-repo"
//}
variable "DockerAppName" {
    default ="kchmatumaini"
}
variable "ECSCluster" {
    default = "KCHMatumaini-Cluster"
}

variable "ECSService" {
    default = "KCHMatumaini-Service"
}

variable "NLBTargetGroup" {
    default = "KCHMatumaini-TG"
}
