variable "AWSRegion" {
  description = "Default region for Stadia Consulting's AWS services."
  default = "us-east-1"
}

data "aws_availability_zones" "AZ" {}
data "aws_region" "AWSRegion" {}
data "aws_billing_service_account" "Account" {}

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
variable "DockerAppName" {
    default = "kchmatumaini"
}
variable "ECSCluster" {
    default = "KCHMatumaini-Cluster"
}

variable "CfgDir" {
  default = "configs"
  description = "Dirctory of all JSON configuration files used by AWS"
}
variable "EcsTaskRolePolicyJson" {
  default = "ecs-task-role-policy.json"
}
variable "ContainerService" {
    default = "kchmatumainiservice"
}
