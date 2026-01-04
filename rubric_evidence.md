# Rubric evidence

This file lists where each rubric objective is satisfied in the repo and links to artifacts.

- **Git Work Flow**
  - Branch: `dockerize` contains all containerization changes and documentation.
  - Commits: multiple descriptive commits (21 total on branch at time of writing). See `git log`.

- **Image Selection & Size**
  - Client image: `mainlymwaura/yolo-client:1.0.0` — size ~84.6MB (multi-stage build with `nginx:stable-alpine`).
  - Backend image: `mainlymwaura/yolo-backend:1.0.1` — size ~287MB (optimized `node:18-alpine`, `npm ci --only=production`).
  - Total image sizes well below 400MB target.

- **Image Versioning**
  - Images are tagged with semantic versions: `1.0.0`, `1.0.1`.

- **Image Deployment**
  - Images pushed to Docker Hub under `mainlymwaura`.
  - DockerHub screenshot should be added to `docs/dockerhub_screenshot.png` (placeholder file present).

- **Service Orchestration**
  - `docker-compose.yml` orchestrates `mongo`, `backend`, and `client` services.
  - Custom bridge network `yolo-net` and named volume `mongo-data` are used for persistence.

- **Debugging & Validation**
  - Smoke test workflow: `.github/workflows/stack-smoke-test.yml` runs basic API tests on pushes to `dockerize`.
  - Manual smoke tests performed locally and recorded in logs; product persistence confirmed after restart.

If you want, I can prepare a PDF or snapshot of this evidence for submission. Add the DockerHub screenshot file and I will commit it and finalize the docs.
