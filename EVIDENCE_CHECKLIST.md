# Evidence Collection Template for YOLO GKE Deployment

Use this document to record all evidence of successful deployment on Google Kubernetes Engine.

## 1. GKE Cluster Setup Evidence

### Screenshot 1: Cluster Created
```bash
gcloud container clusters describe yolo-cluster --zone=us-central1-a
# Save output showing:
# - name: yolo-cluster
# - status: RUNNING
# - nodeCount: 3
# - Kubernetes version
```

### Screenshot 2: Nodes Running
```bash
kubectl get nodes
# Output should show:
# NAME                                    STATUS   ROLES    AGE   VERSION
# gke-yolo-cluster-default-pool-xxxxx     Ready    <none>   5m    v1.xx.x
# gke-yolo-cluster-default-pool-yyyyy     Ready    <none>   5m    v1.xx.x
# gke-yolo-cluster-default-pool-zzzzz     Ready    <none>   5m    v1.xx.x
```

## 2. Kubernetes Manifests Deployed

### Screenshot 3: Namespace Created
```bash
kubectl get namespace yolo-app
# Output:
# NAME       STATUS   AGE
# yolo-app   Active   5m
```

### Screenshot 4: All Objects Created
```bash
kubectl get all -n yolo-app

# Output should show:
# NAME                           READY   STATUS    RESTARTS   AGE
# pod/backend-xxxxx              1/1     Running   0          3m
# pod/backend-yyyyy              1/1     Running   0          3m
# pod/frontend-xxxxx             1/1     Running   0          3m
# pod/frontend-yyyyy             1/1     Running   0          3m
# pod/mongodb-0                  1/1     Running   0          4m
#
# NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)        AGE
# service/backend-service        ClusterIP      10.0.1.100      <none>         5000/TCP       4m
# service/frontend-service       LoadBalancer   10.0.1.101      34.72.45.123   80:30123/TCP   4m
# service/mongodb                ClusterIP      None            <none>         27017/TCP      4m
#
# NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/backend                    2/2     2            2           4m
# deployment.apps/frontend                   2/2     2            2           4m
#
# NAME                                                  DESIRED   CURRENT   READY   AGE
# statefulset.apps/mongodb                             1         1         1       4m
```

## 3. Services and LoadBalancer Evidence

### Screenshot 5: LoadBalancer External IP Assigned
```bash
kubectl get svc frontend-service -n yolo-app

# Output:
# NAME               TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)        AGE
# frontend-service   LoadBalancer   10.0.1.101     34.72.45.123   80:30123/TCP   5m
```

### Screenshot 6: All Service Endpoints
```bash
kubectl get endpoints -n yolo-app

# Output:
# NAME               ENDPOINTS                          AGE
# backend-service    10.0.1.10:5000,10.0.1.11:5000     5m
# frontend-service   10.0.2.5:80,10.0.2.6:80           5m
# mongodb            10.0.3.7:27017                    5m
```

## 4. Application Accessibility Evidence

### Screenshot 7: Frontend in Browser
Take a screenshot of:
```
URL: http://34.72.45.123:80
Shows: YOLO e-commerce application homepage
- Product list visible
- Add to cart button visible
- Navigation working
```

### Screenshot 8: Products Loaded
Screenshot showing:
- Product images visible
- Product names displayed
- Prices shown
- "Add to Cart" buttons functional

## 5. Cart Functionality Testing

### Screenshot 9: Adding Product to Cart
Steps:
1. Click "Add to Cart" on a product
2. Take screenshot showing:
   - Product added confirmation
   - Cart item count updated (if visible)
   - Product details shown in cart

### Screenshot 10: Multiple Items in Cart
Screenshot showing:
- At least 3 items added to cart
- Each item with name and price
- Cart total calculation (if available)
- "Checkout" or similar action button

## 6. Data Persistence Testing - CRITICAL

### Screenshot 11: Items in Cart Before Pod Deletion
```bash
# Terminal command:
kubectl get pod -n yolo-app | grep mongodb

# Output:
# mongodb-0                  1/1     Running   0          10m
```
Screenshot showing:
- Browser with cart items visible (e.g., 3-5 products)
- Products clearly listed with names
- Cart status showing items are persisted

### Screenshot 12: Delete MongoDB Pod
```bash
kubectl delete pod mongodb-0 -n yolo-app

# Terminal output showing:
# pod "mongodb-0" deleted
```
Screenshot showing the delete command executed

### Screenshot 13: Pod Automatically Recreated
```bash
kubectl get pod -n yolo-app | grep mongodb

# Output showing new pod creation:
# mongodb-0                  1/1     Running   0          45s
```
Screenshot showing:
- mongodb-0 pod running with AGE = 45s (or similar small value)
- This proves Kubernetes recreated the pod

### Screenshot 14: Data Persisted After Pod Deletion
Browser screenshot showing:
```
URL: http://34.72.45.123:80
- All cart items still visible
- Same items as Screenshot 11
- No data loss despite pod deletion
- This proves StatefulSet + PVC persistence works
```

## 7. Pod Status and Health

### Screenshot 15: All Pods Healthy
```bash
kubectl get pods -n yolo-app -o wide

# All pods showing:
# - STATUS: Running
# - READY: 1/1
# - RESTARTS: 0
# - No pending or error states
```

### Screenshot 16: Pod Resource Usage
```bash
kubectl top pods -n yolo-app

# Output:
# NAME                          CPU(cores)   MEMORY(bytes)
# backend-7d5c9f4d5d-xxxxx      50m          256Mi
# backend-7d5c9f4d5d-yyyyy      48m          260Mi
# frontend-7d5c9f4d5d-xxxxx     15m          128Mi
# frontend-7d5c9f4d5d-yyyyy     12m          130Mi
# mongodb-0                     75m          300Mi
```

### Screenshot 17: Node Resource Usage
```bash
kubectl top nodes

# Output showing nodes have available resources:
# NAME                                    CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# gke-yolo-cluster-default-pool-xxxxx    350m         17%    1200Mi          40%
# gke-yolo-cluster-default-pool-yyyyy    340m         17%    1150Mi          38%
# gke-yolo-cluster-default-pool-zzzzz    330m         16%    1100Mi          36%
```

## 8. Logs and Monitoring

### Screenshot 18: MongoDB Logs - Healthy Startup
```bash
kubectl logs mongodb-0 -n yolo-app --tail=20

# Should show successful startup messages
```
Screenshot showing:
- No ERROR messages
- "ready to accept connections" message
- Or similar success indicators

### Screenshot 19: Backend Logs - Connected to MongoDB
```bash
kubectl logs <backend-pod-name> -n yolo-app --tail=20
```
Screenshot showing:
- No connection errors
- Successfully connected to MongoDB
- Ready to serve requests

### Screenshot 20: Frontend Logs - Running
```bash
kubectl logs <frontend-pod-name> -n yolo-app --tail=20
```
Screenshot showing:
- Nginx or web server running
- No error messages
- Ready to serve static files

## 9. Persistent Volume Evidence

### Screenshot 21: PersistentVolume Claims
```bash
kubectl get pvc -n yolo-app

# Output:
# NAME                         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# mongo-storage-mongodb-0      Bound    pvc-xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx    5Gi        RWO            fast-ssd       10m
```

### Screenshot 22: PersistentVolume Bound
```bash
kubectl describe pvc mongo-storage-mongodb-0 -n yolo-app

# Output showing:
# Name:              mongo-storage-mongodb-0
# Namespace:         yolo-app
# StorageClass:      fast-ssd
# Status:            Bound
# Volume:            pvc-xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx
# Capacity:          5Gi
# Access Modes:      RWO
# Mounted By:        mongodb-0
```

### Screenshot 23: GCP Persistent Disk
```bash
gcloud compute disks list --filter="zone:us-central1-a"

# Should show gke-pvc-xxxxxxxxx disk for MongoDB storage
```
Screenshot showing:
- Persistent disk created
- Size: 5GB
- Status: in use
- Zone: us-central1-a

## 10. Service Discovery Testing

### Screenshot 24: DNS Resolution from Pod
```bash
kubectl exec -it <backend-pod-name> -n yolo-app -- nslookup mongodb

# Output:
# Server:         10.0.0.10
# Address:        10.0.0.10#53
#
# Name:   mongodb.yolo-app.svc.cluster.local
# Address: 10.0.3.7
```

### Screenshot 25: Backend to MongoDB Connectivity
```bash
kubectl exec -it <backend-pod-name> -n yolo-app -- curl http://mongodb:27017

# Should show binary MongoDB response (not a connection error)
```

## 11. High Availability Testing

### Screenshot 26: Pod Anti-Affinity Distribution
```bash
kubectl get pods -n yolo-app -o wide

# Output showing pods distributed:
# NAME                    NODE                                    
# backend-7d5c9f4d5d-xxxxx   gke-yolo-cluster-default-pool-xxxxx
# backend-7d5c9f4d5d-yyyyy   gke-yolo-cluster-default-pool-yyyyy
# frontend-7d5c9f4d5d-xxxxx  gke-yolo-cluster-default-pool-zzzzz
# frontend-7d5c9f4d5d-yyyyy  gke-yolo-cluster-default-pool-xxxxx
# mongodb-0                  gke-yolo-cluster-default-pool-yyyyy
```
Each backend and frontend replica on different node

### Screenshot 27: Rolling Update Works
```bash
# Update deployment to cause rolling update
kubectl set image deployment/backend \
  backend=mainlymwaura/yolo-backend:1.0.0 -n yolo-app

kubectl get pods -n yolo-app --watch

# Should see pods being updated without full downtime
```
Screenshot showing:
- New pods starting
- Old pods terminating
- Some pods always Ready

## Summary Table

Create a summary table:

| Component | Expected | Actual | Status |
|-----------|----------|--------|--------|
| GKE Cluster | 3 nodes Running | [number] | ✓ |
| MongoDB StatefulSet | 1/1 Running | [status] | ✓ |
| Backend Deployment | 2/2 Running | [status] | ✓ |
| Frontend Deployment | 2/2 Running | [status] | ✓ |
| Frontend LoadBalancer | EXTERNAL-IP assigned | [IP] | ✓ |
| Application URL | Accessible | [URL] | ✓ |
| Cart functionality | Items add successfully | [test result] | ✓ |
| Data persistence | Items survive pod restart | [test result] | ✓ |
| Storage | 5Gi PVC bound to mongodb-0 | [status] | ✓ |
| All health checks | Passing | [count] passed | ✓ |

## Final Checklist for Submission

- [ ] All 27 screenshots captured (or relevant ones for your setup)
- [ ] GKE cluster running with 3 nodes
- [ ] All pods running and healthy
- [ ] Frontend accessible from external IP
- [ ] Data persistence test completed and verified
- [ ] Logs show no critical errors
- [ ] Storage properly configured and bound
- [ ] GitHub repository contains all manifests
- [ ] README.md has deployment instructions
- [ ] explanation.md has implementation details
- [ ] Live application URL documented
- [ ] All evidence organized and ready for submission
