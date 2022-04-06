variable "region" {
  default = "us-east1"
  #default = "us-central1"
  #default = "us-west1"
}

variable "zones" {
  default = ["us-east1-c", "us-east1-d"]
  #default = ["us-central1-a", "us-central1-c"]
  #default = ["us-west1-a", "us-west1-b"]
}

# tag
variable "label" {
  default = {
    namespace = "shztki"
    stage     = "dev"
    name      = "compute"
  }
}

variable "gcp_user" {}
variable "gcp_project_id" {}
variable "office_cidr" {}

variable "instance_example" {
  default = {
    name         = "example"
    machine_type = "e2-micro"
    count        = 1
    size         = 10 # GB

    #image = "centos-cloud/centos-7"
    image = "ubuntu-os-cloud/ubuntu-2004-lts"
  }
}

variable "instance_example_tags" {
  default = ["server-example"]
}

