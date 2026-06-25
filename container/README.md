# tldr;
Install inkcut to your linux OS by running the `distrobox-assemble create` command below.  
The python environment is already built-out, inkcut is ready-to-run.  

# Overview
1. A github action builds an OCI image that contains [inkcut](https://github.com/inkcut/inkcut/tree/master) and a python environment to run it.  
2. The distrobox-create command downloads that image and integrates it with the host machine.  
  Once complete, inkcut is conveniently launchable from the OS like any other application.  

This approach is distribution agnostic, and is ideal for use on immutable OS's.  

## distrobox-assemble create
The paths and flags and apps-to-export are stored in a file;  
simply point the distrobox-assemble command to use the stored configuration.

```sh
distrobox-assemble create \
--name inkcutEnv \
--file https://raw.githubusercontent.com/cyril279/inkcut/refs/heads/master/container/distrobox.ini
```

[distrobox.ini:](distrobox.ini)  
```ini
[inkcutEnv]
name=inkcutEnv
image=ghcr.io/inkcut/inkcut:latest
home=$HOME/.local/share/distrobox/inkcutEnv
exported_apps=/opt/inkcut-env/share/applications/inkcut.desktop
exported_bins=/opt/inkcut-env/bin/inkcut
exported_bins_path="$HOME/.local/bin"
pull=true
replace=true
```

# todo:
Document the serial-permissions hurdles  
