# Stage 2: Terraform + Ansible Integration - Technical Explanation

## Executive Summary

Stage 2 demonstrates enterprise-grade infrastructure automation by combining:
- **Terraform**: Infrastructure as Code (IaC) for resource provisioning
- **Ansible**: Configuration Management for application deployment

This integration creates a fully automated pipeline where Terraform provisions the virtual machine, and Ansible configures it with Docker and deploys the containerized e-commerce application.

## Architecture Overview

### Traditional Approach (Stage 1)

```
User runs: vagrant up
    ↓
Vagrant boots VM
    ↓
Vagrant runs Ansible provisioner
    ↓
Ansible deploys application
```

**Limitation**: Vagrant is tightly coupled with VM provisioning; harder to manage with external tools

### Unified Approach (Stage 2)

```
User runs: terraform apply && ansible-playbook site.yml
    ↓
Terraform provisions VM resources
    ↓
Terraform outputs VM details (IP, hostname)
    ↓
Ansible uses outputs to configure VM
    ↓
Ansible deploys application
```

**Advantages**: Separation of concerns, easier to manage multiple environments, enterprise-ready

## Component Breakdown

### Terraform Configuration

#### Provider Configuration (`provider.tf`)

```hcl
terraform {
  required_providers {
    vagrant = {
      source  = "hashicorp/vagrant"
      version = ">= 0.2.0"
    }
  }
}

provider "vagrant" {}
```

**Purpose**: Declares that we're using the Vagrant provider

**Why Vagrant as Provider?**: 
- Vagrant simplifies local VM management
- Runs on developer's machine (unlike AWS, Azure)
- Consistent with Stage 1 development flow
- No cloud credentials needed

#### Variables (`variables.tf`)

Key variables:

```hcl
variable "vagrant_box" {
  default = "bento/ubuntu-20.04"
  # Pre-built, minimal Ubuntu image
}

variable "vm_memory" {
  default = 2048
  # Sufficient for Docker containers
}

variable "private_network_ip" {
  default = "192.168.33.20"
  # Static IP for consistent connection
}

variable "app_repo_url" {
  default = "https://github.com/mainlymwaura/YOLO.git"
  # Application source
}
```

**Why Use Variables?**
- **Reusability**: Same configuration for multiple environments
- **Flexibility**: Override at deployment time with `-var` flag or `.tfvars`
- **Documentation**: Variables serve as interface documentation
- **Best Practice**: Avoid hardcoding values

#### Resource Definition (`main.tf`)

```hcl
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
      "pip3 install docker pyyaml"
    ]
  }
}
```

**Key Aspects**:

1. **Resource Type**: `vagrant_vm` - provision a Vagrant VM
2. **Resource Name**: `yolo_app` - identifier for this resource
3. **Box Selection**: Using bento/ubuntu-20.04
4. **Shell Provisioning**: Installs Python and Docker SDK (required for Ansible to work)
5. **Outputs**: VM IP and hostname captured for Ansible use

**Why Shell Provisioning?**
- Ansible requires Python 3
- Docker SDK for Python needed for Docker modules
- Alternative: Let Ansible install these (but shell is faster)

### Ansible Integration

#### Master Playbook (`site.yml`)

```yaml
- name: "YOLO E-commerce Platform - Stage 2"
  hosts: localhost
  connection: local
  
  roles:
    - role: terraform-provisioning
      tags: ["terraform"]
```

**Key Details**:

- **hosts: localhost**: Runs on control machine (where you execute ansible-playbook)
- **connection: local**: Doesn't SSH anywhere initially
- **terraform-provisioning role**: Handles Terraform execution and output extraction

#### Terraform Provisioning Role

The `terraform-provisioning` role orchestrates the workflow:

1. **Task: Initialize Terraform**
```yaml
- name: "Initialize Terraform working directory"
  terraform:
    project_path: "{{ terraform_dir }}"
    state: present
    force_init: false
```

- Runs `terraform init` to download provider plugins
- `force_init: false` skips if already initialized

2. **Task: Plan Terraform Deployment**
```yaml
- name: "Generate Terraform plan"
  terraform:
    project_path: "{{ terraform_dir }}"
    state: planned
    plan_file: "{{ terraform_dir }}/tfplan"
```

- Creates execution plan (safe, read-only)
- Helps identify what will change

3. **Task: Apply Terraform Configuration**
```yaml
- name: "Apply Terraform plan"
  terraform:
    project_path: "{{ terraform_dir }}"
    state: present
    plan_file: "{{ terraform_dir }}/tfplan"
  register: terraform_apply
```

- Executes actual provisioning
- `register: terraform_apply` captures outputs for next step

4. **Task: Extract VM Details**
```yaml
- name: "Extract VM IP from Terraform outputs"
  set_fact:
    vm_ip: "{{ terraform_apply.outputs.vm_ip.value }}"
    vm_hostname: "{{ terraform_apply.outputs.vm_hostname.value }}"
```

- Captures Terraform outputs (VM IP and hostname)
- Sets as Ansible facts for downstream use

5. **Task: Create Dynamic Inventory**
```yaml
- name: "Create inventory for provisioned VM"
  copy:
    content: |
      [all]
      {{ vm_hostname }} ansible_host={{ vm_ip }}
```

- Creates inventory file with provisioned VM details
- Enables Ansible to connect to the VM for configuration

6. **Task: Wait for VM Readiness**
```yaml
- name: "Wait for SSH connectivity to VM"
  wait_for:
    host: "{{ vm_ip }}"
    port: 22
    timeout: 300
```

- Ensures VM is fully booted before configuration
- Prevents connection timeouts

## Execution Flow Diagram

```
Playbook Start
    ↓
[terraform-provisioning role]
├─ Initialize Terraform
├─ Plan deployment
├─ Apply configuration (VM created)
├─ Extract outputs (IP, hostname)
├─ Create dynamic inventory
└─ Wait for SSH
    ↓
[Post-tasks - Future: Configuration]
├─ Could invoke docker-setup role
├─ Could invoke mongodb role
├─ Could invoke backend role
└─ Could invoke frontend role
    ↓
Deployment Complete
```

## Advantages Over Stage 1

### 1. **Separation of Concerns**

| Aspect | Stage 1 | Stage 2 |
|--------|---------|---------|
| VM Provisioning | Vagrant |  Terraform |
| Configuration | Ansible | Ansible |
| Tool Coupling | Tightly coupled | Loosely coupled |

### 2. **Scalability**

- **Stage 1**: Can't easily manage multiple VMs without Vagrant files
- **Stage 2**: Use Terraform workspaces/modules for multiple environments

### 3. **Integration with Enterprise Tools**

- **Terraform Cloud**: Manage state and runs centrally
- **GitHub Actions**: Automate `terraform apply` and `ansible-playbook`
- **ServiceNow**: Integrate infrastructure provisioning with ticketing

### 4. **State Management**

- **Stage 1**: Vagrant stores state locally (hard to track)
- **Stage 2**: Terraform state file explicitly manages resource state

### 5. **Code Organization**

- **Stage 1**: Infrastructure tied to Vagrantfile
- **Stage 2**: Infrastructure defined in HCL (similar to Ansible YAML)

## Variables Management

### Hierarchy (Top to Bottom Priority)

1. **Environment Variables**: `TF_VAR_` prefix
2. **Command-line**: `terraform apply -var="key=value"`
3. **Variable Files**: `-var-file=production.tfvars`
4. **`terraform.tfvars`**: Auto-loaded if exists
5. **`variables.tf`**: Default values

### Example Workflow

```bash
# Development
terraform apply -var-file=dev.tfvars

# Staging
terraform apply -var-file=staging.tfvars

# Production
terraform apply -var-file=production.tfvars
```

## Data Persistence

### Stage 1 vs Stage 2

Both stages use same data persistence strategy:

```yaml
volumes:
  - "{{ mongodb_data_dir }}:/data/db"
```

Where:
- `{{ mongodb_data_dir }}` = `/home/vagrant/yolo-app/mongo-data`
- Mounted to container's `/data/db`
- Persists across container restarts and VM reboots

## Error Handling Strategy

### Terraform Errors

1. **Init Errors**: Usually means wrong provider or network issues
2. **Plan Errors**: Validate HCL syntax and variable references
3. **Apply Errors**: Often resource-specific (e.g., port conflicts)

**Error Handling in Ansible**:
```yaml
- name: "Apply Terraform"
  terraform:
    project_path: "{{ terraform_dir }}"
    state: present
  register: terraform_apply
  failed_when: terraform_apply.failed | default(false)
```

### Connection Timeouts

```yaml
- name: "Wait for VM"
  wait_for:
    host: "{{ vm_ip }}"
    port: 22
    timeout: 300  # 5 minutes max wait
```

## Security Considerations

### Secrets Management

**Current Implementation** (Development):
- No special handling for secrets
- MongoDB credentials hardcoded

**Production Approach**:

1. **Terraform Sensitive Variables**:
```hcl
variable "db_password" {
  sensitive = true
  type      = string
}
```

2. **Ansible Vault**:
```bash
ansible-vault create secret_vars.yml
```

3. **Environment Variables**:
```bash
export TF_VAR_db_password="secure_password"
export ANSIBLE_VAULT_PASSWORD_FILE="/path/to/vault/pass"
```

### State File Security

⚠️ **Important**: Terraform state contains all resource data (including passwords)

**Recommendations**:
- Don't commit state to Git (use `.gitignore`)
- Use remote state backend (S3, Terraform Cloud)
- Enable encryption at rest
- Restrict file permissions: `chmod 600 terraform.tfstate`

## Idempotency

Both Terraform and Ansible are idempotent:

### Terraform Idempotency

```
Run 1: terraform apply
  → Resources created
Run 2: terraform apply
  → No changes (if nothing changed)
Run 3: terraform apply
  → No changes
```

### Ansible Idempotency

```
Run 1: ansible-playbook site.yml
  → VM configured, containers deployed
Run 2: ansible-playbook site.yml
  → No unnecessary changes (state already correct)
```

## Testing Strategy

### Unit Testing (Terraform)

```bash
terraform validate    # Check syntax
terraform fmt -check # Check formatting
terraform plan       # Dry-run
```

### Integration Testing (Ansible)

```bash
ansible-playbook site.yml --check    # Dry-run
ansible-playbook site.yml --diff     # Show changes
ansible-playbook site.yml -vvv       # Verbose
```

### End-to-End Testing

```bash
# 1. Apply Terraform
cd Stage_two/terraform && terraform apply

# 2. Run Ansible
ansible-playbook Stage_two/site.yml

# 3. Verify
curl http://192.168.33.20:5000/api/products
```

## Performance Considerations

| Operation | Time |
|-----------|------|
| Terraform init | ~30 seconds |
| VM provisioning | ~60 seconds |
| Shell provisioning (Python install) | ~30 seconds |
| Ansible playbook | ~2 minutes |
| **Total** | **~3 minutes** |

## Migration Path: Stage 1 → Stage 2

### Step 1: Create Terraform Configuration
- Define same resources as Vagrant config
- Extract variables

### Step 2: Copy Ansible Playbooks
- Use same roles and playbooks
- Update inventory paths

### Step 3: Create Master Orchestrator
- Playbook that runs terraform-provisioning
- Then runs other roles

### Step 4: Test
- Run through entire flow
- Verify identical results

## Advanced Patterns

### Multi-Environment Setup

```
Stage_two/
├── dev.tfvars
├── staging.tfvars
├── production.tfvars
└── terraform/
```

Deploy to any environment:
```bash
terraform apply -var-file=production.tfvars
```

### Modular Terraform

```
terraform/
├── modules/
│   ├── vm/
│   │   ├── main.tf
│   │   └── variables.tf
│   └── networking/
│       ├── main.tf
│       └── variables.tf
└── main.tf
```

### Conditional Deployment

```hcl
resource "vagrant_vm" "yolo_app" {
  count = var.deploy_vm ? 1 : 0
  # ... resource config
}
```

## Conclusion

Stage 2 demonstrates professional infrastructure automation patterns:
- **Terraform** for reproducible resource provisioning
- **Ansible** for idempotent configuration management
- **Integration** between tools for seamless workflow

This approach scales from single VM to multi-environment enterprise deployments while maintaining code quality, documentation, and maintainability.
