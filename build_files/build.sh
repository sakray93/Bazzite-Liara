#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status,
# exit if a variable is used without being set,
# print commands and their arguments as they are executed,
# and ensure pipe failures are handled.
set -ouex pipefail

### SECTION 1: Install Core Packages and General Utilities

echo "--- Installing core packages and general utilities ---"

# Bazzite-KDE already includes KDE Plasma 6, latest Qt6, Steam, Wine, and Lutris.
# Explicit 'dnf5 install' for these is generally not needed and can cause conflicts.
# Bazzite handles their integration and optimization.

# AMD Stoney Ridge (AMDA4) graphics drivers are provided by the open-source
# 'mesa' packages and 'linux-firmware', which are included by default in Bazzite for AMD GPUs.
# No additional proprietary drivers are typically required for general gaming or desktop use.

# Install essential tools required for patch scripts, Waydroid, and any other utilities you desire.
# 'curl' is needed for downloading the kernel RPMs.
dnf5 install -y \
    git \
    python3 \
    alsa-utils \
    pulseaudio-utils \
    curl \
    # Add any other general utilities you want here, one per line.
    # Example:
    # neofetch \
    # htop \
    # vim-enhanced

### SECTION 2: Android Emulation Support (Waydroid)

echo "--- Installing Waydroid for Android emulation support ---"

# Waydroid is available in Fedora's official repositories.
# This will install Waydroid and its necessary dependencies.
dnf5 install -y waydroid

# After installation, Waydroid typically requires initialization.
# This is usually done by the user on first boot, but we can pre-configure it.
# Note: The actual Android image download happens on first run by the user.
# The following commands configure Waydroid to use the official images.
# The user will still need to run 'waydroid init' on the first boot.
echo "Setting Waydroid properties for multi-window and default images (user will still need to run 'waydroid init')..."
mkdir -p /var/lib/waydroid/
cat <<EOF > /var/lib/waydroid/waydroid.cfg
[properties]
persist.waydroid.multi_windows = true
EOF

### SECTION 3: Apply Chromebook Linux Audio Patches

echo "--- Applying Chromebook Linux Audio patches from WeirdTreeThing/chromebook-linux-audio ---"

AUDIO_REPO_DIR="/tmp/chromebook-linux-audio-repo"

# Clone the repository into a temporary directory
git clone https://github.com/WeirdTreeThing/chromebook-linux-audio.git "${AUDIO_REPO_DIR}"

# Make the setup script executable
chmod +x "${AUDIO_REPO_DIR}/setup-audio"

# Run the setup-audio script.
# This script handles its own dependencies and configurations for audio.
# We use '|| true' to allow the build to continue even if the script
# exits with a non-zero status for non-critical reasons (e.g., warnings).
echo "Executing setup-audio script..."
"${AUDIO_REPO_DIR}/setup-audio" || true

# Clean up the temporary audio repository
echo "Cleaning up temporary audio repository..."
rm -rf "${AUDIO_REPO_DIR}"

### SECTION 4: Apply Chromebook Keyboard Map Patches

echo "--- Applying Chromebook Keyboard Map patches from WeirdTreeThing/cros-keyboard-map ---"

KEYBOARD_REPO_BASE_URL="https://raw.githubusercontent.com/WeirdTreeThing/cros-keyboard-map/main"

# Download the udev rule file for keyboard mapping
echo "Downloading 90-cros-keyboard.rules..."
curl -sSL "${KEYBOARD_REPO_BASE_URL}/90-cros-keyboard.rules" -o /etc/udev/rules.d/90-cros-keyboard.rules

# Download the libinput keymap file
# The common location for custom libinput keymaps is /usr/share/libinput/
echo "Downloading cros-keyboard keymap..."
curl -sSL "${KEYBOARD_REPO_BASE_URL}/cros-keyboard" -o /usr/share/libinput/cros-keyboard

# Ensure correct permissions for the keymap file
chmod 644 /usr/share/libinput/cros-keyboard

# Reload udev rules and trigger udev to apply the new keyboard map rules
echo "Reloading udev rules and triggering udev..."
udevadm control --reload-rules
udevadm trigger

### SECTION 5: Custom Kernel Installation (AMD Stoney Ridge)

echo "--- Installing custom kernel for AMD Stoney Ridge (AMDA4) ---"

KERNEL_BASE_URL="https://chultrabook.sakamoto.pl/stoneyridge-kernel/fedora-6.14.4-300.fc42.x86_64"
KERNEL_VERSION="6.14.4-300.fc42.x86_64"
KERNEL_TEMP_DIR="/tmp/custom-kernel-rpms"

mkdir -p "${KERNEL_TEMP_DIR}"

# Download the specific kernel RPMs
echo "Downloading kernel RPMs from ${KERNEL_BASE_URL}..."
curl -sSL "${KERNEL_BASE_URL}/kernel-${KERNEL_VERSION}.rpm" -o "${KERNEL_TEMP_DIR}/kernel-${KERNEL_VERSION}.rpm"
curl -sSL "${KERNEL_BASE_URL}/kernel-core-${KERNEL_VERSION}.rpm" -o "${KERNEL_TEMP_DIR}/kernel-core-${KERNEL_VERSION}.rpm"
curl -sSL "${KERNEL_BASE_URL}/kernel-modules-${KERNEL_VERSION}.rpm" -o "${KERNEL_TEMP_DIR}/kernel-modules-${KERNEL_VERSION}.rpm"
curl -sSL "${KERNEL_BASE_URL}/kernel-modules-core-${KERNEL_VERSION}.rpm" -o "${KERNEL_TEMP_DIR}/kernel-modules-core-${KERNEL_VERSION}.rpm"

# Use rpm-ostree override replace to install the custom kernel.
# This command removes the existing kernel packages and replaces them with the downloaded ones.
echo "Overriding existing kernel with custom Stoney Ridge kernel..."
rpm-ostree override replace \
    --remove kernel \
    --remove kernel-core \
    --remove kernel-modules \
    --remove kernel-modules-core \
    "${KERNEL_TEMP_DIR}/kernel-${KERNEL_VERSION}.rpm" \
    "${KERNEL_TEMP_DIR}/kernel-core-${KERNEL_VERSION}.rpm" \
    "${KERNEL_TEMP_DIR}/kernel-modules-${KERNEL_VERSION}.rpm" \
    "${KERNEL_TEMP_DIR}/kernel-modules-core-${KERNEL_VERSION}.rpm"

# Clean up the temporary kernel RPMs
echo "Cleaning up temporary kernel RPMs..."
rm -rf "${KERNEL_TEMP_DIR}"

echo "--- build.sh script finished ---"

# The 'ostree container commit' command is handled by the Containerfile
# after this script completes successfully.
