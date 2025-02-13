#!/bin/bash

set -e  # Exit on error
set -o pipefail  # Catch pipeline errors

# Get the commit hash as the tag
TAG=$(git rev-parse --short HEAD)
NETWORK_NAME="network_$(git rev-parse --short HEAD || date +%s)"

echo "Building images with tag: $TAG"

# Create a temporary docker-compose file with the replaced network name
cp docker-compose.yml docker-compose.temp.yml
sed -i "s/\NETWORKS/$NETWORK_NAME/g" docker-compose.temp.yml
sed -i "s/\${TAG}/$TAG/g" docker-compose.temp.yml
chmod 644 docker-compose.temp.yml

echo "Starting services in $NETWORK_NAME network, with docker-compose..."
docker compose -f docker-compose.temp.yml up -d

# Wait for services to be healthy
echo -e "\n"
echo "Waiting for services to be ready..."
sleep 10  # Adjust sleep time if needed

# Run health checks
echo -e "\n"
echo "Checking application health..."
docker exec catalogue-catalogue-1  wget -qO-  http://localhost:8080/health | jq .
if [ $? -ne 0 ]; then
  echo "Health check failed"
  exit 1
fi

echo -e "\n"
echo "Checking catalogue ..."
docker exec catalogue-catalogue-1  wget -qO-  http://localhost:8080/catalogue | jq '.[0]' 
if [ $? -ne 0 ]; then
  echo "Catalogue check failed"
  exit 1
fi

echo -e "\n"
echo "Application is running successfully!"
