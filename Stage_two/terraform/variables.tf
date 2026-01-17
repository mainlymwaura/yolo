variable "vagrant_box" {
  description = "Vagrant box to use for VM"
  type        = string
  default     = "bento/ubuntu-20.04"
}

variable "vm_hostname" {
  description = "Hostname for the virtual machine"
  type        = string
  default     = "yolo-app-server-tf"
}

variable "vm_memory" {
  description = "Memory allocation for VM in MB"
  type        = number
  default     = 2048
}

variable "vm_cpus" {
  description = "Number of CPU cores for VM"
  type        = number
  default     = 2
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "yolo"
}

variable "private_network_ip" {
  description = "Private network IP address for the VM"
  type        = string
  default     = "192.168.33.20"
}

variable "docker_network" {
  description = "Docker network name"
  type        = string
  default     = "yolo-net"
}

variable "frontend_port" {
  description = "Frontend service port"
  type        = number
  default     = 3000
}

variable "backend_port" {
  description = "Backend service port"
  type        = number
  default     = 5000
}

variable "mongodb_port" {
  description = "MongoDB service port"
  type        = number
  default     = 27017
}

variable "app_repo_url" {
  description = "Git repository URL for the application"
  type        = string
  default     = "https://github.com/mainlymwaura/YOLO.git"
}

variable "app_repo_branch" {
  description = "Git repository branch to checkout"
  type        = string
  default     = "main"
}
