#!/bin/bash
set -e

function docker_create_private_registry() {
    echo "$L docker_private_registry"

    echo "$L$L checking if the docker image for private registry exists...image name: $DOCKER_PVT_REGISTRY_IMAGE"
    # Check if the Docker image for private registry exists
    docker pull $DOCKER_PVT_REGISTRY_IMAGE

    echo "$L$L running container for private registry..."
    echo "docker run -d --restart=always -p $DOCKER_PORT:$DOCKER_PORT --name $DOCKER_PVT_REGISTRY_CONTAINER_NAME -v $DOCKER_VOLUME_PVT_REGISTRY_PATH:/var/lib/registry $DOCKER_PVT_REGISTRY_IMAGE"
    docker run -d --restart=always \
        -p $DOCKER_PORT:$DOCKER_PORT \
        --name $DOCKER_PVT_REGISTRY_CONTAINER_NAME \
        -v $DOCKER_VOLUME_PVT_REGISTRY_PATH:/var/lib/registry \
        $DOCKER_PVT_REGISTRY_IMAGE
}

function docker_add_k3s_images_to_private_registry() {
    # Loop through each line in the k3s-images.txt file
    while IFS= read -r line; do
        # Pull the image
        docker pull "$line"
        # Extract the image name without the repository and tag
        image_name=$(echo "$line" | awk -F/ '{print $NF}' | awk -F: '{print $1}')
        # Tag the image with the destination registry
        docker tag "$line" "$DOCKER_PVT_REGISTRY_HOST_PORT/$image_name"
        # Push the tagged image to the destination registry
        docker push "$DOCKER_PVT_REGISTRY_HOST_PORT/$image_name"
    done < "$ASSETS_FOLDER/k3s-images.txt" 
}

function step_1() {
    echo ""
    echo "________________________________________________________________________"
    echo "$L Step 1 start"
    docker_create_private_registry
    docker_add_k3s_images_to_private_registry
    echo "________________________________________________________________________"
    echo "$L Step 1 END"
    echo ""
}