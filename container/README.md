# tldr;
Install inkcut to your linux OS by running the `distrobox-assemble create` command below.  
The python environment is already built-out, inkcut is ready-to-run.  

# Overview
1. A github action builds an OCI image that contains [inkcut](https://github.com/inkcut/inkcut/tree/master) and a python environment to run it.  
2. The distrobox-create command downloads that image and integrates it with the host machine.  
3. The options used in the distrobox-create command make inkcut conveniently launchable from the OS like any other application.  

This approach is distribution agnostic, and is ideal for use on immutable OS's.  

## distrobox-assemble create
The paths and flags and apps-to-export are stored in a file;  
simply point the distrobox-assemble command to use the stored configuration.

```sh
distrobox-assemble create \
--name inkcutEnv \
--file https://raw.githubusercontent.com/cyril279/docker-inkcut/refs/heads/main/distrobox.ini
```

[distrobox.ini:](distrobox.ini)  
```ini
[inkcutEnv]
name=inkcutEnv
image=ghcr.io/cyril279/docker-inkcut:latest
home=$HOME/.local/share/distrobox/inkcutEnv
exported_apps=/opt/inkcut-env/share/applications/inkcut.desktop
exported_bins=/opt/inkcut-env/bin/inkcut
exported_bins_path="$HOME/.local/bin"
pull=true
replace=true
```

# todo:
Document the serial-permissions hurdles  

## Untested
```ini
[inkcutEnv]
name=inkcutEnv
image=ghcr.io/cyril279/docker-inkcut:latest
home=$HOME/.local/share/distrobox/inkcutEnv
exported_apps=/opt/inkcut-env/share/applications/inkcut.desktop
exported_bins=/opt/inkcut-env/bin/inkcut
exported_bins_path="$HOME/.local/bin"
pull=true
replace=true

# Map host devices (USB/Serial) and X11/Wayland sockets
volume="/dev:/dev"
volume="/tmp/.X11-unix:/tmp/.X11-unix"
volume="/var/run/cups/cups.sock:/var/run/cups/cups.sock"

# Enable privileged mode for full hardware access
additional_flags="--privileged"

# Optional: Pass display environment variable
# (Usually handled automatically, but explicit is safer for GUI apps)
# additional_flags="--env DISPLAY=$DISPLAY"
```

## security implications
(AI generated)  

Using `--privileged` and mapping `/dev:/dev` fundamentally **breaks the security isolation** that containers provide.  
While necessary for hardware-heavy applications like Inkcut, these configurations introduce significant risks:

### 1. Risks of the `--privileged` Flag

The `--privileged` flag grants the container **all capabilities** of the host kernel, effectively removing the security boundary between the container and the host.

*   **Container Escape**: A compromised application or malicious code inside the container can easily escape to the host system. It gains access to host kernel features, allowing it to load kernel modules, manipulate host processes, or access host memory.
*   **Root Equivalence**: In a rootful container (which you are likely using for hardware access), `root` inside the container is effectively `root` on the host. Any vulnerability in Inkcut or its dependencies could give an attacker full control over your machine.
*   **Namespace Bypass**: It disables restrictions on namespaces (PID, network, mount), allowing the container to see and interact with host processes and network interfaces directly.

### 2. Risks of Mapping `/dev:/dev`

Mapping the entire `/dev` directory exposes **every device** on your host to the container, not just the plotter.

*   **Raw Disk Access**: The container gains access to raw block devices (e.g., `/dev/sda`, `/dev/nvme0n1`). A malicious actor could wipe your host's hard drive, modify partition tables, or read sensitive data directly from the disk, bypassing filesystem permissions.
*   **Host Device Control**: Access to devices like `/dev/mem` or `/dev/kmem` (if present) could allow direct memory manipulation. Access to host network interfaces or TTYs could allow traffic interception or keylogging.
*   **Dynamic Device Risks**: If you plug in a new device (like a USB drive) later, the container immediately gains access to it without restarting.

### 3. Mitigation Strategies

If you must run Inkcut with these permissions, consider these steps to reduce risk:

1.  **Prefer Specific Device Mapping**: Instead of `-v /dev:/dev`, map **only** the specific device your plotter uses (e.g., `-v /dev/ttyUSB0:/dev/ttyUSB0`). This requires knowing the device path beforehand and may need `udev` rules to ensure the path is stable.
2.  **Avoid `--privileged` if Possible**: Try running with only the necessary capabilities (e.g., `--cap-add=SYS_RAWIO` or `--cap-add=SYS_ADMIN`) and specific device mappings. However, for complex hardware interaction, this is often difficult to configure correctly.
3.  **Use a Dedicated User**: Run the container as a non-root user inside the container if the application allows, though this may limit hardware access.
4.  **Isolate Data**: Do not mount sensitive host directories (like `~/.ssh`, `~/.gnupg`, or your entire home directory) into this specific container. Use the `--home` flag in Distrobox to create an isolated home directory for the container.
5.  **Trust the Application**: Only use this setup if you fully trust the Inkcut software and any plugins/scripts it might execute. Do not use this container for browsing the web or running untrusted code.

#### Summary of Trade-offs

| Configuration | Security Level | Hardware Access | Risk Profile |
| :--- | :--- | :--- | :--- |
| **Default Container** | High | None | Minimal |
| **Specific `--device`** | Medium-High | Limited (Specific) | Low (if configured correctly) |
| **`-v /dev:/dev`** | Low | High (All devices) | **High** (Raw disk access) |
| **`--privileged`** | **None** | Full | **Critical** (Full host compromise possible) |

For a plotter application like Inkcut on a personal desktop, the convenience often outweighs the risk **provided you trust the software**.  
However, be aware that you are effectively running Inkcut as a native application with root-like powers, not in a securely sandboxed environment.

