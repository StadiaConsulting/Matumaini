resource "aws_codebuild_project" "example" {
  name          = "KCHMatumainiServiceCodeBuildProject"
  description   = "KCH Matumaini App"
  build_timeout = "5"
  service_role  = "${aws_iam_role.KCHMatumainiServiceCodeBuildServiceRole.arn}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/python:3.5.2"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      "name"  = "AWS_ACCOUNT_ID"
      "value" = "${data.aws_billing_service_account.Account.id}"
    }

    environment_variable {
      "name"  = "AWS_DEFAULT_REGION"
      "value" = "${data.aws_region.Region.name}"
    }
  }

  source {
    type = "CODECOMMIT"
    location        = "https://git-codecommit.${data.aws_region.Region.name}.amazonaws.com/v1/repos/KCHMatumainiService-Repository"
  }
}

resource "aws_codepipeline" "KCHMatumainiServiceCICDPipeline" {
  name     = "KCHMatumainiServiceCICDPipeline"
  role_arn = "${aws_iam_role.KCHMatumainiServiceCodePipelineServiceRole.arn}"

  artifact_store {
    location = "${aws_s3_bucket.AppCodeBucket.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["KCHMatumainiService-SourceArtifact"]

      configuration = {
        RepositoryName   = "KCHMatumainiService-Repository"
        BranchName = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["KCHMatumainiService-SourceArtifact"]
      output_artifacts = ["KCHMatumainiService-BuildArtifact"]
      version         = "1"

      configuration = {
        ProjectName = "KCHMatumainiServiceCodeBuildProject"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "ECS"
      input_artifacts  = ["KCHMatumainiService-BuildArtifact"]
      version          = "1"

      configuration {
        ClusterName     = "KCHMatumaini-Cluster"
        ServiceName   = "KCHMatumaini-Service"
        FileName = "imagedefinitions.json"

      }
    }
  }
}