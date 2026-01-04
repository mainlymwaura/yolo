Rubric evidence for containerizing the YOLO MERN app

Overview
- Repository: https://github.com/mainlymwaura/yolo
- Branch with work: `dockerize`

Files added / modified

1. Dockerfiles
- `backend/Dockerfile` — production-optimized Node image, `NODE_ENV=production`, uses `npm ci --only=production`.
- `client/Dockerfile` — multi-stage build (node build -> nginx runtime), sets `REACT_APP_API_URL` for runtime configuration and uses `NODE_OPTIONS=--openssl-legacy-provider` to handle Node 18 OpenSSL issues.

2. Compose & orchestration
- `docker-compose.yml` — defines `mongo`, `backend`, `client` services; exposes ports, mounts named volume `mongo-data` for persistence, and creates custom network `yolo-net`.

3. Persistence & Volumes
- `docker-compose.yml` — named volume `mongo-data: driver: local` mapped to `/data/db` in the `mongo` container.

4. Networking
- Services communicate over the bridge network `yolo-net`. Backend consumes `MONGODB_URI=mongodb://mongo:27017/yolomy` and client uses `REACT_APP_API_URL`.

5. Image tagging & pushing
- Images built and pushed to Docker Hub with semver tags:
  - `mainlymwaura/yolo-client:1.0.0`
  - `mainlymwaura/yolo-backend:1.0.0` and `mainlymwaura/yolo-backend:1.0.1`

6. CI / Automation
- `.github/workflows/docker-publish.yml` — builds and pushes Docker images to Docker Hub when a semver tag is pushed (uses `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` as repo secrets).
- `.github/workflows/stack-smoke-test.yml` — brings up the stack in CI and runs basic API smoke tests on pushes to `dockerize`.

7. Documentation & explanation
- `explanation.md` — documents the choices made for images, networking, volumes, build-time flags, and verification steps.
- `README.md` — includes instructions to run `docker compose up --build` and verification steps.

8. Verification steps performed locally
- `docker compose up --build` (fixed client build issues by setting `NODE_OPTIONS=--openssl-legacy-provider` and fixing import order) ✅
- Confirmed API reachable at `http://localhost:5000/api/products` and data persisted across restarts (volume `mongo-data`). ✅
- Images pushed to Docker Hub and pulled successfully on fresh start with `docker compose pull` ✅

Notes and pending items
- Add a Docker Hub screenshot in `docs/dockerhub_screenshot.png` and commit it to the `dockerize` branch as visual evidence (placeholder file exists in `docs/`).

Contact
- If you'd like, I can also open the PR for review (prepared PR body available) — I can't open one via the GitHub CLI here because it's not installed, but you can create it with: https://github.com/mainlymwaura/yolo/pull/new/dockerize
