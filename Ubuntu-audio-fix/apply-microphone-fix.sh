#!/bin/bash
# Automation Script to Apply Dell Latitude 7430 Microphone Fix

echo "=== Starting Dell Latitude 7430 Audio Fix Installation ==="

# 1. Create PipeWire user-space drop-in directory
mkdir -p ~/.config/pipewire/pipewire-pulse.conf.d/

# 2. Write Quantum buffer size config (resolves crackling)
echo "-> Creating 99-quantum.conf..."
cat << 'EOF' > ~/.config/pipewire/pipewire-pulse.conf.d/99-quantum.conf
pulse.properties = {
    pulse.min.quantum = 512/48000
}
EOF

# 3. Write volume lock config (resolves auto-gain static noise)
echo "-> Creating 99-block-volume.conf..."
cat << 'EOF' > ~/.config/pipewire/pipewire-pulse.conf.d/99-block-volume.conf
pulse.rules = [
    {
        matches = [
            { client.name = "~.*" }
        ]
        actions = {
            quirks = [ block-source-volume ]
        }
    }
]
EOF

# 4. Create ALSA volume calibration script
echo "-> Creating alsa-mic-fix.sh..."
cat << 'EOF' > ~/.config/alsa-mic-fix.sh
#!/bin/bash
sleep 4
# Route capture to physical Internal Mic (numid 6 = 0)
amixer -c 0 cset numid=6 0
# Set optimal clean mixer levels
amixer -c 0 sset 'Internal Mic Boost' 1
amixer -c 0 sset 'Capture' 48
EOF
chmod +x ~/.config/alsa-mic-fix.sh

# 5. Create autostart launcher for GNOME login
echo "-> Creating autostart desktop launcher..."
mkdir -p ~/.config/autostart/
cat << 'EOF' > ~/.config/autostart/alsa-mic-fix.desktop
[Desktop Entry]
Type=Application
Exec=/home/biswarup-biswas/.config/alsa-mic-fix.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=ALSA Mic Fix
Comment=Resets microphone boost to 1 and capture volume to 48
EOF

# 6. Apply Kernel Driver Override (Requires root/sudo)
echo "=== Applying Kernel Driver Configuration ==="
echo "You will be prompted for your sudo password to modify /etc/modprobe.d/..."
sudo sh -c 'echo "options snd-intel-dspcfg dsp_driver=3" > /etc/modprobe.d/inteldsp.conf'
sudo sh -c 'echo "options snd-hda-intel model=dell-headset-multi" >> /etc/modprobe.d/inteldsp.conf'

echo "-> Updating initramfs boot images..."
sudo update-initramfs -u

echo "=== Done! ==="
echo "Audio configuration successfully applied."
echo "Please REBOOT your computer now to load the new drivers."
echo "============================================="
