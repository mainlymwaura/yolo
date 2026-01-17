# YOLO E-commerce Application - Ansible Configuration Management

## Overview

This document explains the Ansible playbook structure for automating the deployment of the YOLO e-commerce application on a Vagrant-provisioned Ubuntu 20.04 virtual machine. The playbook uses roles, blocks, tags, and variables to ensure modular, maintainable, and easily auditable infrastructure-as-code.

## Project Architecture

The YOLO application is a containerized e-commerce platform with the following microservices:

1. **MongoDB** - NoSQL database for product and order persistence
2. **Node.js Backend** - REST API server handling business logic
3. **React Frontend** - Modern SPA for user interface
4. **Docker Network** - Custom bridge network for inter-container communication

## Playbook Execution Flow

The main playbook (`site.yml`) executes in the following sequential order:

### 1. **Pre-tasks: System Preparation**
```yaml
- Update system packages via apt cache refresh
- Upgrade all installed packages to latest stable versions
```
**Purpose**: Ensures the system is up-to-date before infrastructure deployment
**Tags**: `always`, `system-update`

### 2. **Role: docker-setup**
**Execution Order**: First  
**Purpose**: Install and configure Docker and Docker Compose  
**Tasks Sequence**:

#### Block 1: Docker Installation
- Install system prerequisites (apt-transport-https, curl, gnupg, etc.)
- Add Docker's official GPG key to system keyring
- Register Docker's APT repository for Ubuntu
- Install docker.io, docker-compose, and python3-docker packages

#### Block 2: Docker Configuration
- Start Docker daemon and enable auto-start on boot
- Add vagrant user to docker group (privilege escalation for container operations)

#### Block 3: Docker Compose Installation
- Download Docker Compose binary from official release repository
- Set executable permissions and verify installation
- Display installed Docker Compose version

#### Block 4: Network Setup
- Create custom bridge network named `yolo-net` for container communication
- This network enables DNS-based service discovery between containers

**Why Docker-setup First?**: Docker must be installed before any container-based roles can execute. This is a hard dependency.

### 3. **Role: mongodb**
**Execution Order**: Second  
**Purpose**: Deploy MongoDB container for data persistence  
**Tasks Sequence**:

#### Block 1: Preparation
- Create data persistence directory: `/home/vagrant/yolo-app/mongo-data`
- Pull MongoDB 6.0 image from Docker Hub
- Set directory ownership to vagrant user

#### Block 2: Container Deployment
- Launch MongoDB container in detached mode
- Mount local volume for persistent data storage
- Connect to custom `yolo-net` bridge network
- Configure root credentials (admin/password)
- Expose MongoDB port 27017
- Set restart policy to `unless-stopped`
- Wait up to 30 seconds for MongoDB to be ready

**Environment Variables**:
- `MONGO_INITDB_ROOT_USERNAME`: admin
- `MONGO_INITDB_ROOT_PASSWORD`: password

**Why MongoDB Second?**: Backend service depends on MongoDB for data persistence. MongoDB must be running before backend deployment.

### 4. **Role: backend**
**Execution Order**: Third  
**Purpose**: Deploy Node.js backend REST API  
**Tasks Sequence**:

#### Block 1: Repository Cloning
- Check if application code already exists locally
- Clone YOLO repository from GitHub (`https://github.com/mainlymwaura/YOLO.git`)
- Checkout specified branch (default: `main`)
- Update ownership to vagrant user

#### Block 2: Image Preparation
- Pull pre-built backend image from Docker Hub
- Uses image: `mainlymwaura/yolo-backend:1.0.0`

#### Block 3: Container Deployment
- Launch backend container connected to `yolo-net`
- Expose port 5000 for API access
- Set environment variables:
  - `PORT`: 5000 (internal port)
  - `MONGODB_URI`: mongodb://yolo-mongo:27017/yolomy (connects to MongoDB container)
  - `NODE_ENV`: production
- Wait up to 60 seconds for backend service to accept connections

**MongoDB Integration**: Uses Docker DNS to connect to MongoDB container by hostname (`yolo-mongo`)

**Why Backend Third?**: Backend depends on MongoDB being operational. Frontend depends on backend API.

### 5. **Role: frontend**
**Execution Order**: Fourth  
**Purpose**: Deploy React frontend SPA  
**Tasks Sequence**:

#### Block 1: Image Preparation
- Pull pre-built frontend image from Docker Hub
- Uses image: `mainlymwaura/yolo-client:1.0.0`

#### Block 2: Container Deployment
- Launch frontend container
- Expose port 3000 (mapped from container port 80)
- Set environment variable:
  - `REACT_APP_API_URL`: http://localhost:5000
- Enable service restart unless explicitly stopped

#### Block 3: Health Verification
- Poll frontend HTTP endpoint up to 60 seconds
- Confirm 200 OK response from frontend
- Retry up to 3 times with 5-second intervals

**Why Frontend Last?**: Frontend is the user-facing layer and can only operate effectively when backend is ready. Testing happens after all services are deployed.

### 6. **Post-tasks: Deployment Verification**

#### Block 1: Service Health Checks
- Wait for backend API to respond on port 5000
- Wait for frontend web server to respond on port 3000

#### Block 2: Summary Display
- Display deployment success message with service URLs
- Format: Clear, human-readable confirmation of running services

## Variables and Configuration Management

### Global Variables (`group_vars/all.yml`)

Variables are centralized in a single file for easy management and modification:

```yaml
# Application Metadata
app_name: yolo
app_user: vagrant
app_home: /home/vagrant
app_deploy_dir: /home/vagrant/yolo-app

# Repository Configuration
app_repo_url: https://github.com/mainlymwaura/YOLO.git
app_repo_branch: main

# Docker Configuration
docker_network: yolo-net
docker_compose_version: "2.5.0"

# Service Identifiers
mongodb_container_name: yolo-mongo
backend_container_name: yolo-backend
frontend_container_name: yolo-client

# Image References
mongodb_image: mongo:6.0
backend_image: mainlymwaura/yolo-backend:1.0.0
frontend_image: mainlymwaura/yolo-client:1.0.0

# Service Ports
frontend_port: 3000
backend_port: 5000
mongodb_port: 27017

# Connection Strings
mongodb_uri: mongodb://yolo-mongo:27017/yolomy
react_app_api_url: http://localhost:5000
```

### Role-Specific Variables

Each role contains a `vars/main.yml` file for role-specific configuration:

- `roles/docker-setup/vars/main.yml`: Docker Compose version
- `roles/mongodb/vars/main.yml`: MongoDB-specific defaults (currently inherits from group vars)
- `roles/backend/vars/main.yml`: Backend-specific configuration
- `roles/frontend/vars/main.yml`: Frontend-specific configuration

## Blocks and Tags

### Tags Usage

Tags enable selective playbook execution for debugging and CI/CD pipelines:

```bash
# Run only Docker setup
ansible-playbook site.yml --tags "docker"

# Run only application deployment
ansible-playbook site.yml --tags "application"

# Run health checks only
ansible-playbook site.yml --tags "verification,health-check"

# Run everything except system updates
ansible-playbook site.yml --skip-tags "system-update"
```

### Tag Hierarchy

- `always`: Tasks that run regardless of tag filters
- `docker`: All Docker-related tasks
- `infrastructure`: Infrastructure setup (networks, volumes)
- `database`: MongoDB deployment
- `application`: Backend and frontend deployments
- `verification`: Health checks and validation

### Blocks Structure

Blocks logically group related tasks within roles:

1. **Installation Blocks**: Install software and dependencies
2. **Configuration Blocks**: Configure services and permissions
3. **Deployment Blocks**: Deploy containers and services
4. **Verification Blocks**: Health checks and validation

Benefits of blocks:
- Clear organization and readability
- Error handling at block level if needed
- Logical grouping for understanding execution flow
- Potential for block-level error handling (rescue/always)

## Ansible Modules Used

### Core Modules

| Module | Role | Purpose |
|--------|------|---------|
| `apt` | docker-setup | Package management (install/upgrade) |
| `apt_key` | docker-setup | Manage GPG keys for repositories |
| `apt_repository` | docker-setup | Add/remove APT repositories |
| `systemd` | docker-setup | Manage system services (Docker daemon) |
| `user` | docker-setup | Manage user accounts and groups |
| `get_url` | docker-setup | Download files from URLs |
| `command` | docker-setup | Execute arbitrary shell commands |
| `stat` | backend | Get file/directory facts |
| `file` | backend, mongodb | Manage file permissions and ownership |
| `git` | backend | Clone and manage Git repositories |
| `wait_for` | all roles | Wait for services to become available |
| `debug` | all roles | Display messages during execution |
| `uri` | frontend | Make HTTP requests for health checks |

### Community Docker Modules

| Module | Purpose |
|--------|---------|
| `community.docker.docker_network` | Create custom Docker networks |
| `community.docker.docker_image` | Pull/manage Docker images |
| `community.docker.docker_container` | Deploy and manage containers |

## Vagrant Integration

### Vagrantfile Configuration

```ruby
# Box: bento/ubuntu-20.04 (pre-built, no special setup needed)
# Memory: 2GB
# CPU: 2 cores
# Hostname: yolo-app-server
# IP: 192.168.33.10

# Port Forwarding:
# - 3000 -> Frontend (React)
# - 5000 -> Backend API (Node.js)
```

### Provisioning

Vagrant uses `ansible_local` provisioner, which:
1. Copies the playbook to the VM
2. Installs Ansible on the VM if not present
3. Runs the playbook locally on the VM
4. Execution: `vagrant up` triggers full deployment

## Data Persistence

MongoDB data is stored in a volume mounted to the host system:

```
Host: /home/vagrant/yolo-app/mongo-data
Container: /data/db
```

This ensures products added via the frontend persist across container restarts and VM reboots.

## Execution Timeline

```
vagrant up
    ↓
Boot VM from Ubuntu 20.04 image
    ↓
Run Ansible playbook locally on VM
    ↓
1. Update system packages (~30s)
    ↓
2. Install Docker & Docker Compose (~60s)
    ↓
3. Create docker network
    ↓
4. Deploy MongoDB container (~10s)
    ↓
5. Deploy backend container (~30s)
    ↓
6. Deploy frontend container (~30s)
    ↓
7. Health checks (5s)
    ↓
✓ Application ready at http://localhost:3000
```

**Total approximate time**: 3-5 minutes from `vagrant up` to ready state

## Error Handling Strategy

### Wait Conditions

Each service deployment includes explicit wait conditions:

```yaml
wait_for:
  host: localhost
  port: <service_port>
  delay: <initial_delay>
  timeout: <max_wait_time>
```

This prevents race conditions and ensures services are fully initialized before dependent services start.

### Idempotency

The playbook is designed to be idempotent:
- Can run multiple times safely
- Containers are checked before pulling images
- Git repo clone only if directory doesn't exist
- `docker_container` with `state: started` doesn't restart if already running

## Testing the Deployment

### Manual Verification

After `vagrant up` completes:

```bash
# SSH into VM
vagrant ssh

# Check running containers
docker ps

# View logs
docker logs yolo-mongo
docker logs yolo-backend
docker logs yolo-client

# Test API connectivity
curl http://localhost:5000/api/products

# Test MongoDB connectivity
docker exec -it yolo-mongo mongosh -u admin -p password
```

### Browser Testing

1. Open `http://localhost:3000`
2. Add a product using the form
3. Verify product appears in the list
4. Restart containers: `docker restart yolo-backend yolo-mongo`
5. Verify product still appears (data persistence test)

## Troubleshooting

### Common Issues

**Issue**: Port 3000 or 5000 already in use on host
**Solution**: Modify Vagrantfile port forwarding to different ports

**Issue**: Container fails to start
**Solution**: Check logs with `docker logs <container_name>`

**Issue**: Backend can't connect to MongoDB
**Solution**: Verify containers are on same network: `docker network inspect yolo-net`

**Issue**: Frontend shows "Cannot reach API"
**Solution**: Verify `REACT_APP_API_URL` environment variable in container

## Best Practices Demonstrated

1. **Separation of Concerns**: Each role handles one aspect of deployment
2. **DRY Principle**: Variables centralized, no value duplication
3. **Documentation**: Clear task names and descriptions
4. **Idempotency**: Safe to run multiple times
5. **Error Handling**: Explicit wait conditions and health checks
6. **Readability**: Blocks organize related tasks logically
7. **Maintainability**: Easy to add services or modify configuration
8. **Security**: User privilege escalation only where needed

## Conclusion

This playbook demonstrates enterprise-grade infrastructure automation using Ansible. The modular role structure, comprehensive variable management, and explicit health checks ensure reliable, repeatable deployments of the YOLO e-commerce application.
- Validate connectivity by `curl`ing the backend endpoints (e.g., `curl http://localhost:5000/api/products`).

7) Image tagging and DockerHub
- Use semantic versioning for image tags, e.g., `your-dockerhub-username/yolo-backend:1.0.0` and `your-dockerhub-username/yolo-client:1.0.0`.
- To push images: `docker build -t username/yolo-backend:1.0.0 ./backend` then `docker push username/yolo-backend:1.0.0`.
- Include a screenshot of the image on DockerHub (the UI showing the tagged image) as part of the submission for verification.

9) CI: GitHub Actions
- A workflow `./github/workflows/docker-publish.yml` is included to build and push both images to DockerHub when commits are pushed to `dockerize` or `master`, or when tags are created.
- To enable it, add `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets in the repository settings.


8) Running locally with Docker Compose
- Build and run the stack: `docker compose up --build -d`
- Stop and remove: `docker compose down -v` (removes volumes if requested).

Notes: Replace `your-dockerhub-username` in `docker-compose.yml` and tagging commands with your DockerHub username before pushing the images.
