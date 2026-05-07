#!/bin/bash
# Docker ACUITY environment setup for Radxa A7A (A733, NPU v3, ACUITY v2.0)
# Run in WSL: bash setup_docker.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCKER_ZIP="/mnt/c/Users/yoan3/vscode/docker_images_v2.0.x.zip"
WORK_DIR="$SCRIPT_DIR/docker_workspace"

echo "=== YOLOE Trash NPU - Docker Setup (A733, ACUITY v2.0) ==="

# Step 1: Extract
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
[ ! -f docker_images_v2.0.x.zip ] && cp "$DOCKER_ZIP" .
[ ! -d docker_images_v2.0.x ] && unzip -o docker_images_v2.0.x.zip
cd docker_images_v2.0.x
TAR_ZIP=$(ls ubuntu-npu_*.tar.zip | head -1)
[ ! -f "${TAR_ZIP%.zip}" ] && unzip -o "$TAR_ZIP"

# Step 2: Load Docker image
TAR_FILE=$(ls ubuntu-npu_*.tar | head -1)
if ! sudo docker images | grep -q "ubuntu-npu.*v2.0.10.1"; then
    sudo docker load -i "$TAR_FILE"
else
    echo "[SKIP] Image already loaded"
fi

# Step 3: Create container
CONTAINER_NAME="allwinner_v2.0.10.1"
if ! sudo docker ps -a | grep -q "$CONTAINER_NAME"; then
    sudo docker run --ipc=host -itd \
        -v "$SCRIPT_DIR:/workspace/yoloe_trash_npu" \
        --name "$CONTAINER_NAME" \
        ubuntu-npu:v2.0.10.1 /bin/bash
    echo "[OK] Container created: $CONTAINER_NAME"
else
    sudo docker start "$CONTAINER_NAME" 2>/dev/null
    echo "[SKIP] Container exists"
fi

# Step 4: Clone ai-sdk
sudo docker exec "$CONTAINER_NAME" bash -c "
[ ! -d /workspace/ai-sdk ] && cd /workspace && git clone https://github.com/ZIFENG278/ai-sdk.git
"
echo "[OK] Setup complete. Enter container: sudo docker exec -it $CONTAINER_NAME /bin/bash"
