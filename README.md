# YOLO - E-commerce Application (IP3: Configuration Management with Ansible)

A MERN stack e-commerce application deployed and managed using Ansible configuration automation on Vagrant-provisioned virtual machines. This project demonstrates enterprise-grade infrastructure-as-code practices with modular role-based architecture.

## Quick Start

### Stage 1: Ansible Playbook Automation (Recommended)

Deploy the complete application with a single command:

```bash
# Clone the repository
git clone <your-repo-url>
cd yolo

# Ensure Vagrant and VirtualBox are installed
# Then provision and deploy
vagrant up

# Application will be ready at http://localhost:3000
```

The `vagrant up` command will:
1. Boot an Ubuntu 20.04 VM
2. Install Docker and Docker Compose
3. Deploy MongoDB, Backend, and Frontend containers
4. Run health checks
5. Display deployment summary

### Stage 1: Docker Compose (Manual)

Alternatively, run the application with Docker Compose directly:

```bash
# Build and start all services
docker compose up --build -d

# Application available at:
# Frontend: http://localhost:3000
# Backend API: http://localhost:5000

# Stop and clean up
docker compose down -v
```

## Directory Structure

```
yolo/
├── Vagrantfile                 # Vagrant VM configuration (Ubuntu 20.04)
├── docker-compose.yml          # Docker Compose service definitions
├── ansible/
│   ├── site.yml               # Main Ansible playbook (entry point)
│   ├── inventory.ini          # Ansible inventory configuration
│   ├── group_vars/
│   │   └── all.yml            # Global variables for all hosts
│   └── roles/
│       ├── docker-setup/      # Docker installation and configuration
│       ├── mongodb/           # MongoDB container deployment
│       ├── backend/           # Node.js backend container
│       └── frontend/          # React frontend container
├── backend/                    # Node.js/Express backend service
├── client/                     # React frontend application
├── docs/                       # Documentation and screenshots
├── explanation.md             # Detailed explanation of Ansible architecture
└── README.md                  # This file
```

## Architecture Overview

### Services

The application consists of four interconnected services:

1. **MongoDB** - NoSQL database
   - Image: `mongo:6.0`
   - Port: 27017 (internal only)
   - Volume: `mongo-data` for persistence

2. **Backend API** - Node.js/Express
   - Image: `mainlymwaura/yolo-backend:1.0.0`
   - Port: 5000
   - Environment: Connected to MongoDB

3. **Frontend** - React SPA
   - Image: `mainlymwaura/yolo-client:1.0.0`
   - Port: 3000
   - Environment: API endpoint configuration

4. **Docker Network** - Inter-service communication
   - Type: Custom bridge network (`yolo-net`)
   - Enables DNS-based service discovery

### Data Persistence

MongoDB data persists across container restarts:
- Host: `/home/vagrant/yolo-app/mongo-data`
- Container: `/data/db`

Products added via the frontend will persist when containers are restarted.

## Ansible Playbook Details

### Execution Order

The playbook executes in a carefully orchestrated sequence:

1. **System Update** - Update all system packages
2. **Docker Setup** - Install Docker, Docker Compose, and create bridge network
3. **MongoDB** - Deploy MongoDB container with persistent volume
4. **Backend** - Clone repository, build, and run backend service
5. **Frontend** - Deploy frontend with API configuration
6. **Health Checks** - Verify all services are responding

For detailed information about each role, variables, blocks, and tags, see [explanation.md](explanation.md).

### Key Features

- **Modular Roles**: Each service has its own role with clear responsibilities
- **Centralized Variables**: Single source of truth for configuration in `group_vars/all.yml`
- **Blocks & Tags**: Logical grouping and selective execution capabilities
- **Idempotent**: Safe to run multiple times without causing issues
- **Health Checks**: Explicit verification that services are ready
- **Error Handling**: Wait conditions prevent race conditions

### Running Specific Roles

```bash
# Run only Docker setup
ansible-playbook ansible/site.yml --tags "docker"

# Run only application deployment
ansible-playbook ansible/site.yml --tags "application"

# Run health checks only
ansible-playbook ansible/site.yml --tags "verification"

# Skip system updates
ansible-playbook ansible/site.yml --skip-tags "system-update"
```

## Testing the Application

### Browser Verification

1. Navigate to `http://localhost:3000`
2. You should see the YOLO e-commerce dashboard
3. Click "Add Product" and fill in the form
4. Submit the form - the product should appear in the list
5. Restart containers and verify the product persists

### Command-line Verification

```bash
# SSH into Vagrant VM
vagrant ssh

# Check running containers
docker ps

# View service logs
docker logs yolo-backend
docker logs yolo-mongo

# Test API
curl http://localhost:5000/api/products

# Stop and restart containers to test persistence
docker restart yolo-backend yolo-mongo
```

## Troubleshooting

### Issue: Vagrant fails to boot
**Solution**: Ensure VirtualBox is installed and "bento/ubuntu-20.04" box is cached

### Issue: Ports 3000 or 5000 already in use
**Solution**: Modify port mappings in Vagrantfile or docker-compose.yml

### Issue: Frontend shows "Cannot reach API"
**Solution**: Verify backend container is running and healthy with `docker logs yolo-backend`

### Issue: Products don't persist
**Solution**: Verify MongoDB volume is mounted correctly: `docker inspect yolo-mongo | grep -A 5 Mounts`

## Configuration Management

### Variables

Edit `ansible/group_vars/all.yml` to customize:

```yaml
app_deploy_dir: /home/vagrant/yolo-app        # Application directory
frontend_port: 3000                            # Frontend port
backend_port: 5000                             # Backend port
react_app_api_url: http://localhost:5000       # API endpoint for frontend
```

### Docker Credentials (Stage 2)

For Stage 2 deployment with Terraform, sensitive data should be managed via Ansible vault or environment variables.

## GitHub Actions

The project includes a GitHub Actions workflow for automated Docker image building and pushing to DockerHub. To enable:

1. Set repository secrets:
   - `DOCKERHUB_USERNAME`
   - `DOCKERHUB_TOKEN`

2. Images are automatically built and pushed on:
   - Pushes to `dockerize` or `master` branches
   - Creation of version tags

## Stage 2: Terraform Integration (Optional)

A second stage of this project integrates Terraform for resource provisioning. Check out the `Stage_two` branch for:

- Terraform configuration for resource provisioning
- Integration of Terraform and Ansible in a unified workflow
- Automated infrastructure and configuration management

## Best Practices Implemented

- **Infrastructure as Code**: Playbooks are version-controlled and repeatable
- **Separation of Concerns**: Each role handles one aspect of deployment
- **DRY Principle**: Centralized variables eliminate duplication
- **Documentation**: Clear task names and extensive documentation
- **Idempotency**: Safe to run multiple times
- **Health Checks**: Explicit verification of service readiness
- **Modularity**: Easy to add or modify services

## Git Workflow

The project uses semantic commit messages:

- `feat(...)`: New features
- `fix(...)`: Bug fixes
- `docs(...)`: Documentation updates
- `chore(...)`: Maintenance tasks

Example: `feat(ansible): add mongodb role with persistent storage`

## Requirements

- **Vagrant** 2.0+ with VirtualBox
- **Git** for repository cloning
- **Docker** and **Docker Compose** (installed by Ansible on VM)
- **Ansible** 2.9+ (installed by Vagrant provisioner on VM)
- **Disk Space**: ~5GB for VM and containers
- **Memory**: 2GB allocated to Vagrant VM

## Contributing

1. Create a feature branch: `git checkout -b feat/your-feature`
2. Make changes with descriptive commits
3. Test thoroughly with `vagrant up`
4. Push and create a pull request

## License

See LICENSE file for details.

## Support & Documentation

- See [explanation.md](explanation.md) for detailed architecture documentation
- Docker Compose setup: See [docker-compose.yml](docker-compose.yml)
- Ansible structure: See [ansible/](ansible/) directory
- Vagrant config: See [Vagrantfile](Vagrantfile)

Ensure the tags follow semver (e.g., `1.0.0`, `1.0.1`) and include a screenshot of your DockerHub repo with the new tag as proof.


