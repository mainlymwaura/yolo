(# YOLO - E-commerce app)

This repo contains a MERN e-commerce app. The following section explains how to run the full stack using Docker Compose.

## Running with Docker Compose

1. Replace `your-dockerhub-username` in `docker-compose.yml` with your DockerHub username (optional — only required if you plan to pull prebuilt images).
2. Build and start the stack:

```bash
docker compose up --build -d
```

3. Open the frontend at http://localhost:3000 and the backend API is available at http://localhost:5000.

4. To stop and remove containers and volumes:

```bash
docker compose down -v
```

See `explanation.md` for implementation choices and guidance on tagging/pushing images to DockerHub.

## Build and push images to DockerHub (optional)

Replace `username` with your DockerHub username and run:

```bash
# backend
docker build -t username/yolo-backend:1.0.0 ./backend
docker push username/yolo-backend:1.0.0

# client
docker build -t username/yolo-client:1.0.0 ./client
docker push username/yolo-client:1.0.0
```

Ensure the tags follow semver (e.g., `1.0.0`, `1.0.1`) and include a screenshot of your DockerHub repo with the new tag as proof.


