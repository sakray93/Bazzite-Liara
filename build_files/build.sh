#!/usr/bin/env bash

set -ouex pipefail

###############################################################################
# SECTION 1: Install Core System Packages via rpm-ostree
###############################################################################

echo "--- Installing core system packages ---"

rpm-ostree install \
    git \
    python3 \
    python3-pip \
    python3-virtualenv \
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
    qt6-* \
    qt5-*

###############################################################################
# SECTION 2: Install GUI Apps via Flatpak
###############################################################################

echo "--- Installing creative and gaming apps via Flatpak ---"

flatpak install -y flathub \
    org.gimp.GIMP \
    org.kde.krita \
    org.inkscape.Inkscape \
    org.blender.Blender \
    com.valvesoftware.Steam \
    net.lutris.Lutris \
    com.visualstudio.code

echo "--- Installing Wine (Staging) via Flatpak ---"
echo 5 | flatpak install -y flathub org.winehq.Wine

###############################################################################
# SECTION 3: Waydroid Setup (Android Emulation)
###############################################################################

echo "--- Installing Waydroid ---"

rpm-ostree install waydroid

mkdir -p /var/lib/waydroid/
cat <<EOF > /var/lib/waydroid/waydroid.cfg
[properties]
persist.waydroid.multi_windows = true
EOF

###############################################################################
# SECTION 4: ZRAM Configuration (Optional)
###############################################################################

echo "--- Enabling ZRAM ---"

rpm-ostree install zram-generator

cat <<EOF > /etc/systemd/zram-generator.conf
[zram0]
zram-size = min(ram/2, 4096)
EOF

###############################################################################
# SECTION 5: AI Tools Setup (Virtualenv)
###############################################################################

echo "--- Installing AI tools in Python virtualenv ---"

mkdir -p /opt/ai-tools
cd /opt/ai-tools

python3 -m virtualenv venv && \
source venv/bin/activate && \
pip install --upgrade pip && \
pip install diffusers transformers accelerate --quiet

deactivate

###############################################################################
# SECTION 6: Drawing Mode Launcher
###############################################################################

echo "--- Creating Drawing Mode launcher ---"

cat <<'EOF' > /usr/local/bin/launch-drawing-mode.sh
#!/usr/bin/env bash
flatpak run org.kde.krita --fullscreen --nonscaling-mode
EOF

chmod +x /usr/local/bin/launch-drawing-mode.sh

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

###############################################################################
# SECTION 7: Stable Diffusion Launcher
###############################################################################

echo "--- Creating Stable Diffusion launcher ---"

cat <<'EOF' > /usr/local/bin/start-stable-diffusion.sh
#!/usr/bin/env bash
source /opt/ai-tools/venv/bin/activate
echo "Starting Stable Diffusion Web UI..."
# Replace with actual start command
python -m diffusers &
wait
EOF

chmod +x /usr/local/bin/start-stable-diffusion.sh

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

###############################################################################
# SECTION 8: Copilot Nativefier App with Custom Icon
###############################################################################

echo "--- Creating Copilot desktop app with Nativefier ---"

# Ensure Node.js and Nativefier are installed
sudo dnf install -y nodejs
npm install -g nativefier

# Create Copilot app
mkdir -p /opt/copilot-app
nativefier --name "Copilot" --single-instance --tray --width 1280 --height 800 "https://copilot.microsoft.com" /opt/copilot-app

# Download custom icon
mkdir -p /usr/share/icons/copilot
curl -L -o /usr/share/icons/copilot/copilot.png https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/Microsoft_Copilot_Icon.svg/1024px-Microsoft_Copilot_Icon.svg.png

# Create launcher
cat <<EOF > /usr/share/applications/copilot.desktop
[Desktop Entry]
Name=Copilot
Comment=Launch Microsoft Copilot AI Assistant
Exec=/opt/copilot-app/Copilot-linux-x64/Copilot
Icon=/usr/share/icons/copilot/copilot.png
Terminal=false
Type=Application
Categories=Utility;Development;AI;
EOF

###############################################################################
# SECTION 9: Post-install Script for Microsoft Edge
###############################################################################

echo "--- Creating post-install script for Microsoft Edge ---"

cat <<'EOF' > /usr/local/bin/install-edge.sh
#!/usr/bin/env bash
echo "Installing Microsoft Edge via Flatpak..."
flatpak install -y flathub com.microsoft.Edge
EOF

chmod +x /usr/local/bin/install-edge.sh

cat <<EOF > /usr/share/applications/install-edge.desktop
[Desktop Entry]
Name=Install Microsoft Edge
Comment=Run this once to install Edge browser
Exec=/usr/local/bin/install-edge.sh
Icon=web-browser
Terminal=true
Type=Application
Categories=Network;Utility;
EOF

echo "--- Custom tools setup completed ---"
