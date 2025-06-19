# HTTPBin K3d Cluster - Quick Start

Simple guide to deploy and test HTTPBin load balancing on a local k3d cluster.

## 🚀 Quick Setup

### 1. Create Cluster

```bash
# Create k3d cluster with port mapping
cd ../terraform
terraform init
terraform apply -auto-approve
```

### 2. Deploy HTTPBin

```bash
# Deploy and verify HTTPBin
chmod +x deploy.sh
./deploy.sh
```

### 3. Test Load Balancing

```bash
# Test ingress load balancing
chmod +x test-lb.sh
./test-lb.sh
```

## 🧪 What Each Script Does

### `deploy.sh`

- Deploys HTTPBin pods and service
- Waits for pods to be ready
- Tests both service and ingress connectivity
- Shows pod distribution across nodes

### `test-lb.sh`

- Makes 8 requests through ingress
- Shows different origin IPs = load balancing working
- Quick verification that traffic distributes across pods

## 🎯 Expected Results

**Successful Load Balancing:**

```bash
INGRESS:
Request 1: "origin": "10.42.2.0"
Request 2: "origin": "10.42.0.1" 
Request 3: "origin": "10.42.1.0"
Request 4: "origin": "10.42.2.0"
...
```

**Different origin IPs = Different pods handling requests!** ✅

## 🔧 Troubleshooting

**If ingress doesn't work:**

```bash
# Check Traefik is running
kubectl get pods -n kube-system | grep traefik

kubectl logs <traefik pod> -n kube-system
```

**If no load balancing:**

```bash
# Check pod count
kubectl get pods -l app=httpbin

# Scale if needed
kubectl scale deployment httpbin --replicas=3
```

## 🧹 Cleanup

```bash
# Remove everything
cd ../terraform
terraform destroy -auto-approve
```
