# YOLO E-commerce Platform - Stage 2: Terraform + Ansible Integration

## Overview

Stage 2 demonstrates the power of combining Terraform (Infrastructure as Code) with Ansible (Configuration Management). This approach enables fully automated resource provisioning and application deployment with a single command.

## Architecture

### Workflow

```
$ terraform init && terraform plan && terraform apply
$ ansible-playbook site.yml
    ↓
[Terraform Phase]
- Provision Vagrant VM with specified resources
- Apply VirtualBox configuration
    ↓
[Ansible Phase]
- Configure Docker on provisioned VM
- Deploy MongoDB, Backend, and Frontend containers
- Run health checks
    ↓
✓ Complete e-commerce application running
```

## Directory Structure

```
Stage_two/
├── terraform/
│   ├── main.tf                    # VM resource definition
│   ├── provider.tf               # Terraform provider configuration
│   ├── variables.tf              # Input variables
│   ├── terraform.tfvars.example  # Example variable overrides
│   └── .terraform/               # Terraform working directory (gitignored)
├── ansible/
│   ├── site.yml                  # Master playbook
│   ├── inventory.ini             # Ansible inventory
│   ├── requirements.yml          # Ansible Galaxy dependencies
│   ├── .ansible.cfg              # Ansible configuration
│   ├── group_vars/
│   │   └── all.yml              # Global variables
│   └── roles/
│       ├── terraform-provisioning/  # Invokes Terraform
│       ├── docker-setup/           # Docker installation
│       ├── mongodb/                # MongoDB container
│       ├── backend/                # Backend container
│       └── frontend/               # Frontend container
└── README.md                     # This file
```

## Quick Start

### Prerequisites

- **Terraform** 1.0+
- **Ansible** 2.9+
- **Vagrant** 2.0+
- **VirtualBox** (or other Vagrant provider)
- **Git**

### Deployment Steps

1. **Initialize and apply Terraform** (provisions VM):

```bash
cd Stage_two/terraform
terraform init
terraform plan
terraform apply
```

2. **Run Ansible playbook** (configures and deploys application):

```bash
cd ../..
ansible-playbook Stage_two/site.yml
```

3. **Access the application**:

```
Frontend: http://192.168.33.20:3000
Backend API: http://192.168.33.20:5000
```

### Combined One-Liner (After initial setup)

```bash
cd Stage_two/terraform && \
terraform apply -auto-approve && \
cd ../.. && \
ansible-playbook Stage_two/site.yml
```

## Configuration

### Terraform Variables

Edit `terraform.tfvars` to customize the deployment:

```hcl
# VM Configuration
vagrant_box           = "bento/ubuntu-20.04"
vm_hostname           = "yolo-app-server-tf"
vm_memory             = 2048
vm_cpus               = 2
private_network_ip    = "192.168.33.20"

# Application Configuration
app_repo_url          = "https://github.com/mainlymwaura/YOLO.git"
app_repo_branch       = "main"
```

### Ansible Variables

Edit `ansible/group_vars/all.yml` for Ansible customization:

```yaml
docker_network: yolo-net
frontend_port: 3000
backend_port: 5000
mongodb_port: 27017
```

## How It Works

### Terraform Phase

The `terraform-provisioning` Ansible role:

1. **Initializes Terraform**: `terraform init`
2. **Plans Deployment**: `terraform plan`
3. **Applies Configuration**: `terraform apply`
4. **Extracts Outputs**: Captures VM IP and hostname
5. **Updates Inventory**: Creates dynamic inventory for Ansible

### Ansible Phase

The playbook then uses the provisioned VM to:

1. Install Docker and Docker Compose
2. Create Docker network
3. Deploy MongoDB with persistent volume
4. Deploy Node.js backend
5. Deploy React frontend
6. Run health checks

## State Management

### Terraform State

- **File Location**: `Stage_two/terraform/terraform.tfstate`
- **Backup Location**: `terraform.tfstate.backup` (should be gitignored)
- **Git Strategy**: Commit `terraform.tfstate` but gitignore backups

**Note**: In production, use remote state backends (S3, Terraform Cloud, etc.)

## Advantages of This Approach

### Infrastructure as Code
- **Version Control**: Track all infrastructure changes in Git
- **Repeatability**: Provision identical environments consistently
- **Auditability**: Complete history of infrastructure evolution

### Configuration as Code
- **Idempotency**: Safe to run multiple times
- **Documentation**: Code documents the configuration
- **Modular**: Easy to add or modify services

### Combined Benefits
- **Single Workflow**: One command to provision and configure
- **Separation of Concerns**: Terraform handles infrastructure, Ansible handles configuration
- **Flexibility**: Use Terraform outputs in Ansible (dynamic inventory)
- **Scalability**: Easy to scale from single VM to multiple environments

## Troubleshooting

### Terraform Issues

**Error**: `Error: Unsupported provider type`
**Solution**: Ensure VirtualBox provider plugin is installed

**Error**: `terraform: command not found`
**Solution**: Install Terraform from https://www.terraform.io/downloads

### Ansible Issues

**Error**: `MODULE FAILURE\nSeen in ansible stderr`
**Solution**: Install required collections: `ansible-galaxy collection install -r requirements.yml`

**Error**: SSH connection refused
**Solution**: Ensure Terraform VM has finished provisioning. Check: `vagrant status`

### Common Issues

**Problem**: Changes in Terraform don't update Ansible inventory
**Solution**: Manually run Terraform apply before Ansible, or modify the role to auto-detect outputs

**Problem**: Port conflicts (3000, 5000 already in use)
**Solution**: Modify variables in `terraform.tfvars` and `ansible/group_vars/all.yml`

## Testing

### Verify Terraform Resources

```bash
cd Stage_two/terraform
terraform state list
terraform state show vagrant_vm.yolo_app
terraform output
```

### Verify Ansible Deployment

```bash
# SSH into provisioned VM
vagrant ssh -n yolo-app-server-tf

# Check running containers
docker ps

# View logs
docker logs yolo-backend
docker logs yolo-mongo

# Test API
curl http://localhost:5000/api/products
```

### End-to-End Test

1. Navigate to `http://192.168.33.20:3000` in browser
2. Add a product through the form
3. Verify product appears in list
4. Restart containers: `docker restart yolo-backend yolo-mongo`
5. Verify product still persists

## CI/CD Integration

This deployment can be integrated into CI/CD pipelines:

```yaml
# Example GitLab CI/CD
deploy:
  stage: deploy
  script:
    - cd Stage_two/terraform && terraform apply -auto-approve
    - cd ../.. && ansible-playbook Stage_two/site.yml -i Stage_two/ansible/inventory-stage2.ini
  environment:
    name: production
```

## Best Practices

1. **State Management**: Keep Terraform state secure and backed up
2. **Variables**: Use `.tfvars` for sensitive data (add to `.gitignore`)
3. **Modular Code**: Keep roles small and focused
4. **Documentation**: Document any custom modifications
5. **Testing**: Always test with `terraform plan` before `apply`
6. **Idempotency**: Ensure Ansible roles can run multiple times safely

## Advanced Features

### Scaling

To deploy multiple environments:

```bash
terraform workspace new staging
terraform apply -var-file=staging.tfvars

terraform workspace new production
terraform apply -var-file=production.tfvars
```

### Remote State

Store Terraform state remotely:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "yolo/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### Integration with Ansible Cloud

For larger deployments, consider:
- **Ansible Tower**: Enterprise automation platform
- **Terraform Cloud**: Managed Terraform remote state and runs
- **ServiceNow/HashiCorp Integration**: Enterprise workflow automation

## Cleanup

### Destroy All Resources

```bash
# Remove containers and volumes
ansible-playbook Stage_two/site.yml --tags "cleanup"

# Destroy Terraform resources
cd Stage_two/terraform
terraform destroy
```

### Cleanup Commands

```bash
# Remove only containers
docker rm -f yolo-mongo yolo-backend yolo-client

# Remove volume data
docker volume rm yolo-mongo-data

# Remove Vagrant VM
vagrant destroy yolo-app-server-tf
```

## Documentation

For more information:
- [Terraform Documentation](https://www.terraform.io/docs/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Vagrant Documentation](https://www.vagrantup.com/docs/)
- [Main README](../README.md)
- [Explanation Document](../explanation.md)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review logs: `terraform show`, `ansible-playbook -vvv`
3. Consult official documentation
4. Open an issue on GitHub

## Next Steps

- Implement remote state backend for production
- Add monitoring and logging
- Integrate with CI/CD pipeline
- Set up automated testing
- Document custom modifications
