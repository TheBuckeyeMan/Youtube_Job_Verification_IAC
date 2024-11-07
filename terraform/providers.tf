terraform {
  cloud {
    organization = "1220-IAC"
    workspaces {
      name = "YoutubeService1"
    }
  }
}
provider "aws" {
    region = var.region
    access_key  = var.aws_access_key
    secret_key  = var.aws_secret_key
}
