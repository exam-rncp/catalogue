#!/bin/bash

# IP address for API testing
ip="127.0.0.1"

# Color codes
function green() { echo -e "\e[32m$1\e[0m"; }
function red() { echo -e "\e[31m$1\e[0m"; }
function yellow() { echo -e "\e[33m$1\e[0m"; }

# Function to wait for the API to be available
function wait_or_fail() {
    local endpoint=$1
    local limit=${2:-20}
    while [[ $limit -gt 0 ]]; do
        curl -s --head "$endpoint" > /dev/null
        if [[ $? -eq 0 ]]; then
            return 0
        fi
        limit=$((limit - 1))
        sleep 1
    done

    red "Couldn't get the API running"
    exit 1
}

# Function to check and restart the container images
function check_and_run_containers() {
    local containers=("f3lin/catalogue-db" "f3lin/catalogue")

    # Loop through the containers and check if they are running
    for container in "${containers[@]}"; do
        if [[ $(docker ps -q -f "ancestor=$container") ]]; then
            yellow "Stopping running container: $container"
            docker stop $(docker ps -q -f "ancestor=$container")
        fi
    done

    # Check if MYSQL_ROOT_PASSWORD env var is present and return an error if not
    if [[ -z "$MYSQL_ROOT_PASSWORD" ]]; then
        red "Error: MYSQL_ROOT_PASSWORD environment variable is not set." >&2
        return 1
    fi
    
    yellow "Starting containers with MYSQL_ROOT_PASSWORD..."
    docker compose -f docker-compose.yml up -d

    # Small delay to allow containers to start
    sleep 5
}

# Call the function to check and run containers
check_and_run_containers

# Test the /catalogue endpoint for items and structure
function test_catalogue_has_item_id() {
    wait_or_fail "http://$ip:80/catalogue"
    local response=$(curl -s "http://$ip/catalogue")
    local item_id=$(echo "$response" | jq -r '.[0].id')

    if [[ -z "$item_id" ]]; then
        red "Catalogue does not have an item ID"
        return 1
    else
        green "Item ID exists: $item_id"
        return 0
    fi
}

function test_catalogue_has_image() {
    local endpoint="http://${ip}:80/catalogue"
    local exit_code=0

    # Test catalogue endpoint first
    yellow "Testing catalogue endpoint: $endpoint"
    wait_or_fail $endpoint
    local catalogue_response=$(curl -s -w "%{http_code}" "$endpoint")
    local http_code=${catalogue_response: -3}
    local catalogue_data=${catalogue_response:0:-3}

    if [[ "$http_code" != "200" ]]; then
        red "Error: Failed to fetch catalogue. HTTP Status: $http_code" >&2
        return 1
    fi

    # Validate JSON format
    if ! echo "$catalogue_data" | jq empty > /dev/null 2>&1; then
        red "Error: Invalid JSON response from catalogue" >&2
        return 1
    fi

    # Extract and test each image URL
    yellow "Validating images..."
    echo "$catalogue_data" | jq -r '.[].imageUrl[]' | while read -r imageUrl; do
        yellow "Checking image: $imageUrl"
        
        # Get response headers using curl
        local image_response=$(curl -s -D - -o /dev/null "http://${ip}${imageUrl}")
        
        # Parse the response
        local response_code=$(echo "$image_response" | grep -i "^HTTP/" | awk '{print $2}')
        local content_type=$(echo "$image_response" | grep -i "^Content-Type:" | awk '{print $2}')
        local content_length=$(echo "$image_response" | grep -i "^Content-Length:" | awk '{print $2}' | tr -d '\r')

        # Validate response code
        if [[ "$response_code" != "200" ]]; then
            red "Error: Failed to access $imageUrl. HTTP Status: $response_code" >&2
            exit_code=1
            continue
        fi

        # Validate content length
        if [[ -z "$content_length" ]] || [[ "$content_length" -le 0 ]]; then
            red "Error: Invalid content length for $imageUrl: $content_length" >&2
            exit_code=1
            continue
        fi

        # Validate content type (allowing for optional charset parameter)
        if [[ ! "$content_type" =~ ^image/(jpeg|jpg|png) ]]; then
            red "Error: Invalid content type for $imageUrl: $content_type" >&2
            exit_code=1
            continue
        fi

        green "✓ Image $imageUrl is valid (size: $content_length bytes)"
    done

    # Check if any errors occurred
    if [[ $exit_code -eq 0 ]]; then
        green "All images validated successfully"
    else
        red "Some images failed validation" >&2
    fi

    return $exit_code
}

# Test /catalogue/{id} for an item's details
function test_get_item_by_id() {
    local item_id=$1
    wait_or_fail "http://$ip:80/catalogue/$item_id"
    local response=$(curl -s "http://$ip/catalogue/$item_id")
    local id=$(echo "$response" | jq -r '.id')

    if [[ "$id" != "$item_id" ]]; then
        red "Expected item ID $item_id, got $id"
        return 1
    else
        green "Item with ID $item_id exists."
        return 0
    fi
}

# Test the /tags endpoint for tags
function test_catalogue_tags() {
    wait_or_fail "http://$ip:80/tags"
    local response=$(curl -s "http://$ip/tags")
    local tags=$(echo "$response" | jq -r '.tags[]' | paste -sd ", " -)

    if [[ -z "$tags" ]]; then
        red "No tags found in the catalogue"
        return 1
    else
        green "Tags found: $tags"
        return 0
    fi
}

# Test the /catalogue/size endpoint for catalogue size
function test_catalogue_size() {
    wait_or_fail "http://$ip:80/catalogue/size"
    local response=$(curl -s "http://$ip/catalogue/size")
    local size=$(echo "$response" | jq '.size')

    if [[ "$size" -gt 0 ]]; then
        green "Catalogue size: $size"
        return 0
    else
        red "Invalid catalogue size"
        return 1
    fi
}

# Run tests
test_catalogue_has_item_id
test_catalogue_has_image
test_catalogue_tags
test_catalogue_size
test_get_item_by_id "a0a4f044-b040-410d-8ead-4de0446aec7e"

# Clean up: bring down the Docker containers
echo "Cleaning up Docker containers..."
docker compose -f docker-compose.yml down