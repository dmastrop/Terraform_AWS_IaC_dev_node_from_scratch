terraform {
  # this is configuration that terraform needs to know about
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # note that the config file has the region
  shared_config_files      = ["/Users/davemastropolo/.aws/config"]
  shared_credentials_files = ["/Users/davemastropolo/.aws/credentials"]
  # this is the profile for our IAM user that we created
  profile = "vscode"
}
