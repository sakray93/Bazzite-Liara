#!/usr/bin/env bash

set -ouex pipefail

### SECTION 1: Install Core Packages and General Utilities

echo "--- Installing core packages and general utilities ---"

# Corrected dnf5 command: removed non-existent packages.
dnf5 install -y \
    git \
    python3 \
    alsa-utils \
    pulseaudio-utils \
    curl \
    wget \
    fastfetch \
    htop \
    vim-enhanced \
    kde-gtk-config \
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
    'qt6-*' \
    'qt5-*'

### SECTION 2: Android Emulation Support (Waydroid)

echo "--- Installing Waydroid for Android emulation support ---"

dnf5 install -y waydroid

mkdir -p /var/lib/waydroid/
cat <<EOF > /var/lib/waydroid/waydroid.cfg
[properties]
persist.waydroid.multi_windows = true
EOF

### SECTION 3: AMD Proprietary Driver Fallback & Performance Tweaks

echo "--- Installing AMD proprietary drivers fallback and performance tweaks ---"

if ! dnf5 list --installed amdgpu-pro &>/dev/null; then
    echo "AMD proprietary driver not installed; installing fallback open-source with performance tweaks..."
    dnf5 install -y mesa-dri-drivers mesa-vulkan-drivers vulkan-loader
fi

# Enable AMDGPU DC and power management optimizations
echo "options amdgpu dc=1 power_dpm_state=performance power_dpm_force_performance_level=high" > /etc/modprobe.d/amdgpu.conf

### SECTION 4: Vulkan SDK Setup

echo "--- Installing Vulkan SDK ---"

### SECTION 5: AI Tools Installation and Setup

echo "--- Installing AI tools for creators ---"

# Python virtualenv for AI tools
dnf5 install -y python3-pip python3-virtualenv

mkdir -p /opt/ai-tools
cd /opt/ai-tools

# Corrected virtualenv setup: chained commands to ensure pip runs inside the venv.
python3 -m virtualenv venv && \
source venv/bin/activate && \
pip install --upgrade pip && \
pip install diffusers transformers accelerate --quiet

# Install other AI tools (stable-diffusion-webui, etc.) - placeholder for actual install commands

deactivate

### SECTION 6: Create AI Tool Launcher Script and Desktop Entry

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
