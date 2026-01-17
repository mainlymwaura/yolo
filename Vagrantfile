# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-20.04"
  config.vm.hostname = "yolo-app-server"
  
  # Network configuration
  config.vm.network "private_network", ip: "192.168.56.10"
  config.vm.network "forwarded_port", guest: 3000, host: 3000, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 5000, host: 5000, host_ip: "127.0.0.1"
  
  # Provider configuration
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
    vb.name = "yolo-ecommerce-app"
  end
  
  # Synced folder for the application
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox", disabled: true
  
  # Copy ansible directory to VM
  config.vm.provision "file", source: "ansible", destination: "/home/vagrant/ansible"
  
  # Install Python and required dependencies
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y python3 python3-pip git
    pip3 install --upgrade pip
    pip3 install docker pyyaml
  SHELL
  
  # Provisioning with Ansible
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "~/ansible/site.yml"
    ansible.inventory_path = "~/ansible/inventory.ini"
    ansible.install = true
    ansible.install_mode = "pip3"
    ansible.version = "latest"
    ansible.extra_vars = {
      ansible_python_interpreter: "/usr/bin/python3"
    }
  end
end
