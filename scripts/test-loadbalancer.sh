#!/bin/bash

echo "🔄 HTTPBin Load Balancing Test"

echo "INGRESS:"
for i in {1..8}; do
  echo -n "Request $i: "
  curl -s -H "Host: httpbin.local" http://localhost:8080/get | grep '"origin"'
done
