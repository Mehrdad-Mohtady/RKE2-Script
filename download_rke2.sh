#!/usr/bin/env bash

# Define the target download directory for ALL files (including install.sh)
DOWNLOAD_DIR="/var/lib/rancher/rke2/agent/images"

echo "=== RKE2 Smart Downloader (Skip if exists) ==="
echo "All files will be saved to: $DOWNLOAD_DIR"
echo ""

# Check if directory exists
if [ -d "$DOWNLOAD_DIR" ]; then
    echo "✓ Directory already exists"
else
    echo "⚠ Directory does not exist - will create it"
    if mkdir -p "$DOWNLOAD_DIR" 2>/dev/null; then
        echo "✓ Successfully created directory: $DOWNLOAD_DIR"
    else
        echo "✗ ERROR: Cannot create directory $DOWNLOAD_DIR"
        echo "  This directory requires root privileges."
        echo "  Please run this script with sudo:"
        echo "  sudo ./download_rke2.sh"
        exit 1
    fi
fi

# Verify we have write permissions
if [ ! -w "$DOWNLOAD_DIR" ]; then
    echo "✗ ERROR: No write permission to $DOWNLOAD_DIR"
    echo "  Please run this script with sudo:"
    echo "  sudo ./download_rke2.sh"
    exit 1
fi

echo "✓ Write permission confirmed"
echo ""

# Define the base URL and version
VERSION="v1.33.4%2Brke2r1"
BASE_URL="https://github.com/rancher/rke2/releases/download/$VERSION"

# Function to check and download a file
download_if_missing() {
    local filename="$1"
    local filepath="$DOWNLOAD_DIR/$filename"
    local url="$2"
    
    echo "→ Checking: $filename"
    
    # Check if file exists and has content (size > 0)
    if [ -f "$filepath" ] && [ -s "$filepath" ]; then
        echo "✓ Skipping (already exists): $filename"
        display_file_size "$filepath"
        return 0
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
                return 0
            else
                echo "✗ File empty after download: $filename"
                return 1
            fi
        else
            echo "✗ FAILED to download: $filename"
            return 1
        fi
    fi
    echo "----------------------------------------"
}

# Function to display human-readable file size
display_file_size() {
    local filepath="$1"
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
}

echo "Checking existing files and downloading missing ones..."
echo "========================================"

downloaded_count=0
skipped_count=0

# Define files and URLs
files=(
    "rke2-images.linux-amd64.tar.zst|$BASE_URL/rke2-images.linux-amd64.tar.zst"
    "rke2.linux-amd64.tar.gz|$BASE_URL/rke2.linux-amd64.tar.gz"
    "sha256sum-amd64.txt|$BASE_URL/sha256sum-amd64.txt"
    "rke2-images-core.linux-amd64.tar.gz|$BASE_URL/rke2-images-core.linux-amd64.tar.gz"
    "rke2-images-cilium.linux-amd64.tar.gz|$BASE_URL/rke2-images-cilium.linux-amd64.tar.gz"
    "install.sh|https://get.rke2.io"
)

# Process each file
for file_entry in "${files[@]}"; do
    IFS='|' read -r filename url <<< "$file_entry"
    if download_if_missing "$filename" "$url"; then
        if [ -f "$DOWNLOAD_DIR/$filename" ] && [ -s "$DOWNLOAD_DIR/$filename" ]; then
            ((skipped_count++))
        else
            ((downloaded_count++))
        fi
    else
        echo "⚠ Error processing: $filename"
    fi
    echo "----------------------------------------"
done

echo ""
echo "========================================"
echo "Download process completed!"
echo ""

# Final summary
echo "=== Final Summary ==="
total_files=${#files[@]}
echo "Total files checked: $total_files"
echo "✓ Already present: $skipped_count"
echo "⬇ Newly downloaded: $downloaded_count"
echo ""

# List status of all files
echo "=== File Status ==="
for file_entry in "${files[@]}"; do
    IFS='|' read -r filename _ <<< "$file_entry"
    filepath="$DOWNLOAD_DIR/$filename"
    if [ -f "$filepath" ] && [ -s "$filepath" ]; then
        echo "✓ $filename"
    else
        echo "✗ $filename (missing or empty)"
    fi
done

# Display checksums if available
if [ -f "$DOWNLOAD_DIR/sha256sum-amd64.txt" ]; then
    echo ""
    echo "=== SHA256 Checksums ==="
    echo "========================================"
    cat "$DOWNLOAD_DIR/sha256sum-amd64.txt"
fi

echo ""
echo "=== Next Steps ==="
INSTALLER_PATH="$DOWNLOAD_DIR/install.sh"
if [ -f "$INSTALLER_PATH" ]; then
    echo "1. Install RKE2 with pre-downloaded images:"
    echo "   sudo INSTALL_RKE2_VERSION=\"v1.33.4+rke2r1\" $INSTALLER_PATH"
    echo ""
    echo "2. (Optional) Review installer:"
    echo "   less $INSTALLER_PATH"
    echo ""
    echo "💡 RKE2 will auto-detect and use the images in $DOWNLOAD_DIR"
else
    echo "⚠ install.sh not found — please run script again or download manually:"
    echo "   sudo curl -sfL https://get.rke2.io --output $DOWNLOAD_DIR/install.sh && sudo chmod +x $DOWNLOAD_DIR/install.sh"
fi