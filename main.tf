provider "aws" {
  default_tags {
    tags = {
      SourceCode     = element(split("/${var.repository_name}/", path.cwd), 1)
      DeploymentTool = var.deployment_tool
      Service        = var.service_name
    }
  }
}