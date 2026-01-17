resource "vagrant_vm" "yolo_app" {
  box             = var.vagrant_box
  hostname        = var.vm_hostname
  memory          = var.vm_memory
  cpus            = var.vm_cpus
  private_network = var.private_network_ip

  provision "shell" {
    inline = [
      "apt-get update",
      "apt-get install -y python3 python3-pip git",
      "pip3 install --upgrade pip",
      "pip3 install docker pyyaml"
    ]
  }

  tags = {
    Environment = "development"
    Application = var.app_name
  }
}

output "vm_ip" {
  description = "Private IP address of the Vagrant VM"
  value       = vagrant_vm.yolo_app.private_network
}

output "vm_hostname" {
  description = "Hostname of the Vagrant VM"
  value       = vagrant_vm.yolo_app.hostname
}
