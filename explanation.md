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

8) Running locally with Docker Compose
- Build and run the stack: `docker compose up --build -d`
- Stop and remove: `docker compose down -v` (removes volumes if requested).

## How this meets the rubric (concise answers)

- **Choice of base images**: backend uses `node:18-alpine` for a minimal, secure Node LTS base; client uses a multi-stage build (build: `node:18-alpine`, runtime: `nginx:stable-alpine`) to keep the final image small. Mongo uses the official `mongo:6.0` image.

- **Dockerfile directives**: standard directives are used: `FROM`, `WORKDIR`, `COPY`, `RUN` (dependency install and build), `ENV` (e.g., `NODE_OPTIONS` for OpenSSL compatibility), `EXPOSE` (informational), and `CMD`. Client builds are multi-stage to keep the runtime image minimal.

- **Networking**: a custom bridge network `yolo-net` is declared in `docker-compose.yml` so services resolve by name (backend connects to `mongodb://mongo:27017`). Host port mapping exposes backend on 5000 and client on 3000 (mapped to nginx:80).

- **Volumes**: a named volume `mongo-data` is mounted at `/data/db` to persist MongoDB data so products survive container restarts and host reboots.

- **Git workflow**: Use feature branches (we used `dockerize`), small descriptive commits (examples: `feat(docker): add docker-compose`, `fix(client): lint/import order`, `ci: add publish workflow`). Push branches and open PRs for review.

- **Debugging & validation**: Use `docker compose logs <service>`, `docker compose exec <service> sh`, and `curl` to validate endpoints; rebuild with `docker compose build --no-cache` when dependencies change; check disk space and git integrity if builds fail.

- **Image tagging & DockerHub**: images use semantic tags (we used `1.0.0`); we pushed `mainlymwaura/yolo-backend:1.0.0` and `mainlymwaura/yolo-client:1.0.0`. Include a DockerHub screenshot in `docs/dockerhub_screenshot.png` as proof of deployment.

If anything above needs extra detail for the submission, tell me which rubric item you want expanded and I'll add it to this file.

## Submission checklist

- Ensure `docker-compose.yml` is pushed to repo root and points to images you want to use (we use `mainlymwaura/yolo-backend:1.0.1` and `mainlymwaura/yolo-client:1.0.0`).
- Push Docker images to DockerHub and capture a screenshot showing the tag(s) (save as `docs/dockerhub_screenshot.png`).
- Confirm the GitHub Actions workflow `docker-publish.yml` is configured with your DockerHub secrets (`DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`) if you want CI publishing.
- Run the smoke tests locally or via the `stack-smoke-test.yml` workflow to confirm endpoints respond.


Notes: Replace `your-dockerhub-username` in `docker-compose.yml` and tagging commands with your DockerHub username before pushing the images.
