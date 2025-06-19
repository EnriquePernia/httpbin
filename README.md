# HTTPBin K3d Cluster with Terraform

A complete development setup for testing Kubernetes networking, load balancing, and ingress using HTTPBin on a local k3d cluster managed by Terraform.

## 🎯 Project Overview

This project demonstrates:

- **Container orchestration** with Kubernetes (k3d)
- **Infrastructure as Code** with Terraform
- **Load balancing** across multiple pods
- **Ingress routing** with Traefik
- **Service networking** patterns
- **Production-like** local development environment

## 📋 Prerequisites

- **Docker** - Container runtime
- **k3d** - Lightweight Kubernetes distribution
- **kubectl** - Kubernetes CLI
- **Terraform** - Infrastructure as Code tool
- **curl** - HTTP client for testing

### Installation Commands

```bash
# Install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip && sudo mv terraform /usr/local/bin/
```

## 🏗️ Architecture

```md
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Your Machine  │    │   k3d Cluster   │    │   HTTPBin Pods  │
│                 │    │                 │    │                 │
│ localhost:8080  ├────┤ Traefik Ingress ├────┤ Pod 1: 10.x.x.1 │
│ (with Host hdr) │    │                 │    │ Pod 2: 10.x.x.2 │
│                 │    │                 │    │ Pod 3: 10.x.x.3 │
│ localhost:8081  ├────┤ HTTPBin Service ├────┤                 │
│ (port-forward)  │    │ (ClusterIP)     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Components

- **k3d Cluster**: 1 server + 2 agent nodes
- **Traefik**: Ingress controller (pre-installed with k3d)
- **HTTPBin**: Test application with 3 replicas
- **Port Mapping**: localhost:8080 → cluster:80, localhost:8443 → cluster:443

## 🔧 Configuration

### Cluster Configuration

```hcl
# Terraform configuration (main.tf)
resource "k3d_cluster" "sample_cluster" {
  name          = "playson"
  servers_count = 1
  agents_count  = 2
  
  # Port mapping for external access
  ports {
    host_port      = 8080
    container_port = 80
    node_filters   = ["loadbalancer"]
  }
}
```

## 🏗️ Cluster Architecture

**K3d cluster with 4 nodes total:**

- **1 Control Plane** (`k3d-playson-server-0`) - manages cluster operations
- **3 Worker Nodes** - run application workloads:

- `k3d-playson-agent-0`
- `k3d-playson-agent-1`
- `playson-node-1-0`

**Network Configuration:**

- **API Server:** `localhost:6445` (kubectl access)
- **Load Balancer:** `localhost:8080` → Traefik → HTTPBin pods
- **Pod Distribution:** 3 HTTPBin replicas spread across all worker nodes for high availability

**Load Balancing:** Traefik distributes requests in round-robin fashion across the 3 pods, ensuring even traffic distribution and fault tolerance.

### HTTPBin Deployment

- **Replicas**: 3 pods for load balancing demonstration
- **Resources**: 64Mi memory, 50m CPU per pod
- **Anti-affinity**: Pods spread across different nodes
- **Health checks**: Liveness, startup and readiness probes

### Ingress Configuration

- **Path**: All paths (`/`)

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/EnriquePernia/httpbin.git
cd httpbin-k3d-cluster
```

### 2. Deploy Infrastructure

```bash
# Review plan before applying
terraform -chdir=terraform init
terraform -chdir=terraform plan -out=tfplan
terraform -chdir=terraform show tfplan  # Review what will be created
terraform -chdir=terraform apply tfplan  # Apply reviewed plan
# Verify cluster
kubectl get nodes
```

### 3. Deploy HTTPBin Application

```bash
# Deploy HTTPBin pods and service
chmod +x ./scripts/deploy.sh
./scripts/deploy.sh
```

- Deploys HTTPBin pods and service
- Waits for pods to be ready
- Tests both service and ingress connectivity
- Shows pod distribution across nodes

### 4. Test Ingress

```bash
# Test ingress load balancing
chmod +x ./scripts/test-loadbalancer.sh
./scripts/test-loadbalancer.sh
```

- Makes 8 requests through ingress
- Shows different origin IPs = load balancing working
- Quick verification that traffic distributes across pods

#### 🎯 Expected Results

**Successful Load Balancing:**

```bash
INGRESS:
Request 1: "origin": "10.42.2.0"
Request 2: "origin": "10.42.0.1" 
Request 3: "origin": "10.42.1.0"
Request 4: "origin": "10.42.2.0"
...
```

### Traffic Flow

localhost:8080 → Traefik → HTTPBin Service → Gateway Routing

**Different origin IPs = Different pods handling requests!** ✅

Keep in mind that what you are seeing is the **gateway IP** so if adding more nodes, the number of IPs could not match the nodes count.

### Gateway to Node Mapping

**Current Setup (3 nodes):**

- Gateway 10.42.0.1 → Pod A (agent-0)
- Gateway 10.42.1.0 → Pod B (agent-1)  
- Gateway 10.42.2.0 → Pod C (node-1-0)

**Setup (4 nodes):**

- Gateway 10.42.0.1 → Pod A (agent-0)
- Gateway 10.42.1.0 → Pod B (agent-1)
- Gateway 10.42.2.0 → Pod C (node-1-0) AND Pod D (node-2-0)

### Available HTTPBin Endpoints

| Endpoint | Description |
|----------|-------------|
| `/get` | GET request data |
| `/post` | POST request data |
| `/status/{code}` | Return status code |
| `/json` | Return JSON |
| `/headers` | Return headers |
| `/ip` | Return client IP |
| `/uuid` | Return random UUID |

## 🔍 Load Balancing Verification

### Understanding Load Distribution

1. **Service Level**: Kubernetes random algorithm distributes across pods
2. **Ingress Level**: Traefik load balances before reaching service
3. **Node Level**: Pod anti-affinity spreads across cluster nodes

### Monitoring Distribution

```bash
# Real-time log monitoring
kubectl logs -f -l app=httpbin-secure --prefix=true -n httpbin-secure

# Watch resource usage
watch kubectl top pods -l app=httpbin-secure -n httpbin-secure

# Monitor endpoints
watch kubectl get endpoints httpbin-secure-service -n httpbin-secure
```

## 🚨 Troubleshooting

### Common Issues

**Ingress not responding:**

```bash
# Check if ports are mapped
k3d cluster list playson

# Verify Traefik is running
kubectl get pods -n kube-system | grep traefik

# Test with port-forward as fallback
kubectl port-forward -n kube-system svc/traefik 8082:80
```

**Pods not starting:**

```bash
# Check pod status
kubectl describe pods -l app=httpbin-secure -n httpbin-secure

# View events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check resource usage
kubectl top nodes
```

**Load balancing not working:**

```bash
# Verify service endpoints
kubectl get endpoints httpbin-secure-service -n httpbin-secure

# Check service configuration
kubectl describe svc httpbin-secure-service -n httpbin-secure
```

## 🧹 Cleanup

```bash
# Destroy cluster and resources
terraform -chdir=terraform destroy -auto-approve

# Destroy only resources
kubectl delete -f deployment.yaml
```

## Security

Essential Security:

✅ Custom Namespace (httpbin-secure)

What: Separate namespace instead of default
Why: Isolates resources, enables namespace-level policies
Benefit: Apps can't interfere with each other

✅ Resource Quotas

What: Limits total CPU/memory in namespace (1 CPU, 1Gi RAM)
Why: Prevents one app from consuming all cluster resources
Benefit: Protects against resource exhaustion attacks

✅ Network Policy

What: Firewall rules controlling pod traffic (only port 80 from Traefik)
Why: Default Kubernetes allows all pod-to-pod communication
Benefit: Blocks unauthorized network access

✅ Service Account

What: Custom identity for pods instead of default
Why: Default service account has unnecessary permissions
Benefit: Principle of least privilege

✅ Non-root User (UID 1000)

What: Container runs as user 1000, not root (UID 0)
Why: Root can escape containers more easily
Benefit: Limits damage if container is compromised

✅ Dropped Capabilities (ALL)

What: Removes Linux capabilities like network admin, file owner changes
Why: Containers inherit some root-like powers by default
Benefit: Prevents privilege escalation within container

✅ No Privilege Escalation

What: allowPrivilegeEscalation: false
Why: Prevents gaining more privileges during runtime
Benefit: Stops attackers from becoming root

✅ Resource Limits (CPU/Memory)

What: Max 100m CPU, 128Mi RAM per container
Why: Prevents resource exhaustion and DoS attacks
Benefit: Ensures fair resource sharing and stability

## Load Balancing

**Current k3d Limitation:**

- Service uses **random load balancing** (iptables mode)
- Traefik routes to service, not individual pods
- Uneven distribution possible with low traffic

**EKS ALB Solution:**

- **True round-robin** load balancing directly to pod IPs
- Advanced health checks and SSL termination
- Production-grade reliability and performance
`

## 🎯 Benefits Achieved

### Performance Comparison

| Metric | k3d (Random) | EKS ALB (Round-Robin) |
|--------|--------------|----------------------|
| **Distribution Variance** | ±15% | ±3% |
| **Predictability** | Low | High |
| **Health Checks** | Basic | Advanced |
| **SSL Termination** | Manual | Automatic |
| **Scaling** | Manual | Automatic |
| **Production Ready** | No | Yes |

### Traffic Flow Improvement

```bash
# k3d Flow:
Request → Traefik → Service (random) → Pod
# Issues: Double load balancing, uneven distribution

# EKS ALB Flow:  
Request → ALB (round-robin) → Pod IP directly
# Benefits: Single LB, perfect distribution, enterprise features
````
