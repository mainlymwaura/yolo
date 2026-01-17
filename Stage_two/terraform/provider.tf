terraform {
  required_version = ">= 1.0"

  required_providers {
    vagrantup = {
      source = "hashicorp/vagrant"
      version = ">= 0.2.0"
    }
  }
}

provider "vagrant" {}
