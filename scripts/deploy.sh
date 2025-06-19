#!/bin/bash

# deploy.sh - Deploy HTTPBin to your k3d cluster

echo "🚀 Deploying HTTPBin to k3d cluster..."

# Apply the deployment
kubectl apply -f ../deployment.yaml

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/httpbin

echo "✅ Deployment ready!"

# Verification commands
echo "🔍 Verifying deployment..."

echo "📊 Deployment status:"
kubectl get deployment httpbin

echo "🏷️  Pod distribution across nodes:"
kubectl get pods -o wide -l app=httpbin

echo "🌐 Service status:"
kubectl get service httpbin-service

echo "🔗 Testing connectivity:"
kubectl port-forward service/httpbin-service 8081:80 &
PORT_FORWARD_PID=$!

# Wait a moment for port-forward to establish
sleep 3

echo "📡 Testing Service HTTP endpoints:"
curl -s http://localhost:8081/status/200 && echo "✅ Status endpoint works"
curl -s http://localhost:8081/get | jq '.url' && echo "✅ GET endpoint works"

sleep 3

echo "📡 Testing Ingress HTTP endpoints:"
curl -s http://localhost:8080/status/200 && echo "✅ Status endpoint works"
curl -s http://localhost:8080/get | jq '.url' && echo "✅ GET endpoint works"

# Cleanup port-forward
kill $PORT_FORWARD_PID 2>/dev/null

echo "🎉 Deployment successful and verified!"
