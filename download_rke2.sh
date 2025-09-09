#!/usr/bin/env bash

echo "=== Stage 0: Checking for required system packages ==="
REQUIRED_PKGS=("curl" "vim" "sudo" "iptables")
MISSING_PKGS=()

for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! command -v "$pkg" &> /dev/null; then
        echo "⚠ $pkg is not installed"
        MISSING_PKGS+=("$pkg")
    else
        echo "✓ $pkg is already installed"
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo ""
    echo "=== Stage 1: Installing missing system dependencies ==="
    apt update -y
    apt install -y "${MISSING_PKGS[@]}"
    
    if [ $? -ne 0 ]; then
        echo "✗ Failed to install system packages. Are you running as root?"
        exit 1
    fi
    echo "✓ All required packages installed: ${MISSING_PKGS[*]}"
else
    echo "✓ All required packages already installed"
fi
echo ""

# ====================================================================
# Define paths and version
VERSION="v1.33.1%2Brke2r1"
BASE_URL="https://github.com/rancher/rke2/releases/download/$VERSION"

# Directory for core/cilium images (used by RKE2 agent automatically)
IMAGE_DIR="/var/lib/rancher/rke2/agent/images"
# Directory for main installer, binary, and checksum
ARTIFACT_DIR="/root/rke2-artifacts"

echo "=== Stage 2: Creating Directories ==="
mkdir -p "$IMAGE_DIR" "$ARTIFACT_DIR"
echo "✓ Created: $IMAGE_DIR"
echo "✓ Created: $ARTIFACT_DIR"
echo ""

# Verify write permissions
for dir in "$IMAGE_DIR" "$ARTIFACT_DIR"; do
    if [ ! -w "$dir" ]; then
        echo "✗ ERROR: No write permission to $dir"
        echo "Please run this script as root."
        exit 1
    fi
done
echo "✓ Write permissions confirmed for all directories"
echo ""

# ====================================================================
# Function to download file if missing
download_if_missing() {
    local filename="$1"
    local filepath="$2"
    local url="$3"
    
    echo "→ Checking: $filename"
    echo "  Path: $filepath"
    
    if [ -f "$filepath" ] && [ -s "$filepath" ]; then
        echo "✓ Skipping (already exists): $filename"
        display_file_size "$filepath"
    else
        echo "⬇ Downloading: $filename"
        if curl -L --progress-bar -o "$filepath" "$url"; then
            if [ -f "$filepath" ] && [ -s "$filepath" ]; then
                echo "✓ Successfully downloaded: $filename"
                display_file_size "$filepath"
                
                # Special case: make install.sh executable
                if [ "$filename" = "install.sh" ]; then
                    chmod +x "$filepath"
                    echo "→ Made executable: chmod +x $filepath"
                fi
            else
                echo "✗ File empty after download: $filename"
            fi
        else
            echo "✗ FAILED to download: $filename"
        fi
    fi
    echo "----------------------------------------"
}

# Function to display human-readable file size
display_file_size() {
    local filepath="$1"
    if [ -f "$filepath" ]; then
        size=$(stat -c%s "$filepath" 2>/dev/null || stat -f%z "$filepath" 2>/dev/null)
        if [ -n "$size" ]; then
            if [ "$size" -gt 1048576 ]; then
                human_size=$(printf "%.2f MB" $(echo "$size/1048576" | bc -l 2>/dev/null || echo 0))
            elif [ "$size" -gt 1024 ]; then
                human_size=$(printf "%.2f KB" $(echo "$size/1024" | bc -l 2>/dev/null || echo 0))
            else
                human_size="${size} B"
            fi
            echo "  File size: $human_size"
        fi
    fi
}

# ====================================================================
echo "=== Stage 3: Downloading Files to /var/lib/rancher/rke2/agent/images/ ==="

# Files to go into IMAGE_DIR
download_if_missing \
    "rke2-images-core.linux-amd64.tar.zst" \
    "$IMAGE_DIR/rke2-images-core.linux-amd64.tar.zst" \
    "$BASE_URL/rke2-images-core.linux-amd64.tar.zst"

download_if_missing \
    "rke2-images-cilium.linux-amd64.tar.zst" \
    "$IMAGE_DIR/rke2-images-cilium.linux-amd64.tar.zst" \
    "$BASE_URL/rke2-images-cilium.linux-amd64.tar.zst"

echo ""
echo "=== Stage 4: Downloading Files to /root/rke2-artifacts/ ==="

# Files to go into ARTIFACT_DIR
download_if_missing \
    "rke2-images.linux-amd64.tar.zst" \
    "$ARTIFACT_DIR/rke2-images.linux-amd64.tar.zst" \
    "$BASE_URL/rke2-images.linux-amd64.tar.zst"

download_if_missing \
    "rke2.linux-amd64.tar.gz" \
    "$ARTIFACT_DIR/rke2.linux-amd64.tar.gz" \
    "$BASE_URL/rke2.linux-amd64.tar.gz"

download_if_missing \
    "sha256sum-amd64.txt" \
    "$ARTIFACT_DIR/sha256sum-amd64.txt" \
    "$BASE_URL/sha256sum-amd64.txt"

download_if_missing \
    "install.sh" \
    "$ARTIFACT_DIR/install.sh" \
    "https://get.rke2.io"

# ====================================================================
echo ""
echo "========================================"
echo "✅ All downloads completed successfully!"
echo ""

# Final summary
echo "=== Summary ==="
echo "System packages: curl, vim, sudo, iptables → Verified/Installed"
echo ""
echo "📁 /var/lib/rancher/rke2/agent/images/"
echo "   • rke2-images-core.linux-amd64.tar.zst"
echo "   • rke2-images-cilium.linux-amd64.tar.zst"
echo ""
echo "📁 /root/rke2-artifacts/"
echo "   • rke2-images.linux-amd64.tar.zst"
echo "   • rke2.linux-amd64.tar.gz"
echo "   • sha256sum-amd64.txt"
echo "   • install.sh (executable)"
echo ""

# Verify file statuses
echo "=== File Status Check ==="

echo "→ Checking /var/lib/rancher/rke2/agent/images/ :"
for file in "rke2-images-core.linux-amd64.tar.zst" "rke2-images-cilium.linux-amd64.tar.zst"; do
    if [ -f "$IMAGE_DIR/$file" ] && [ -s "$IMAGE_DIR/$file" ]; then
        echo "✓ $file"
    else
        echo "✗ $file"
    fi
done

echo ""
echo "→ Checking /root/rke2-artifacts/ :"
for file in "rke2-images.linux-amd64.tar.zst" "rke2.linux-amd64.tar.gz" "sha256sum-amd64.txt" "install.sh"; do
    if [ -f "$ARTIFACT_DIR/$file" ] && [ -s "$ARTIFACT_DIR/$file" ]; then
        echo "✓ $file"
    else
        echo "✗ $file"
    fi
done

# Display checksums if available
if [ -f "$ARTIFACT_DIR/sha256sum-amd64.txt" ]; then
    echo ""
    echo "=== SHA256 Checksums ==="
    echo "========================================"
    cat "$ARTIFACT_DIR/sha256sum-amd64.txt"
fi

echo ""
echo "=== Next Steps ==="
echo "1. Install RKE2 using:"
echo "   cd /root/rke2-artifacts/"
echo "   sudo INSTALL_RKE2_VERSION=\"v1.33.1+rke2r1\" INSTALL_RKE2_ARTIFACT_PATH=\"/root/rke2-artifacts\" ./install.sh"
echo ""
echo "💡 RKE2 will automatically detect and use:"
echo "   - Core/Cilium images from: $IMAGE_DIR"
echo "   - Binary & checksum from: $ARTIFACT_DIR"