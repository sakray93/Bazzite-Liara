#!/usr/bin/env bash

set -ouex pipefail

### SECTION 1: Install Core Packages and General Utilities

echo "--- Installing core packages and general utilities ---"

dnf5 install -y \
    git \
    python3 \
    alsa-utils \
    pulseaudio-utils \
    curl \
    wget \
    neofetch \
    htop \
    vim-enhanced \
    kde-gtk-config \
    kde-settings-patch \
    mesa-vulkan-drivers \
    vulkan-loader \
    vulkan-tools \
    vulkan-validation-layers \
    libva-utils \
    ffmpeg \
    gimp \
    krita \
    inkscape \
    blender \
    steam \
    lutris \
    wine \
    wayland-protocols \
    qt6-* \
    qt5-* 

### SECTION 2: Android Emulation Support (Waydroid)

echo "--- Installing Waydroid for Android emulation support ---"

dnf5 install -y waydroid

mkdir -p /var/lib/waydroid/
cat <<EOF > /var/lib/waydroid/waydroid.cfg
[properties]
persist.waydroid.multi_windows = true
EOF

### SECTION 3: Chromebook Linux Audio Patches

echo "--- Applying Chromebook Linux Audio patches ---"

AUDIO_REPO_DIR="/tmp/chromebook-linux-audio-repo"
git clone https://github.com/WeirdTreeThing/chromebook-linux-audio.git "${AUDIO_REPO_DIR}"
chmod +x "${AUDIO_REPO_DIR}/setup-audio"
"${AUDIO_REPO_DIR}/setup-audio" || true
rm -rf "${AUDIO_REPO_DIR}"

### SECTION 4: Chromebook Keyboard Map Patches

echo "--- Applying Chromebook Keyboard Map patches ---"

KEYBOARD_REPO_BASE_URL="https://raw.githubusercontent.com/WeirdTreeThing/cros-keyboard-map/main"
curl -sSL "${KEYBOARD_REPO_BASE_URL}/90-cros-keyboard.rules" -o /etc/udev/rules.d/90-cros-keyboard.rules
curl -sSL "${KEYBOARD_REPO_BASE_URL}/cros-keyboard" -o /usr/share/libinput/cros-keyboard
chmod 644 /usr/share/libinput/cros-keyboard
udevadm control --reload-rules
udevadm trigger

### SECTION 5: Custom Kernel Installation (AMD Stoney Ridge)

echo "--- Installing custom kernel for AMD Stoney Ridge (AMDA4) ---"

KERNEL_BASE_URL="https://chultrabook.sakamoto.pl/stoneyridge-kernel/fedora-6.14.4-300.fc42.x86_64"
KERNEL_VERSION="6.14.4-300.fc42.x86_64"
KERNEL_TEMP_DIR="/tmp/custom-kernel-rpms"

mkdir -p "${KERNEL_TEMP_DIR}"
curl -sSL "${KERNEL_BASE_URL}/kernel-${KERNEL_VERSION}.rpm" -o "${KERNEL_TEMP_DIR}/kernel-${KERNEL_VERSION}.rpm"
curl -sSL "${KERNEL_BASE_URL}/kernel-core-${KERNEL_VERSION}.rpm" -o "${KERNEL_TEMP_DIR}/kernel-core-${KERNEL_VERSION}.rpm"
curl -sSL "${KERNEL_BASE_URL}/kernel-modules-${KERNEL_VERSION}.rpm" -o "${KERNEL_TEMP_DIR}/kernel-modules-${KERNEL_VERSION}.rpm"
curl -sSL "${KERNEL_BASE_URL}/kernel-modules-core-${KERNEL_VERSION}.rpm" -o "${KERNEL_TEMP_DIR}/kernel-modules-core-${KERNEL_VERSION}.rpm"

rpm-ostree override replace \
    --remove kernel \
    --remove kernel-core \
    --remove kernel-modules \
    --remove kernel-modules-core \
    "${KERNEL_TEMP_DIR}/kernel-${KERNEL_VERSION}.rpm" \
    "${KERNEL_TEMP_DIR}/kernel-core-${KERNEL_VERSION}.rpm" \
    "${KERNEL_TEMP_DIR}/kernel-modules-${KERNEL_VERSION}.rpm" \
    "${KERNEL_TEMP_DIR}/kernel-modules-core-${KERNEL_VERSION}.rpm"

rm -rf "${KERNEL_TEMP_DIR}"

### SECTION 6: AMD Proprietary Driver Fallback & Performance Tweaks

echo "--- Installing AMD proprietary drivers fallback and performance tweaks ---"

if ! dnf5 list --installed amdgpu-pro &>/dev/null; then
    echo "AMD proprietary driver not installed; installing fallback open-source with performance tweaks..."
    dnf5 install -y mesa-dri-drivers mesa-vulkan-drivers vulkan-loader
fi

# Enable AMDGPU DC and power management optimizations
echo "options amdgpu dc=1 power_dpm_state=performance power_dpm_force_performance_level=high" > /etc/modprobe.d/amdgpu.conf

### SECTION 7: Vulkan SDK Setup

echo "--- Installing Vulkan SDK ---"

dnf5 install -y vulkan-sdk

### SECTION 8: AI Tools Installation and Setup

echo "--- Installing AI tools for creators ---"

# Python virtualenv for AI tools
dnf5 install -y python3-pip python3-virtualenv

mkdir -p /opt/ai-tools
cd /opt/ai-tools

# Setup Stable Diffusion Web UI environment (minimal)
python3 -m virtualenv venv
source venv/bin/activate
pip install --upgrade pip
pip install diffusers transformers accelerate --quiet

# Install other AI tools (stable-diffusion-webui, etc.) - placeholder for actual install commands

deactivate

### SECTION 9: Create AI Tool Launcher Script and Desktop Entry

echo "--- Creating AI tool launcher script and desktop shortcut ---"

cat <<'EOF' > /usr/local/bin/start-stable-diffusion.sh
#!/usr/bin/env bash
source /opt/ai-tools/venv/bin/activate
# Start your AI tool web UI here; example placeholder:
echo "Starting Stable Diffusion Web UI..."
# Replace with actual start command
python -m diffusers &

# Keep script running
wait
EOF

chmod +x /usr/local/bin/start-stable-diffusion.sh

mkdir -p /usr/share/applications

cat <<'EOF' > /usr/share/applications/stable-diffusion.desktop
[Desktop Entry]
Name=Stable Diffusion AI
Comment=Launch Stable Diffusion Web UI for AI image generation
Exec=/usr/local/bin/start-stable-diffusion.sh
Icon=applications-graphics
Terminal=false
Type=Application
Categories=Graphics;Utility;Development;
EOF

echo "--- build.sh script finished ---"
