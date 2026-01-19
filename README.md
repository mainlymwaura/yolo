# 🛒 YOLO E-commerce DevOps Project

## 📋 Overview
This project automates the deployment of a full-stack e-commerce application using modern DevOps tools. The goal was to create a reproducible, containerized environment that can be spun up with a single command. The application consists of a React frontend, a Node.js backend API, and a MongoDB database, all orchestrated with Docker and managed by an Ansible playbook provisioned through Vagrant.

## 🚀 Quick Start
Getting the application up and running is straightforward:

```bash
# 1. Clone the repository
git clone https://github.com/mainlymwaura/yolo.git
cd yolo

# 2. Provision the VM and deploy the application (takes 10-15 minutes)
vagrant up

# 3. Access the application
#    Frontend: http://localhost:3000
#    Backend API: http://localhost:5000/api/products
That's it! The vagrant up command handles everything: creating the virtual machine, installing Docker, pulling the application images, and starting all services.

🏗️ Architecture & Tech Stack
Infrastructure as Code: Vagrant with an Ubuntu 20.04 (Focal) base box.

Configuration Management: Ansible playbook (site.yml) with modular roles.

Containerization: Docker for each application component (frontend, backend, database).

Application Stack:

Frontend: React.js served by Nginx (Container: mainlymwaura/yolo-client:1.0.0)

Backend: Node.js/Express API (Container: mainlymwaura/yolo-backend:1.0.0)

Database: MongoDB with persistent data storage (Container: mongo:6.0)

✅ Validation & Testing
The deployment has been thoroughly validated. Here's how you can verify it:

Check Container Status (from the host machine):

bash
# SSH into the VM and list containers
vagrant ssh
docker ps
# You should see three running containers: yolo-mongo, yolo-backend, yolo-client
Test the API Endpoint:

bash
curl http://localhost:5000/api/products
# Expected output: A JSON array, potentially with a test product.
Test Full Resilience & Data Persistence:
This is a key requirement. The setup ensures that product data survives container restarts.

bash
# Inside the VM, restart all containers
docker restart yolo-mongo yolo-backend yolo-client
sleep 5
curl http://localhost:5000/api/products
# The same product data should still be present.
🐛 Troubleshooting Common Issues
Here are solutions to problems encountered during development:

"A VirtualBox machine with the name 'yolo-ecommerce-app' already exists."
This happens if a previous VM wasn't cleaned up. Fix it with:

bash
# On your host machine, not inside the VM
VBoxManage unregistervm "yolo-ecommerce-app" --delete-all
vagrant up
Ansible Playbook Fails on "Start backend container" with a PORT error.
The backend Docker container requires the PORT environment variable to be a string. This is fixed in the code by using the | string filter in the Ansible task. If you encounter this, ensure your ansible/roles/backend/tasks/main.yml has the line:

yaml
PORT: "{{ backend_port_internal | string }}"
Git Clone fails looking for the 'main' branch.
Our repository uses the master branch. This is configured in ansible/group_vars/all.yml with app_repo_branch: master.

📁 Project Structure
text
yolo/
├── Vagrantfile                 # Defines the Ubuntu VM and provisioning
├── ansible/
│   ├── site.yml               # Main Ansible playbook
│   ├── inventory.ini          # Ansible inventory (localhost)
│   ├── group_vars/
│   │   └── all.yml            # Centralized variables (ports, image names, etc.)
│   └── roles/                 # Modular Ansible roles
│       ├── docker-setup/      # Installs Docker and creates network
│       ├── mongodb/           # Deploys MongoDB container with volume
│       ├── backend/           # Clones code & deploys backend API container
│       └── frontend/          # Deploys frontend React container
├── README.md                  # This file
└── explanation.md             # Detailed breakdown of the Ansible playbook logic
📄 Requirements Fulfilled
This project successfully completes Stage 1 of the assignment requirements:

Vagrant VM provisioned with Ubuntu 20.04.

Ansible playbook using roles, variables, blocks, and tags.

Docker containers for each application component.

Code cloned from GitHub and application deployed automatically.

E-commerce application accessible via browser with persistent data.
