# Dell Latitude 7430 Microphone Repair Guide (Ubuntu)

If you reinstall Ubuntu and find that your microphone is noisy/static or silent, follow these steps to restore clear audio.

---

### Step 1: Force the Sound Open Firmware (SOF) Driver & Model Quirk
The default driver (`snd_hda_intel`) cannot detect the laptop's digital microphone array. Additionally, a "phantom jack" detection bug tricks the system into thinking a headset is plugged in, routing the mic to the empty headphone port.

1. Open your terminal (**Ctrl + Alt + T**).
2. Create or edit `/etc/modprobe.d/inteldsp.conf`:
   ```bash
   sudo nano /etc/modprobe.d/inteldsp.conf
   ```
3. Paste the following configuration lines:
   ```text
   options snd-intel-dspcfg dsp_driver=3
   options snd-hda-intel model=dell-headset-multi
   ```
4. Save the file (Press **Ctrl+O**, then **Enter**) and exit (Press **Ctrl+X**).
5. Update your system boot image:
   ```bash
   sudo update-initramfs -u
   ```
6. **Reboot your laptop.**

---

### Step 2: Prevent Audio Crackling (PipeWire Buffer)
By default, the PipeWire audio buffer is too small, causing crackling sounds for applications using PulseAudio translation layers.

1. Create the configuration directory:
   ```bash
   mkdir -p ~/.config/pipewire/pipewire-pulse.conf.d/
   ```
2. Create a new config file:
   ```bash
   nano ~/.config/pipewire/pipewire-pulse.conf.d/99-quantum.conf
   ```
3. Paste the following configuration:
   ```text
   pulse.properties = {
       pulse.min.quantum = 512/48000
   }
   ```

---

### Step 3: Block Applications from Altering Microphone Volume
Some applications (Google Meet, Zoom, Slack, Chrome) use Auto-Gain to boost the microphone volume to 100% (+60dB), bringing back loud static noise.

1. Create a new configuration file:
   ```bash
   nano ~/.config/pipewire/pipewire-pulse.conf.d/99-block-volume.conf
   ```
2. Paste the following configuration to lock app volume changes:
   ```text
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
   ```

---

### Step 4: Add Login Startup Script to Calibrate Volume Levels
To ensure the correct internal microphone channel is selected and gain levels are optimal upon logging in:

1. Create the startup script:
   ```bash
   mkdir -p ~/.config/autostart/
   nano ~/.config/alsa-mic-fix.sh
   ```
2. Paste the following script:
   ```bash
   #!/bin/bash
   sleep 4
   # Route capture to physical Internal Mic (numid 6 = 0)
   amixer -c 0 cset numid=6 0
   # Set optimal clean mixer levels
   amixer -c 0 sset 'Internal Mic Boost' 1
   amixer -c 0 sset 'Capture' 48
   ```
3. Make it executable:
   ```bash
   chmod +x ~/.config/alsa-mic-fix.sh
   ```
4. Create the autostart launcher:
   ```bash
   nano ~/.config/autostart/alsa-mic-fix.desktop
   ```
5. Paste the launcher settings:
   ```text
   [Desktop Entry]
   Type=Application
   Exec=/home/biswarup-biswas/.config/alsa-mic-fix.sh
   Hidden=false
   NoDisplay=false
   X-GNOME-Autostart-enabled=true
   Name=ALSA Mic Fix
   Comment=Resets microphone boost to 1 and capture volume to 48
   ```

---

### 🔄 Apply and Restart Services
After setting everything up, run this command to restart the audio server:
```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```
