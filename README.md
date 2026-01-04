(# YOLO - E-commerce app)

This repo contains a MERN e-commerce app. The following section explains how to run the full stack using Docker Compose.

## Running with Docker Compose

1. The Docker images used in `docker-compose.yml` are tagged as `mainlymwaura/yolo-backend:1.0.0` and `mainlymwaura/yolo-client:1.0.0`. Replace these with your own DockerHub username if you plan to use your repo for images.
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

## DockerHub images

This project publishes two images to DockerHub under the user `mainlymwaura`:

- `mainlymwaura/yolo-backend:1.0.0`
- `mainlymwaura/yolo-client:1.0.0`

A GitHub Actions workflow is provided to build and push these images on pushes to `dockerize`/`master` or when tags are created. To enable automatic pushes, add the following secrets to your GitHub repository Settings → Secrets:

- `DOCKERHUB_USERNAME` — your DockerHub username
- `DOCKERHUB_TOKEN` — a Docker Hub access token (create one in DockerHub)

Place a screenshot of the DockerHub repo showing the tagged images in `docs/dockerhub_screenshot.png` before submission.


## Build and push images to DockerHub (optional)

Replace `username` with your DockerHub username and run:

```bash
# backend
docker build -t mainlymwaura/yolo-backend:1.0.0 ./backend
docker push mainlymwaura/yolo-backend:1.0.0

# client
docker build -t mainlymwaura/yolo-client:1.0.0 ./client
docker push mainlymwaura/yolo-client:1.0.0
```

Ensure the tags follow semver (e.g., `1.0.0`, `1.0.1`) and include a screenshot of your DockerHub repo with the new tag as proof.


