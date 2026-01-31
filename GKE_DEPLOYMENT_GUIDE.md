# GKE Deployment and Testing Guide - YOLO Application

This guide provides step-by-step instructions for deploying the YOLO application on Google Kubernetes Engine (GKE) with comprehensive testing and evidence collection.

## Prerequisites

Ensure you have:
1. Google Cloud Account with billing enabled
2. `gcloud` CLI installed and configured: `gcloud init`
3. `kubectl` installed: `gcloud components install kubectl`
4. Docker images available on Docker Hub:
   - `mainlymwaura/yolo-backend:1.0.0`
   - `mainlymwaura/yolo-client:1.0.0`

## Step 1: Set Up Google Cloud Project

```bash
# Set your project ID
export PROJECT_ID="your-gcp-project-id"
export CLUSTER_NAME="yolo-cluster"
export REGION="us-central1"
export ZONE="us-central1-a"

# Set GCP project
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable storage-api.googleapis.com

# Verify setup
gcloud config list
```

## Step 2: Create GKE Cluster

```bash
# Create a GKE cluster with 3 nodes
gcloud container clusters create $CLUSTER_NAME \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --num-nodes=3 \
  --machine-type=n1-standard-1 \
  --enable-ip-alias \
  --enable-stackdriver-kubernetes \
  --enable-autoscaling \
  --min-nodes=3 \
  --max-nodes=6

# This command will take 3-5 minutes to complete
# Wait for cluster to be ready
```

Output to capture:
```
Creating cluster yolo-cluster in us-central1-a... Cluster created.
kubeconfig entry generated for yolo-cluster.
NAME            LOCATION       MASTER_VERSION  MASTER_STATUS  NODES  STATUS
yolo-cluster    us-central1-a  1.xx.x          RUNNING        3      RUNNING
```

## Step 3: Configure kubectl Access

```bash
# Get cluster credentials
gcloud container clusters get-credentials $CLUSTER_NAME \
  --zone=$ZONE \
  --project=$PROJECT_ID

# Verify kubectl connection
kubectl cluster-info
kubectl get nodes
```

Expected output:
```
NAME                                    STATUS   ROLES    AGE   VERSION
gke-yolo-cluster-default-pool-xxxx      Ready    <none>   2m    v1.xx.x
gke-yolo-cluster-default-pool-yyyy      Ready    <none>   2m    v1.xx.x
gke-yolo-cluster-default-pool-zzzz      Ready    <none>   2m    v1.xx.x
```

## Step 4: Deploy YOLO Application

```bash
# Clone repository and navigate to project
cd /path/to/yolo

# Create namespace and deploy all manifests
kubectl apply -f k8s/

# Verify deployments were created
kubectl get all -n yolo-app
```

Expected output:
```
NAME                           READY   STATUS    RESTARTS   AGE
pod/backend-7d5c9f4d5d-xxxxx   1/1     Running   0          2m
pod/backend-7d5c9f4d5d-yyyyy   1/1     Running   0          2m
pod/frontend-7d5c9f4d5d-xxxxx  1/1     Running   0          2m
pod/frontend-7d5c9f4d5d-yyyyy  1/1     Running   0          2m
pod/mongodb-0                  1/1     Running   0          2m
```

## Step 5: Monitor Deployment Progress

```bash
# Watch MongoDB StatefulSet rollout
kubectl rollout status statefulset/mongodb -n yolo-app --timeout=300s

# Watch Backend Deployment
kubectl rollout status deployment/backend -n yolo-app --timeout=300s

# Watch Frontend Deployment
kubectl rollout status deployment/frontend -n yolo-app --timeout=300s

# Check all rollout status
kubectl rollout status all -n yolo-app
```

## Step 6: Get External IP and Access Application

```bash
# Get frontend LoadBalancer external IP
kubectl get svc frontend-service -n yolo-app

# Wait for EXTERNAL-IP to appear (may take 1-3 minutes)
kubectl get svc frontend-service -n yolo-app --watch
```

Expected output:
```
NAME               TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)        AGE
frontend-service   LoadBalancer   10.0.1.100     34.72.45.123   80:30123/TCP   3m
```

**Application URL**: `http://34.72.45.123:80` (replace with your EXTERNAL-IP)

## Step 7: Comprehensive Testing

### Test 1: Application Accessibility

```bash
# Test frontend is accessible
curl -I http://EXTERNAL_IP:80

# Expected response:
# HTTP/1.1 200 OK
```

### Test 2: Backend API Connectivity

```bash
# Port-forward to backend (in a separate terminal)
kubectl port-forward svc/backend-service 5000:5000 -n yolo-app

# In another terminal, test API
curl http://localhost:5000/api/products

# Should return products array
```

### Test 3: MongoDB Connectivity

```bash
# Execute shell in backend pod
kubectl exec -it <backend-pod-name> -n yolo-app -- /bin/bash

# Inside pod, test MongoDB connection
curl -s http://mongodb:27017/ | head -c 200

# Should return MongoDB welcome message (binary data)
```

### Test 4: Pod Status and Health

```bash
# Check all pods
kubectl get pods -n yolo-app -o wide

# Check pod descriptions (should show all pods Running)
kubectl describe pod <pod-name> -n yolo-app

# Check pod logs for errors
kubectl logs -f <pod-name> -n yolo-app

# Check container resource usage
kubectl top pods -n yolo-app
kubectl top nodes
```

Expected output:
```
NAME                          CPU(cores)   MEMORY(bytes)
backend-7d5c9f4d5d-xxxxx      50m          256Mi
backend-7d5c9f4d5d-yyyyy      48m          260Mi
frontend-7d5c9f4d5d-xxxxx     15m          128Mi
frontend-7d5c9f4d5d-yyyyy     12m          130Mi
mongodb-0                     75m          300Mi
```

### Test 5: Data Persistence (Critical Test)

```bash
# 1. Access the frontend UI at http://EXTERNAL_IP:80
# 2. Add items to cart (e.g., add 3-5 products)
# 3. Note the items displayed

# 4. Delete the MongoDB pod
kubectl delete pod mongodb-0 -n yolo-app

# 5. Kubernetes automatically recreates the pod
kubectl get pods -n yolo-app --watch

# 6. Wait for mongodb-0 to return to Running state (should be ~30 seconds)

# 7. Refresh the browser at http://EXTERNAL_IP:80
# 8. Verify that all items added to cart are still present

# 9. Verify the new pod has reattached to the same PVC
kubectl describe pvc mongo-storage-mongodb-0 -n yolo-app

# Should show:
# Name:          mongo-storage-mongodb-0
# Status:        Bound
# Volume:        pvc-xxxxxxxxx
```

### Test 6: Service Discovery

```bash
# From frontend pod, test backend accessibility
kubectl exec -it <frontend-pod-name> -n yolo-app -- nslookup backend-service

# From backend pod, test MongoDB accessibility
kubectl exec -it <backend-pod-name> -n yolo-app -- nslookup mongodb

# Should resolve to internal IPs
```

### Test 7: Load Balancing

```bash
# Check service endpoints
kubectl get endpoints -n yolo-app

# Expected output:
# NAME               ENDPOINTS                          AGE
# backend-service    10.0.1.10:5000,10.0.1.11:5000     5m
# frontend-service   10.0.2.5:80,10.0.2.6:80           5m
# mongodb            10.0.3.7:27017                    5m
```

## Step 8: Collect Evidence

### Screenshots to Capture

1. **GKE Cluster Overview**
```bash
gcloud container clusters describe $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID
```
Screenshot: Show cluster name, status, node count, kubernetes version

2. **Kubectl Cluster Info**
```bash
kubectl cluster-info
kubectl get nodes
```
Screenshot: Show all nodes are Ready

3. **All Pods Running**
```bash
kubectl get pods -n yolo-app -o wide
```
Screenshot: Show all 5 pods (2 backend, 2 frontend, 1 mongodb) Running

4. **Services and LoadBalancer**
```bash
kubectl get svc -n yolo-app
```
Screenshot: Show EXTERNAL-IP assigned to frontend-service

5. **Application Accessibility**
- Screenshot: Browser showing http://EXTERNAL_IP:80 with YOLO application loaded

6. **Add Product to Cart**
- Screenshot: Product list visible in browser
- Screenshot: Add product to cart (if available)
- Screenshot: Cart showing items

7. **Pod Persistence Test**
```bash
# Before deletion
kubectl get pods -n yolo-app
# Screenshot: mongodb-0 with AGE

# After deletion
kubectl delete pod mongodb-0 -n yolo-app
# Screenshot: New mongodb-0 created with AGE = 0s

# After wait (30 seconds)
kubectl get pods -n yolo-app
# Screenshot: mongodb-0 Running again
```

8. **Data Persistence Verification**
- Screenshot: Browser after pod deletion showing original cart items still present

9. **Resource Usage**
```bash
kubectl top pods -n yolo-app
kubectl top nodes
```
Screenshot: Show resource usage for all pods and nodes

10. **Persistent Volume Status**
```bash
kubectl get pvc -n yolo-app
kubectl describe pvc mongo-storage-mongodb-0 -n yolo-app
```
Screenshot: Show PVC bound and mounted to mongodb-0

## Step 9: Logging and Monitoring

### View Container Logs

```bash
# View logs from all containers
kubectl logs -l app=backend -n yolo-app --all-containers=true --tail=50

# View MongoDB startup logs
kubectl logs mongodb-0 -n yolo-app --tail=30

# Follow logs in real-time
kubectl logs -f frontend-7d5c9f4d5d-xxxxx -n yolo-app
```

### Check Events

```bash
# View recent cluster events
kubectl get events -n yolo-app --sort-by='.lastTimestamp'

# Describe specific pod for detailed events
kubectl describe pod <pod-name> -n yolo-app
```

## Step 10: Troubleshooting Commands

```bash
# If pods are not running, check pod details
kubectl describe pod <pod-name> -n yolo-app

# If image pull fails
kubectl get events -n yolo-app | grep ImagePull

# If MongoDB won't start
kubectl logs mongodb-0 -n yolo-app
kubectl exec -it mongodb-0 -n yolo-app -- mongosh

# Check StorageClass and PVCs
kubectl get storageclass
kubectl get pvc -n yolo-app
kubectl get pv

# Test DNS resolution
kubectl exec -it <pod-name> -n yolo-app -- nslookup mongodb
kubectl exec -it <pod-name> -n yolo-app -- nslookup backend-service
```

## Step 11: Document Deployment Information

Create a `DEPLOYMENT_INFO.md` file in your repository with:

```markdown
# YOLO Application - GKE Deployment Information

## Deployment Date
[Date deployed]

## GKE Cluster Details
- **Cluster Name**: yolo-cluster
- **Region**: us-central1
- **Zone**: us-central1-a
- **Kubernetes Version**: [version from kubectl version]
- **Node Count**: 3
- **Machine Type**: n1-standard-1

## Application URL
**Frontend**: http://[EXTERNAL_IP]:80

Replace [EXTERNAL_IP] with the value from:
```bash
kubectl get svc frontend-service -n yolo-app
```

## Kubernetes Objects Deployed
- Namespace: yolo-app
- MongoDB: StatefulSet with 1 replica
- Backend: Deployment with 2 replicas
- Frontend: Deployment with 2 replicas
- Services: 1 LoadBalancer, 1 ClusterIP, 1 Headless
- ConfigMap: 1
- Secrets: 1
- PersistentVolumeClaim: 1 (5Gi SSD)

## Testing Status
- [x] All pods running
- [x] Frontend accessible from external IP
- [x] Backend API responding
- [x] MongoDB connected and operational
- [x] Data persistence verified (pod deletion test)
- [x] Service discovery working
- [x] Load balancing functional

## Cleanup Instructions
```bash
# Delete namespace (deletes all resources within)
kubectl delete namespace yolo-app

# Delete GKE cluster
gcloud container clusters delete yolo-cluster --zone=us-central1-a
```
```

## Step 12: Final Verification Checklist

- [ ] GKE cluster created and running (3 nodes)
- [ ] kubectl configured and connected to cluster
- [ ] All manifests deployed successfully (`kubectl apply -f k8s/`)
- [ ] All 5 pods running (2 backend, 2 frontend, 1 mongodb)
- [ ] Frontend LoadBalancer has assigned EXTERNAL-IP
- [ ] Application accessible from browser at http://EXTERNAL_IP:80
- [ ] Backend API responding at http://EXTERNAL_IP:5000/api/products (via port-forward)
- [ ] MongoDB connected and operational (verified via logs)
- [ ] Products displayed in application
- [ ] Cart functionality working (items can be added)
- [ ] Data persistence test passed (items persist after pod deletion)
- [ ] All health checks passing (liveness and readiness probes)
- [ ] Resource usage reasonable (CPU < 500m, Memory < 1Gi per pod)
- [ ] Logs show no errors or critical warnings
- [ ] PersistentVolumeClaim bound and mounted
- [ ] Screenshots and evidence collected
- [ ] DEPLOYMENT_INFO.md created with live URL
- [ ] GitHub repository updated with all changes
- [ ] README.md contains deployment instructions
- [ ] explanation.md contains implementation details

## Cleanup When Finished

```bash
# Delete the application namespace (removes all resources)
kubectl delete namespace yolo-app

# Delete the GKE cluster
gcloud container clusters delete $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID --quiet

# Verify deletion
gcloud container clusters list --project=$PROJECT_ID
```

## Submitting Your Project

1. Ensure all commits are pushed to GitHub
2. Repository should contain:
   - `/k8s/` directory with all manifest files
   - `README.md` with deployment instructions
   - `explanation.md` with implementation details
   - `DEPLOYMENT_INFO.md` with live URL and testing results
3. Provide evidence screenshots in a separate folder or documentation
4. Live application should be accessible at the documented URL

## Support Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [StatefulSets Guide](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Service Types](https://kubernetes.io/docs/concepts/services-networking/service/)
