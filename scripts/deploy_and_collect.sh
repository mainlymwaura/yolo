#!/usr/bin/env bash
set -euo pipefail

# deploy_and_collect.sh
# Usage: PROJECT_ID=your-project CLUSTER_NAME=your-cluster ZONE=us-central1-a ./scripts/deploy_and_collect.sh

PROJECT_ID=${PROJECT_ID:-}
CLUSTER_NAME=${CLUSTER_NAME:-yolo-cluster}
ZONE=${ZONE:-us-central1-a}
NUM_NODES=${NUM_NODES:-3}
NAMESPACE=${NAMESPACE:-yolo-app}
EVIDENCE_DIR=${EVIDENCE_DIR:-./evidence}

if [ -z "$PROJECT_ID" ]; then
  echo "ERROR: set PROJECT_ID environment variable"
  echo "Example: PROJECT_ID=my-gcp-project CLUSTER_NAME=my-cluster ZONE=us-central1-a ./scripts/deploy_and_collect.sh"
  exit 1
fi

mkdir -p "$EVIDENCE_DIR"

echo "Checking gcloud authentication..."
if ! gcloud auth list --format="value(account)" | grep -q .; then
  echo "No active gcloud account. Run: gcloud auth login && gcloud config set project $PROJECT_ID"
  exit 1
fi

echo "Ensure project is set"
gcloud config set project "$PROJECT_ID"

# Create cluster if it doesn't exist
if ! gcloud container clusters describe "$CLUSTER_NAME" --zone "$ZONE" --project "$PROJECT_ID" >/dev/null 2>&1; then
  echo "Creating GKE cluster $CLUSTER_NAME in $ZONE..."
  gcloud container clusters create "$CLUSTER_NAME" \
    --zone="$ZONE" \
    --num-nodes="$NUM_NODES" \
    --machine-type=n1-standard-1 \
    --project="$PROJECT_ID" \
    --enable-ip-alias
else
  echo "Cluster $CLUSTER_NAME already exists."
fi

echo "Fetching cluster credentials..."
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE" --project "$PROJECT_ID"

echo "Applying Kubernetes manifests..."
kubectl apply -f k8s/

echo "Waiting for workloads to become available (backend, frontend, statefulset)..."
kubectl rollout status deployment/backend -n "$NAMESPACE" --timeout=300s || true
kubectl rollout status deployment/frontend -n "$NAMESPACE" --timeout=300s || true
kubectl rollout status statefulset/mongodb -n "$NAMESPACE" --timeout=300s || true

# Wait for LoadBalancer IP for frontend
echo "Waiting for frontend external IP (may take 1-3 minutes)..."
FRONTEND_IP=""
for i in {1..36}; do
  FRONTEND_IP=$(kubectl get svc frontend-service -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  if [ -n "$FRONTEND_IP" ]; then break; fi
  sleep 5
done

# Collect evidence
kubectl get all -n "$NAMESPACE" -o wide > "$EVIDENCE_DIR/kubectl-get-all.txt"
kubectl get pvc -n "$NAMESPACE" -o wide > "$EVIDENCE_DIR/kubectl-pvc.txt"
kubectl describe statefulset mongodb -n "$NAMESPACE" > "$EVIDENCE_DIR/describe-mongodb.txt" || true
kubectl get svc frontend-service -n "$NAMESPACE" -o yaml > "$EVIDENCE_DIR/frontend-svc.yaml"

echo "FRONTEND_IP=${FRONTEND_IP}" | tee "$EVIDENCE_DIR/frontend-ip.txt"

if [ -n "$FRONTEND_IP" ]; then
  echo "Fetching frontend index..."
  curl -sS "http://${FRONTEND_IP}" -o "$EVIDENCE_DIR/frontend-index.html" || true
  curl -I "http://${FRONTEND_IP}" > "$EVIDENCE_DIR/frontend-headers.txt" || true
fi

# Basic backend API check
BACKEND_POD=$(kubectl get pods -n "$NAMESPACE" -l app=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -n "$BACKEND_POD" ]; then
  kubectl exec -n "$NAMESPACE" "$BACKEND_POD" -- sh -c 'curl -sS http://localhost:5000/api/products || true' > "$EVIDENCE_DIR/backend-products.json" || true
fi

# Test persistence: delete mongodb pod and capture pod list after recreation
echo "Deleting MongoDB pod to test persistence (StatefulSet will recreate)..."
kubectl delete pod -n "$NAMESPACE" -l app=mongodb --wait=false || true
sleep 10
kubectl get pods -n "$NAMESPACE" -o wide > "$EVIDENCE_DIR/after-delete-pods.txt"

echo "Evidence collected in $EVIDENCE_DIR"
if [ -n "$FRONTEND_IP" ]; then
  echo "Application should be available at: http://${FRONTEND_IP}"
else
  echo "Frontend external IP not available yet. Check: kubectl get svc frontend-service -n $NAMESPACE"
fi
