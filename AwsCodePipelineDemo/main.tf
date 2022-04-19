# Require TF version to be same as or greater than 0.12.16
terraform {
  required_version = ">=0.12.16"
}

# Download any stable version in AWS provider of 2.36.0 or higher in 2.36 train
provider "aws" {
  region  = "us-east-2"
  version = "~> 2.36.0"
}

## Build an S3 bucket and DynamoDB for Terraform state and locking
module "bootstrap" {
  source                              = "./modules/bootstrap"
  s3_tfstate_bucket                   = "testing-mahesh-s3-test-1234-terraform-tfstate"
  s3_logging_bucket_name              = "testing-mahesh-s3-test-1234"
  dynamo_db_table_name                = "codebuild-dynamodb-terraform-locking"
  codebuild_iam_role_name             = "CodeBuildIamRole"
  codebuild_iam_role_policy_name      = "CodeBuildIamRolePolicy"
  terraform_codecommit_repo_arn       = module.codecommit.terraform_codecommit_repo_arn
  tf_codepipeline_artifact_bucket_arn = module.codepipeline.tf_codepipeline_artifact_bucket_arn
}

## Build a CodeCommit git repo
module "codecommit" {
  source          = "./modules/codecommit"
  repository_name = "CodeCommitTerraform"
}

## Build CodeBuild projects for Terraform Plan and Terraform Apply
module "codebuild" {
  source                                 = "./modules/codebuild"
  codebuild_project_terraform_plan_name  = "TerraformPlan"
  codebuild_project_terraform_apply_name = "TerraformApply"
  s3_logging_bucket_id                   = module.bootstrap.s3_logging_bucket_id
  codebuild_iam_role_arn                 = module.bootstrap.codebuild_iam_role_arn
  s3_logging_bucket                      = module.bootstrap.s3_logging_bucket
}

## Build a CodePipeline
module "codepipeline" {
  source                               = "./modules/codepipeline"
  tf_codepipeline_name                 = "TerraformCodePipeline"
  tf_codepipeline_artifact_bucket_name = "kyler-codebuild-demo-artifact-s3"
  tf_codepipeline_role_name            = "TerraformCodePipelineIamRole"
  tf_codepipeline_role_policy_name     = "TerraformCodePipelineIamRolePolicy"
  terraform_codecommit_repo_name       = module.codecommit.terraform_codecommit_repo_name
  codebuild_terraform_plan_name        = module.codebuild.codebuild_terraform_plan_name
  codebuild_terraform_apply_name       = module.codebuild.codebuild_terraform_apply_name
}
