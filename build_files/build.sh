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

# Install essential tools required for patch scripts and any other utilities you desire.
# Group all desired RPM packages into a single 'dnf5 install' command for efficiency.
dnf5 install -y \
    git \
    python3 \
    alsa-utils \
    pulseaudio-utils \
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
# These commands need to run in the Waydroid environment, but we can set up the properties here.
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

### SECTION 5: Custom Kernel Integration (Advanced - Requires Manual Steps)

echo "--- Custom Kernel Integration (Advanced - Placeholder) ---"
echo "WARNING: Integrating a custom kernel is complex and outside the scope of a simple build.sh script."
echo "It typically involves: "
echo "1. Downloading kernel source (e.g., from kernel.org or Fedora's kernel repository)."
echo "2. Configuring the kernel (e.g., 'make menuconfig' or copying an existing .config)."
echo "3. Compiling the kernel and its modules ('make -j$(nproc) rpm')."
echo "4. Using 'rpm-ostree override replace' to install your custom kernel RPMs."
echo "   Example: rpm-ostree override replace /path/to/your/kernel-core-*.rpm /path/to/your/kernel-modules-*.rpm"
echo "This process is highly specific to your kernel source and desired configuration."
echo "Please consult official rpm-ostree and Fedora kernel documentation for detailed steps."

# Example of where you might place kernel-related build steps if you had the RPMs ready:
# dnf5 install -y rpm-build # Install tools needed for RPM creation
# git clone <your_kernel_source_repo> /tmp/my-custom-kernel
# cd /tmp/my-custom-kernel
# cp /boot/config-$(uname -r) .config # Start with current kernel config (adjust as needed)
# make oldconfig # Update config for new kernel version
# make -j$(nproc) rpm # Build kernel RPMs
# rpm-ostree override replace /tmp/my-custom-kernel/rpmbuild/RPMS/x86_64/kernel-core-*.rpm \
#                               /tmp/my-custom-kernel/rpmbuild/RPMS/x86_64/kernel-modules-*.rpm
# rm -rf /tmp/my-custom-kernel # Clean up

echo "--- build.sh script finished ---"

# The 'ostree container commit' command is handled by the Containerfile
# after this script completes successfully.
