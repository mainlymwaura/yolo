# YOLO - E-commerce Application (IP5: Kubernetes Deployment on GKE)

A MERN stack e-commerce application deployed on Google Kubernetes Engine (GKE) using Kubernetes best practices. This project demonstrates production-grade orchestration with StatefulSets for persistence, service discovery, and high availability.

## Quick Start - Kubernetes Deployment

### Prerequisites

Before deploying to GKE, ensure you have:

1. **Google Cloud SDK** installed and configured
2. **kubectl** CLI tool installed
3. A GCP project with billing enabled
4. Docker images pushed to Docker Hub:
   - `mainlymwaura/yolo-backend:1.0.0`
   - `mainlymwaura/yolo-client:1.0.0`

### Step 1: Create GKE Cluster

```bash
# Set your project ID
export PROJECT_ID="your-gcp-project-id"
export CLUSTER_NAME="yolo-cluster"
export REGION="us-central1"
export ZONE="us-central1-a"

# Create GKE cluster (3 nodes)
gcloud container clusters create $CLUSTER_NAME \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --num-nodes=3 \
  --machine-type=n1-standard-1 \
  --enable-ip-alias \
  --enable-stackdriver-kubernetes

# Get cluster credentials
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID

# Verify connection
kubectl get nodes
```

### Step 2: Deploy Application

```bash
# Clone the repository
git clone <your-repo-url>
cd yolo

# Deploy all manifests
kubectl apply -f k8s/

# Watch deployment progress
kubectl rollout status deployment/backend -n yolo-app
kubectl rollout status deployment/frontend -n yolo-app
kubectl rollout status statefulset/mongodb -n yolo-app

# Check all resources
kubectl get all -n yolo-app
```

### Step 3: Get Application URL

```bash
# Wait for LoadBalancer to assign external IP (may take 1-2 minutes)
kubectl get svc frontend-service -n yolo-app --watch

# Once EXTERNAL-IP is available, access the application at:
# http://EXTERNAL_IP:80

# Example output:
# NAME               TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)        AGE
# frontend-service   LoadBalancer   10.0.1.100     34.72.45.123   80:30123/TCP   2m
```

## Application Architecture

### Kubernetes Objects Deployed

1. **Namespace**: `yolo-app` - Isolated environment for application
2. **StorageClass**: `fast-ssd` - GCE PD SSD storage provisioner
3. **PersistentVolume**: Automatic provisioning via StorageClass
4. **MongoDB StatefulSet**:
   - 1 replica with persistent storage
   - Stable DNS names for pod identification
   - Data persists across pod restarts
   - Headless service for direct DNS resolution
5. **Backend Deployment**:
   - 2 replicas for high availability
   - ClusterIP service for internal communication
   - Probes for liveness and readiness
6. **Frontend Deployment**:
   - 2 replicas for high availability
   - LoadBalancer service for external access
   - Environment variable configuration
7. **ConfigMap**: Configuration for services
8. **Secrets**: MongoDB credentials

### Service Discovery

- **Frontend → Backend**: DNS name `backend-service.yolo-app.svc.cluster.local:5000`
- **Backend → MongoDB**: DNS name `mongodb.yolo-app.svc.cluster.local:27017`
- **External Access**: LoadBalancer IP assigned to `frontend-service`

## Data Persistence Testing

To verify MongoDB persistence:

```bash
# Add items to cart via the web interface at http://EXTERNAL_IP:80

# Delete the MongoDB pod
kubectl delete pod mongodb-0 -n yolo-app

# Kubernetes automatically recreates the pod and reattaches the PVC
kubectl get pods -n yolo-app

# Refresh the browser - items should still be in cart
```

The data persists because:
- MongoDB uses a StatefulSet with `volumeClaimTemplates`
- Each pod has its own PersistentVolumeClaim
- PVCs survive pod deletion and node failures
- New pods automatically mount the same PVC with existing data

## Kubernetes Concepts Implemented

### 1. StatefulSets for Databases

MongoDB is deployed as a StatefulSet because:
- Provides stable, unique network identities
- Maintains one PVC per replica
- Guarantees ordered pod creation and deletion
- Better than Deployments for stateful workloads

### 2. Persistent Volumes

Storage configuration:
- **Type**: Google Persistent Disk (SSD)
- **Size**: 5Gi per replica
- **Replication**: Regional (high availability)
- **Access Mode**: ReadWriteOnce (single pod)

### 3. Service Types

- **ClusterIP**: Backend service (internal only)
- **LoadBalancer**: Frontend service (external access)
- **Headless**: MongoDB service (direct pod DNS)

### 4. Configuration Management

- **ConfigMaps**: Non-sensitive configuration
- **Secrets**: Sensitive data (MongoDB password)
- **Environment Variables**: Runtime configuration

### 5. Health Checks

- **Liveness Probe**: Restarts failed containers
- **Readiness Probe**: Load balancer routing decision
- **Probe Types**: HTTP and exec-based checks

### 6. High Availability

- **Pod Replicas**: 2 instances per stateless service
- **Pod Anti-Affinity**: Spreads replicas across nodes
- **Rolling Updates**: Zero-downtime deployments
- **Resource Limits**: Prevents resource starvation

## Manifest Files

All Kubernetes manifests are in the `/k8s` directory:

- `01-namespace.yaml` - Application namespace
- `02-storage.yaml` - StorageClass and PVC
- `03-mongodb-statefulset.yaml` - MongoDB StatefulSet
- `04-secrets-configmap.yaml` - Credentials and config
- `05-backend-deployment.yaml` - Backend service
- `06-frontend-deployment.yaml` - Frontend service

## Common kubectl Commands

```bash
# View deployments and StatefulSets
kubectl get deployments -n yolo-app
kubectl get statefulsets -n yolo-app

# View services and endpoints
kubectl get svc -n yolo-app
kubectl get endpoints -n yolo-app

# View pods
kubectl get pods -n yolo-app
kubectl get pods -n yolo-app -o wide  # With node info

# View logs
kubectl logs -f <pod-name> -n yolo-app

# Access pod shell
kubectl exec -it <pod-name> -n yolo-app -- /bin/sh

# Describe resources
kubectl describe pod <pod-name> -n yolo-app
kubectl describe service frontend-service -n yolo-app

# Check resource usage
kubectl top pods -n yolo-app
kubectl top nodes

# View persistent volumes
kubectl get pvc -n yolo-app
kubectl describe pvc mongo-storage-mongodb-0 -n yolo-app
```

## Troubleshooting

### Check Pod Status

```bash
# If pod is stuck in Pending
kubectl describe pod <pod-name> -n yolo-app

# View pod logs for errors
kubectl logs <pod-name> -n yolo-app

# Previous logs if pod crashed
kubectl logs <pod-name> -n yolo-app --previous
```

### Verify Service Connectivity

```bash
# Test internal connectivity
kubectl exec -it backend-0 -n yolo-app -- curl mongodb:27017

# Check DNS resolution
kubectl exec -it backend-0 -n yolo-app -- nslookup mongodb

# Check service endpoints
kubectl get endpoints -n yolo-app
```

### Common Issues

1. **ImagePullBackOff**: Docker image not found in Docker Hub
   - Verify images exist and are public
   - Check image names in manifests

2. **CrashLoopBackOff**: Container crash on startup
   - Check logs: `kubectl logs <pod-name> -n yolo-app`
   - Verify environment variables in ConfigMap

3. **Pending PVC**: PersistentVolumeClaim not bound
   - Check StorageClass: `kubectl get storageclass`
   - Verify quota limits in GCP

4. **LoadBalancer External-IP stuck pending**: 
   - May take 2-3 minutes in GKE
   - Check GCP Load Balancing services
   - Verify cluster has appropriate permissions

## Cleanup

To delete the application and cluster:

```bash
# Delete all application resources
kubectl delete namespace yolo-app

# Delete GKE cluster
gcloud container clusters delete $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID

# Delete persistent disks (if not deleted with cluster)
gcloud compute disks list --project=$PROJECT_ID
gcloud compute disks delete <disk-name> --zone=$ZONE --project=$PROJECT_ID
```

## Deployment Verification Checklist

- [ ] All pods running: `kubectl get pods -n yolo-app`
- [ ] MongoDB StatefulSet healthy: `kubectl rollout status statefulset/mongodb -n yolo-app`
- [ ] Backend deployment healthy: `kubectl rollout status deployment/backend -n yolo-app`
- [ ] Frontend deployment healthy: `kubectl rollout status deployment/frontend -n yolo-app`
- [ ] Frontend LoadBalancer has external IP: `kubectl get svc -n yolo-app`
- [ ] Can access frontend at `http://EXTERNAL_IP:80`
- [ ] Can add items to cart
- [ ] Items persist after pod deletion test

## Project Structure

```
yolo/
├── k8s/                              # Kubernetes manifests
│   ├── 01-namespace.yaml             # Namespace definition
│   ├── 02-storage.yaml               # StorageClass and PVC
│   ├── 03-mongodb-statefulset.yaml   # MongoDB StatefulSet
│   ├── 04-secrets-configmap.yaml     # Credentials and config
│   ├── 05-backend-deployment.yaml    # Backend API service
│   └── 06-frontend-deployment.yaml   # Frontend web service
├── backend/                          # Node.js backend
│   ├── Dockerfile
│   ├── package.json
│   ├── server.js
│   └── ...
├── client/                           # React frontend
│   ├── Dockerfile
│   ├── package.json
│   ├── public/
│   ├── src/
│   └── ...
├── docker-compose.yml                # Local Docker Compose (optional)
├── explanation.md                    # Implementation details
└── README.md                          # This file
```

## Technologies Used

- **Container Orchestration**: Kubernetes (GKE)
- **Database**: MongoDB 6.0 (StatefulSet)
- **Backend**: Node.js with Express
- **Frontend**: React
- **Container Runtime**: Docker
- **Cloud Provider**: Google Cloud Platform
- **Storage**: Google Persistent Disks (SSD)

## Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine)
- [StatefulSets Guide](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

## Git Workflow

This project uses descriptive commits following the Git workflow:

1. Feature commits for each Kubernetes object
2. Clear commit messages explaining changes
3. Minimum 10 commits documenting implementation progress
4. All changes tracked in GitHub repository

## Author

Caleb Mwaura

## License

MIT
