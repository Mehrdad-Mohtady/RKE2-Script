# 🚀 RKE2 Airgap Installation Preparation Script

> **Automate the setup of RKE2 for offline (airgap) environments.**  
> Installs system dependencies, downloads all required binaries and container images, and places them in the correct directories as expected by the official RKE2 installer.

Perfect for secure, regulated, or bandwidth-constrained deployments.

---

## ✅ Features

- **System Prep**: Installs `curl`, `vim`, `sudo`, and `iptables` if missing.
- **Smart Downloads**: Skips files that already exist and are non-empty.
- **Correct Directory Structure**:
  - `/var/lib/rancher/rke2/agent/images/` — For auxiliary images (`rke2-images-core...`, `rke2-images-cilium...`). *Automatically discovered by RKE2 at runtime.*
  - `/root/rke2-artifacts/` — For core installation files (`rke2.linux-amd64.tar.gz`, `sha256sum-amd64.txt`, `install.sh`).
- **Ready for Airgap Install**: After running this script, install RKE2 completely offline using the official installer.
- **Clear Logging**: Shows exactly what was installed, skipped, or downloaded.

---

## 📦 Files Downloaded

### ➤ To `/var/lib/rancher/rke2/agent/images/` *(Auto-discovered by RKE2)*
- `rke2-images-core.linux-amd64.tar.zst`
- `rke2-images-cilium.linux-amd64.tar.zst`

### ➤ To `/root/rke2-artifacts/` *(Referenced explicitly during install)*
- `rke2-images.linux-amd64.tar.zst` — Main container image bundle.
- `rke2.linux-amd64.tar.gz` — RKE2 binary and systemd unit files.
- `sha256sum-amd64.txt` — Checksums for verifying integrity.
- `install.sh` — Official RKE2 installer script (made executable).

---

## ⚙️ Prerequisites

- **OS**: Linux (Ubuntu/Debian, RHEL/CentOS, etc.)
- **Architecture**: `linux-amd64` (x86_64)
- **User**: Must be run as **root** (uses `sudo` for package install and to write to `/var/lib/` and `/root/`).
- **Internet Access**: Required only during script execution to download files.
- **Disk Space**: Ensure you have sufficient space for container images (several GBs).

---

## 🚀 Quick Start

```bash
# 1. Download or create the script
curl -sfL -o prepare_rke2_airgap.sh https://raw.githubusercontent.com/yourusername/yourrepo/main/prepare_rke2_airgap.sh
# OR
vim prepare_rke2_airgap.sh  # Then paste the full script content

# 2. Make it executable
chmod +x prepare_rke2_airgap.sh

# 3. Run it as root
sudo ./prepare_rke2_airgap.sh