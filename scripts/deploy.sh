#!/bin/bash

# deploy.sh - Deploy HTTPBin to your k3d cluster

echo "🚀 Deploying HTTPBin to k3d cluster..."

# Apply the deployment
kubectl apply -f ./deployment.yaml

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/httpbin-secure -n httpbin-secure   

echo "✅ Deployment ready!"

# Verification commands
echo "🔍 Verifying deployment..."

echo "📊 Deployment status:"
kubectl get deployment httpbin-secure -n httpbin-secure   

echo "🏷️  Pod distribution across nodes:"
kubectl get pods -o wide -l app=httpbin-secure -n httpbin-secure   

echo "🌐 Service status:"
kubectl get service httpbin-secure-service -n httpbin-secure   

echo "🔗 Testing connectivity:"
kubectl port-forward service/httpbin-secure-service 8081:80 -n httpbin-secure &
PORT_FORWARD_PID=$!

# Wait a moment for port-forward to establish
sleep 3

echo "📡 Testing Service HTTP endpoints:"
curl -s -f http://localhost:8081/status/200 > /dev/null && echo "✅ Status endpoint works" || echo "❌ Status endpoint ERROR"
curl -s -f http://localhost:8081/get | jq '.url' > /dev/null 2>&1 && echo "✅ GET endpoint works" || echo "❌ GET endpoint ERROR"

sleep 3

echo "📡 Testing Ingress HTTP endpoints:"
curl -s -f http://localhost:8080/status/200 > /dev/null && echo "✅ Status endpoint works" || echo "❌ Status endpoint ERROR"
curl -s -f http://localhost:8080/get | jq '.url' > /dev/null 2>&1 && echo "✅ GET endpoint works" || echo "❌ GET endpoint ERROR"

echo "🏁 Testing completed!"

# Cleanup port-forward
kill $PORT_FORWARD_PID 2>/dev/null

echo "🎉 Deployment successful and verified!"
