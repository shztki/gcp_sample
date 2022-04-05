provider "google" {
  credentials = file(var.gcp_user)
  project     = var.gcp_project_id
  region      = var.region
  zone        = var.zones[0]
}

terraform {
  required_version = "~> 1.1.7"
  backend "remote" {}

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.12"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.1.0"
    }
  }
}

module "label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=master"
  namespace   = var.label["namespace"]
  stage       = var.label["stage"]
  name        = var.label["name"]
  delimiter   = "-"
  label_order = ["namespace", "stage", "name"]
}

