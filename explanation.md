# Containerization notes

This document explains the design decisions and implementation for containerizing the YOLO app.

1) Choice of base images
- backend: `node:18-alpine` — small, secure, and compatible with current Node LTS.
- client: `node:18-alpine` (build stage) and `nginx:stable-alpine` (runtime) — multi-stage build reduces final image size by only keeping the static build in a minimal webserver image.
- database: official `mongo:6.0` (kept official and recent stable for compatibility).

2) Dockerfile directives used
- `FROM`: chosen minimal base images and a multi-stage build for client.
- `WORKDIR`, `COPY`, `RUN npm install`, `RUN npm run build` for the build stage.
- `EXPOSE` for documentation (ports are configured in `docker-compose.yml`).
- `CMD` to start the runtime (nginx for client, `npm start` for backend).

3) Docker-compose networking and ports
- A custom bridge network (`yolo-net`) is defined to isolate the services while allowing container name resolution (e.g., `mongodb://mongo:27017`).
- The backend service exposes `5000` to the host; the client is served by nginx on container port `80` and mapped to host port `3000` for convenience. The MongoDB service is internal but exposed via a named volume for persistence.

Frontend → Backend proxy
- The client `nginx` is configured to proxy requests under `/api/*` to `http://backend:5000` (internal service name). This allows the frontend to issue relative API calls (e.g., `/api/products`) that are forwarded to the backend in the Docker network so clients from other devices do not rely on `localhost` being reachable.

4) Volumes and persistence
- A named volume `mongo-data` is declared and mounted to `/data/db` to ensure data persistence across container restarts and host reboots.

5) Git workflow
- Use feature branches, descriptive commit messages and frequent commits while developing Docker assets. Example commits: `feat(docker): add client Dockerfile`, `chore(docker): add docker-compose`, `docs: add explanation.md`.

6) Debugging & validation
- If services fail to start, use `docker compose logs <service>` and `docker compose exec <service> sh` to inspect files and environment variables.
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
