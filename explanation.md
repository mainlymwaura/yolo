# YOLO Deployment: Playbook Logic & Execution Order

## 🎯 Why the Order of Execution Matters
Ansible runs tasks sequentially. For a multi-service application like this, getting the order wrong means services won't find their dependencies. The playbook is structured to follow a logical, dependency-driven flow:

1.  **First, build the foundation** (Docker).
2.  **Then, start the data layer** (Database).
3.  **Next, bring up the business logic** (Backend API).
4.  **Finally, launch the user interface** (Frontend).

This mimics how you would start the services manually and ensures reliability.

## 👨‍💻 Detailed Role Breakdown & Positioning

### 1. Role: `docker-setup`
*   **Position**: **First**. Nothing else can run without Docker.
*   **Function**: Prepares the host to be a container runtime environment.
*   **Key Tasks & Modules**:
    *   `apt`: Installs the `docker.io` and `docker-compose` packages.
    *   `systemd`: Ensures the Docker daemon (`docker.service`) is running.
    *   `user`: Adds the `vagrant` user to the `docker` group (so commands can be run without `sudo`).
    *   `docker_network`: Creates a custom bridge network named `yolo-net`. This is crucial—it allows the containers to communicate with each other by name (e.g., the backend can connect to `yolo-mongo`).

### 2. Role: `mongodb`
*   **Position**: **Second**. Runs after Docker is ready, but before the backend.
*   **Function**: Deploys the persistent database.
*   **Key Tasks & Modules**:
    *   `file`: Creates the persistent data directory on the VM (`/home/vagrant/yolo-mongo-data`). This directory is mounted into the container, so data survives restarts.
    *   `docker_image`: Pulls the `mongo:6.0` image from Docker Hub.
    *   `docker_container`: The core task. It:
        *   Starts a container named `yolo-mongo`.
        *   Connects it to the `yolo-net` network.
        *   Maps port `27017` from the container to the VM.
        *   Mounts the data directory created earlier to `/data/db` inside the container.

### 3. Role: `backend`
*   **Position**: **Third**. Must wait for MongoDB to be ready.
*   **Function**: Deploys the Node.js API that powers the application.
*   **Key Tasks & Modules**:
    *   `git`: Clones the application source code from GitHub. The playbook is idempotent—it checks if the repo already exists first.
    *   `docker_image`: Pulls the pre-built `mainlymwaura/yolo-backend:1.0.0` image.
    *   `docker_container`: The most complex task in this role. It:
        *   Starts the `yolo-backend` container on the `yolo-net`.
        *   Maps port `5000`.
        *   **Critical Environment Variables**: This is where a key fix was implemented. The `env` dictionary passes configuration to the container:
            ```yaml
            env:
              PORT: "{{ backend_port_internal | string }}"  # The | string filter was essential
              MONGODB_URI: "{{ mongodb_uri }}"             # Points to 'mongodb://yolo-mongo:27017/yolomy'
              NODE_ENV: "production"
            ```
            Initially, the `PORT` variable caused a failure because Ansible passed the number `5000` in a way Docker misinterpreted. Adding the `| string` filter explicitly converted it to a string `"5000"`, resolving the error.
    *   `wait_for`: Pauses execution to verify the backend API is actually listening on port 5000 before moving on.

### 4. Role: `frontend`
*   **Position**: **Fourth and Final**. Requires the backend API to be up.
*   **Function**: Serves the React.js user interface.
*   **Key Tasks & Modules**:
    *   `docker_image`: Pulls the `mainlymwaura/yolo-client:1.0.0` image.
    *   `docker_container`: Starts the `yolo-client` container.
        *   It's connected to `yolo-net` so it can talk to the backend.
        *   Maps host port `3000` to container port `80` (where Nginx runs inside the container).
        *   The `react_app_api_url` environment variable is configured to point at the backend container (`yolo-backend`).
    *   `uri`: Performs a final health check by making an HTTP request to `http://localhost:3000` to confirm the frontend is serving pages correctly.

## 🔧 Key Design Decisions & Learnings
1.  **Pulling vs. Building Images**: The playbook pulls pre-built images from Docker Hub for speed and consistency. This aligns with a CI/CD pipeline where images are built once and then deployed.
2.  **Centralized Variables**: All configurable values (ports, image names, repository URLs) are stored in `group_vars/all.yml`. This makes the playbook easy to adapt (e.g., changing the MongoDB version or frontend port).
3.  **Idempotency**: The playbook can be run safely multiple times (`vagrant provision`). Tasks use Ansible's built-in idempotence (e.g., `apt` only installs if missing) and explicit checks (like checking if a Git repo exists).
4.  **Problem-Solving**: The two main hurdles were the VirtualBox VM conflict (solved with `VBoxManage`) and the backend's `PORT` environment variable type error (solved with the `| string` filter). These are classic "hands-on" issues that reinforce understanding.

This structure ensures a robust, repeatable, and understandable deployment process for the YOLO e-commerce application.
