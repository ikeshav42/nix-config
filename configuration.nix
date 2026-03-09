# NixOS Configuration for Lenovo ThinkPad P14s Gen 5
# Hardware: Intel Core Ultra 7 155H (Meteor Lake) + NVIDIA RTX 500 Ada Generation
# Purpose: Research workstation for computer vision and robotics (UTARI)
# Maintainer: Keshav Sundararaman
# Last Updated: March 8, 2026

{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ============================================================================
  # BOOT CONFIGURATION
  # ============================================================================
  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Kernel Configuration
  # Using 6.12 LTS - latest kernel compatible with NVIDIA proprietary drivers
  # Kernel 6.19+ has compilation issues with NVIDIA drivers as of this config
  boot.kernelPackages = pkgs.linuxPackages_6_12;
  
  # Intel Arc iGPU kernel parameters for Meteor Lake
  boot.kernelParams = [ 
    "i915.enable_guc=3"   # Enable GuC firmware for better power management
    "i915.enable_psr=1"   # Panel Self Refresh - enables high refresh rates (100Hz native)
  ];

  # SSD Performance Optimizations
  # Reduce unnecessary writes and improve responsiveness on NVMe SSD
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;           # Prefer RAM over swap (10 = low swappiness)
    "vm.vfs_cache_pressure" = 50;   # Retain directory/inode cache longer
  };

  # ============================================================================
  # NIX STORE MANAGEMENT
  # ============================================================================
  
  # Automatic garbage collection - keeps system clean
  # Runs weekly, removes generations older than 30 days
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Store optimization - deduplicates files in /nix/store
  # Can save several GB of disk space
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  # ============================================================================
  # NETWORK & LOCALIZATION
  # ============================================================================
  
  networking.hostName = "anakinskywalker";
  networking.networkmanager.enable = true;
  
  time.timeZone = "America/Chicago";  # CST/CDT (Arlington, Texas)
  i18n.defaultLocale = "en_US.UTF-8";

  # ============================================================================
  # GRAPHICS CONFIGURATION - Hybrid GPU Setup
  # ============================================================================
  
  # Hardware-accelerated graphics with Intel + NVIDIA support
  hardware.graphics = {
    enable = true;
    # VA-API drivers for Intel Arc hardware video acceleration
    extraPackages = with pkgs; [
      intel-media-driver    # Modern Intel GPUs (Meteor Lake)
      intel-vaapi-driver    # Legacy VA-API support
      libva-vdpau-driver    # VDPAU compatibility layer
      libvdpau-va-gl        # OpenGL VDPAU backend
    ];
  };

  # NVIDIA Configuration - PRIME Offload Mode
  # Default: Intel Arc handles all rendering (battery efficient)
  # On-demand: NVIDIA wakes for GPU-intensive tasks via nvidia-offload command
  services.xserver.videoDrivers = [ "modesetting" "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;              # Required for Wayland/modern display servers
    powerManagement.enable = true;          # Enable runtime power management
    powerManagement.finegrained = true;     # Fine-grained PM for Turing+ GPUs (Ada Lovelace supported)
    open = true;                            # Use open-source kernel module (required for Ada Lovelace)
    nvidiaSettings = true;                  # Enable nvidia-settings GUI tool
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # PRIME Offload Configuration
    # Bus IDs verified via lspci (Intel: 00:02.0, NVIDIA: 01:00.0)
    prime = {
      offload = {
        enable = true;              # Enable offload mode
        enableOffloadCmd = true;    # Provides nvidia-offload wrapper command
      };
      intelBusId = "PCI:0:2:0";    # Intel Arc iGPU
      nvidiaBusId = "PCI:1:0:0";   # NVIDIA RTX 500 Ada Generation
    };
  };

  # ============================================================================
  # DESKTOP ENVIRONMENT - GNOME on Wayland
  # ============================================================================
  
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.wayland = true;       # Wayland for modern compositor
  services.displayManager.gdm.autoSuspend = false;  # Prevent auto-suspend on GDM screen
  services.desktopManager.gnome.enable = true;

  # ============================================================================
  # AUDIO CONFIGURATION - PipeWire
  # ============================================================================
  
  security.rtkit.enable = true;  # RealtimeKit for low-latency audio
  
  services.pipewire = {
    enable = true;
    alsa.enable = true;           # ALSA compatibility
    alsa.support32Bit = true;     # 32-bit app support
    pulse.enable = true;          # PulseAudio compatibility layer
    jack.enable = true;           # JACK compatibility for pro audio
  };
  
  services.pulseaudio.enable = false;  # Replaced by PipeWire

  # ============================================================================
  # POWER MANAGEMENT - TLP Configuration
  # ============================================================================
  
  # Disable GNOME's power-profiles-daemon (conflicts with TLP)
  services.power-profiles-daemon.enable = false;

  # TLP - Advanced power management for laptops
  # Target: 6+ hours battery life with balanced performance
  services.tlp = {
    enable = true;
    settings = {
      # CPU Power Management
      CPU_SCALING_GOVERNOR_ON_AC = "performance";   # Max performance when plugged in
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";    # Efficiency on battery
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      
      # CPU Performance Limits
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;    # Full performance on AC
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 30;    # Cap at 30% on battery for longevity
      
      # CPU Boost (Turbo)
      CPU_BOOST_ON_AC = 1;              # Enable turbo boost on AC
      CPU_BOOST_ON_BAT = 0;             # Disable on battery to save power
      CPU_HWP_DYN_BOOST_ON_AC = 1;      # Intel HWP dynamic boost on AC
      CPU_HWP_DYN_BOOST_ON_BAT = 0;     # Disable on battery

      # Battery Health - Charge Thresholds
      # Commented out: Not all ThinkPads support these thresholds
      # Uncomment if your battery supports charge control:
      # START_CHARGE_THRESH_BAT0 = 75;  # Start charging at 75%
      # STOP_CHARGE_THRESH_BAT0 = 80;   # Stop at 80% (extends battery lifespan)

      # Runtime Power Management
      RUNTIME_PM_ON_AC = "on";      # Aggressive PM even on AC
      RUNTIME_PM_ON_BAT = "auto";   # Auto-suspend devices on battery

      # PCIe Power Management
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";  # Aggressive PCIe power saving

      # Network Power Management
      WIFI_PWR_ON_AC = "off";   # Full WiFi performance on AC
      WIFI_PWR_ON_BAT = "on";   # Enable WiFi power saving on battery
      WOL_DISABLE = "Y";        # Disable Wake-on-LAN

      # USB Power Management
      USB_AUTOSUSPEND = 1;           # Enable USB autosuspend
      USB_EXCLUDE_AUDIO = 1;         # Don't suspend audio devices
      USB_EXCLUDE_BTUSB = 0;         # Allow Bluetooth suspend
      USB_EXCLUDE_PHONE = 0;         # Allow phone suspend
      USB_EXCLUDE_PRINTER = 1;       # Don't suspend printers
      USB_EXCLUDE_WWAN = 0;          # Allow WWAN suspend
    };
  };

  # ============================================================================
  # MEMORY & SWAP OPTIMIZATION
  # ============================================================================
  
  # zram - Compressed swap in RAM
  # 50% of RAM (31GB on 62GB system) used for compressed swap
  # Reduces SSD wear and improves responsiveness
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # ============================================================================
  # STORAGE OPTIMIZATION
  # ============================================================================
  
  # TRIM for SSD - runs weekly to maintain SSD performance
  services.fstrim.enable = true;

  # ============================================================================
  # SYSTEM SERVICES
  # ============================================================================
  
  # ananicy-cpp - Automatic process priority optimization
  # Improves desktop responsiveness by managing process nice levels
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
  };

  # Printing support
  services.printing.enable = true;

  # ============================================================================
  # LAPTOP-SPECIFIC - Clamshell Mode
  # ============================================================================
  
  # Lid behavior configuration
  # - On battery: Close lid → Suspend
  # - Plugged in: Close lid → Stay awake (external monitor support)
  # - Docked: Close lid → Stay awake
  services.logind.settings = {
    Login = {
      HandleLidSwitch = "suspend";              # Suspend on battery
      HandleLidSwitchExternalPower = "ignore";  # Stay awake when plugged in
      HandleLidSwitchDocked = "ignore";         # Stay awake when docked
    };
  };

  # ============================================================================
  # GNOME POWER SETTINGS - Prevent Auto-Suspend on AC
  # ============================================================================
  
  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-timeout = pkgs.lib.gvariant.mkInt32 0;      # Never auto-suspend on AC
        sleep-inactive-battery-timeout = pkgs.lib.gvariant.mkInt32 900;  # 15 min timeout on battery
        idle-dim = false;  # Don't dim screen when plugged in
      };
      "org/gnome/desktop/session" = {
        idle-delay = pkgs.lib.gvariant.mkUint32 0;  # No idle timeout
      };
    };
  }];

  # ============================================================================
  # USER CONFIGURATION
  # ============================================================================
  
  users.users.ikeshav42 = {
    isNormalUser = true;
    description = "Keshav Sundararaman";
    extraGroups = [ 
      "networkmanager"  # Network configuration
      "wheel"           # sudo access
      "video"           # Video device access
      "audio"           # Audio device access
    ];
    shell = pkgs.fish;  # Fish as default shell
  };

  # Enable Fish shell system-wide
  programs.fish.enable = true;

  # ============================================================================
  # PACKAGE MANAGEMENT
  # ============================================================================
  
  # Allow unfree packages (NVIDIA drivers, Discord, VSCodium, etc.)
  nixpkgs.config.allowUnfree = true;

  # Flatpak support for apps not in nixpkgs
  services.flatpak.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    # ──────────────────────────────────────────────────────────────────────
    # System Tools
    # ──────────────────────────────────────────────────────────────────────
    vim neovim nano           # Text editors
    wget curl git             # Network tools
    htop btop                 # System monitors
    fastfetch                 # System info
    mesa-demos                # OpenGL utilities (glxinfo, glxgears)
    pciutils usbutils lshw    # Hardware info tools
    powertop brightnessctl    # Power/brightness management

    # ──────────────────────────────────────────────────────────────────────
    # Development Tools
    # ──────────────────────────────────────────────────────────────────────
    fishPlugins.bass          # Bash script compatibility for Fish
    poetry                    # Python dependency management
    vscodium                  # Open-source VS Code
    gcc                       # C/C++ compiler
    python3                   # Python interpreter

    # ──────────────────────────────────────────────────────────────────────
    # Desktop Environment
    # ──────────────────────────────────────────────────────────────────────
    gnome-tweaks              # GNOME customization
    gnome-extension-manager   # GNOME extensions manager

    # ──────────────────────────────────────────────────────────────────────
    # Browsers
    # ──────────────────────────────────────────────────────────────────────
    librewolf                 # Privacy-focused Firefox fork
    firefox                   # Mozilla Firefox

    # ──────────────────────────────────────────────────────────────────────
    # Communication
    # ──────────────────────────────────────────────────────────────────────
    discord                   # Chat/voice platform
    # telegram-desktop        # Commented: Installing via Flatpak instead

    # ──────────────────────────────────────────────────────────────────────
    # Utilities
    # ──────────────────────────────────────────────────────────────────────
    qbittorrent               # Torrent client

    # VPN clients not available in nixpkgs:
    # - Surfshark: Use AppImage or Flatpak
    # - Pulse Secure: Use AppImage or manual install

    # ──────────────────────────────────────────────────────────────────────
    # Media Codecs - Hardware Acceleration & Playback
    # ──────────────────────────────────────────────────────────────────────
    gst_all_1.gst-plugins-base   # GStreamer base plugins
    gst_all_1.gst-plugins-good   # Good quality plugins
    gst_all_1.gst-plugins-bad    # Lower quality but useful plugins
    gst_all_1.gst-plugins-ugly   # Patent-encumbered plugins (MP3, etc.)
    gst_all_1.gst-libav          # FFmpeg integration
    ffmpeg-full                  # Complete FFmpeg with all codecs
  ];

  # ============================================================================
  # SYSTEM VERSION
  # ============================================================================
  
  # DO NOT CHANGE - Tracks NixOS version for compatibility
  # Set during initial installation
  system.stateVersion = "25.11";
}
