# NixOS Configuration - ThinkPad P14s Gen 5

Production NixOS configuration for research and development workstation.

## 🖥️ Hardware Specifications

| Component | Details |
|-----------|---------|
| **Model** | Lenovo ThinkPad P14s Gen 5 (21G2002CUS) |
| **CPU** | Intel Core Ultra 7 155H (Meteor Lake, 16C/22T) |
| **iGPU** | Intel Arc Graphics (MTL) |
| **dGPU** | NVIDIA RTX 500 Ada Generation Laptop GPU (4GB) |
| **RAM** | 64GB DDR5 |
| **Storage** | 1TB NVMe SSD (Micron) |
| **Display** | 14" 1920x1080 @ 100Hz |

## 🎯 Design Goals

- **Battery Life**: 6+ hours of productivity work
- **Hybrid Graphics**: Intel Arc for efficiency, NVIDIA for compute tasks
- **Research Ready**: Computer vision and robotics development (PyTorch, CUDA)
- **Declarative**: Fully reproducible system configuration
- **Optimized**: SSD, memory, and power management tuning

## ✨ Key Features

### Graphics Configuration
- **PRIME Offload Mode**: NVIDIA GPU sleeps when idle, wakes on-demand
- **Intel Arc Default**: Battery-efficient integrated graphics for daily tasks
- **Hardware Acceleration**: VA-API video decode, OpenGL, Vulkan support
- **Auto-Suspend**: NVIDIA automatically suspends after ~10s of inactivity

### Power Management
- **TLP Optimized**: Aggressive battery saving on battery, full performance on AC
- **zram**: 50% RAM compression for reduced SSD wear
- **Clamshell Mode**: Suspend on battery, stay awake when docked/plugged in
- **SSD Optimization**: Weekly TRIM, reduced swappiness

### Development Environment
- **Python**: System Python 3.13 + Poetry for dependency management
- **VSCodium**: Open-source VS Code build
- **Fish Shell**: Modern shell with better defaults
- **Flatpak**: Additional app repository for non-nixpkgs software

## 📦 Usage

### Initial Setup
```bash
# Clone this repository
git clone git@github.com:yourusername/nixos-config.git /etc/nixos

# Apply configuration
sudo nixos-rebuild switch

# Reboot
sudo reboot
```

### Using NVIDIA GPU
```bash
# Run applications with NVIDIA offload
nvidia-offload glxgears
nvidia-offload blender

# Check GPU status
nvidia-smi
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
```

### System Maintenance
```bash
# Update system
sudo nixos-rebuild switch --upgrade

# Clean old generations (automatic weekly, but can run manually)
sudo nix-collect-garbage -d
sudo nix-store --optimize

# Check system health
./check-system.sh  # If you include the verification script
```

## 🔧 Customization

### Modify Configuration
```bash
sudo nano /etc/nixos/configuration.nix
sudo nixos-rebuild switch
```

### Add Packages

Edit `environment.systemPackages` in `configuration.nix`:
```nix
environment.systemPackages = with pkgs; [
  # Add your packages here
  neovim
  htop
];
```

### Install Flatpak Apps
```bash
flatpak install flathub org.telegram.desktop
flatpak install flathub com.spotify.Client
```

## 📚 Useful Commands
```bash
# Search for packages
nix search nixpkgs <package-name>

# Test configuration without committing
sudo nixos-rebuild test

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Check which packages are installed
nix-env -q
```

## 🐛 Troubleshooting

### NVIDIA Not Suspending
```bash
# Check power state
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status

# Should show "suspended" when idle
# If "active", check what's using it:
nvidia-smi
```

### Battery Life Issues
```bash
# Check power draw
cat /sys/class/power_supply/BAT0/power_now

# Monitor with powertop
sudo powertop
```

### Display Refresh Rate
```bash
# List available modes
xrandr

# Set refresh rate
xrandr --output eDP-1 --mode 1920x1080 --rate 100
```

## 📖 Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Search](https://search.nixos.org/)
- [NixOS Wiki - NVIDIA](https://nixos.wiki/wiki/Nvidia)
- [NixOS Discourse](https://discourse.nixos.org/)

## 📝 Notes

- **Kernel**: Using 6.12 LTS for NVIDIA driver compatibility (6.19+ has compilation issues)
- **Battery Thresholds**: Charge control commented out - uncomment if ThinkPad supports it
- **VPN Clients**: Surfshark and Pulse Secure installed via AppImage/Flatpak (not in nixpkgs)

## 📄 License

This configuration is provided as-is for reference. Modify as needed for your hardware.

---

**Maintainer**: Keshav Sundararaman  
**Last Updated**: March 8, 2026  
**NixOS Version**: 25.11 (Xantusia)
