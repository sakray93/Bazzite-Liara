#!/usr/bin/env bash

set -ouex pipefail

### SECTION 1: Install Core Packages and General Utilities

echo "--- Installing core packages and general utilities ---"

# Removed the conflicting 'mesa-vdpau-drivers' package.
dnf5 install -y \
    git \
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
    'qt5-*' \
    mesa-va-drivers \
    breeze-gtk

### SECTION 2: System and Performance Tweaks

# --- Custom Plymouth Boot Splash ---
echo "--- Setting up custom boot splash theme ---"
dnf5 install -y plymouth-themes
plymouth-set-default-theme -R bgrt

# --- GPU Video Rendering Tweaks for Streaming ---
echo "--- Enabling GPU video rendering for online streams ---"
# Add Mesa VA-API and VDPAU drivers for hardware video acceleration.
# A .drirc file can be used to set global rendering options for Mesa.
# This helps applications like OBS Studio, browsers, and media players use the GPU.
# The user's AMD A4 APU should benefit greatly from this.
mkdir -p /etc/X11/xorg.conf.d
cat <<EOF > /etc/X11/xorg.conf.d/20-radeon.conf
Section "Device"
    Identifier  "AMDGPU"
    Driver      "amdgpu"
EndSection
EOF

# Note: The amount of dedicated VRAM for an AMD A4 APU is a BIOS/UEFI setting.
# It cannot be changed by this script. To increase it, you must enter your
# laptop's BIOS/UEFI settings and look for a setting like "UMA Frame Buffer Size"
# or "Shared Memory" in a menu like "Advanced" or "Graphics Configuration".
# The maximum is usually limited to 2GB.

# --- AMD Proprietary Driver Fallback & Performance Tweaks ---
echo "--- Installing AMD proprietary drivers fallback and performance tweaks ---"

if ! dnf5 list --installed amdgpu-pro &>/dev/null; then
    echo "AMD proprietary driver not installed; installing fallback open-source with performance tweaks..."
    dnf5 install -y mesa-dri-drivers mesa-vulkan-drivers vulkan-loader
fi

# Enable AMDGPU DC and power management optimizations
echo "options amdgpu dc=1 power_dpm_state=performance power_dpm_force_performance_level=high" > /etc/modprobe.d/amdgpu.conf

# --- ZRAM Configuration (Optional) ---
echo "--- Ensuring ZRAM is enabled ---"

# Install zram-generator if it's not already present
dnf5 install -y zram-generator

# Create a configuration file to enable ZRAM
cat <<EOF > /etc/systemd/zram-generator.conf
[zram0]
zram-size = min(ram/2, 4096)
EOF

### SECTION 3: Android Emulation Support (Waydroid)

echo "--- Installing Waydroid for Android emulation support ---"

dnf5 install -y waydroid

mkdir -p /var/lib/waydroid/
cat <<EOF > /var/lib/waydroid/waydroid.cfg
[properties]
persist.waydroid.multi_windows = true
EOF

### SECTION 4: Drawing Mode Setup

echo "--- Creating a 'Drawing Mode' launcher ---"

# Create a shell script to launch Krita in full screen
cat <<'EOF' > /usr/local/bin/launch-drawing-mode.sh
#!/usr/bin/env bash
# This script launches a drawing application (Krita) in a touch-friendly way.

# Switch to the Krita session
# For a simple full-screen app, just running Krita is often enough.
# Krita has a "canvas only" mode which can be activated with the 'Tab' key.
krita --fullscreen --nonscaling-mode
EOF

chmod +x /usr/local/bin/launch-drawing-mode.sh

mkdir -p /usr/share/applications

cat <<'EOF' > /usr/share/applications/drawing-mode.desktop
[Desktop Entry]
Name=Drawing Mode
Comment=Launch Krita for a touch-optimized drawing experience
Exec=/usr/local/bin/launch-drawing-mode.sh
Icon=applications-graphics
Terminal=false
Type=Application
Categories=Graphics;Utility;
EOF

echo "--- build.sh script finished ---"
