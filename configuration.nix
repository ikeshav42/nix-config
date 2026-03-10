{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  services.openssh.enable = true;

  # BOOT
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;

  # Test newer kernel
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  boot.kernelParams = [
    "i915.enable_guc=3"
    "i915.enable_psr=1"
  ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
  };

  # NIX STORE MANAGEMENT
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  # NETWORK
  networking.hostName = "anakinskywalker";

  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-openconnect
    ];
  };

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # Firmware
  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;
  # GRAPHICS
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  services.xserver.videoDrivers = [ "modesetting" "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # DESKTOP
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.wayland = true;
  services.displayManager.gdm.autoSuspend = false;
  services.desktopManager.gnome.enable = true;

  # AUDIO
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services.pulseaudio.enable = false;

  # POWER MANAGEMENT
  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;

    settings = {

      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;

      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 30;

      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";

      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      WOL_DISABLE = "Y";

      USB_AUTOSUSPEND = 1;
      USB_EXCLUDE_AUDIO = 1;
      USB_EXCLUDE_BTUSB = 0;
      USB_EXCLUDE_PHONE = 0;
      USB_EXCLUDE_PRINTER = 1;
      USB_EXCLUDE_WWAN = 0;
    };
  };

  # MEMORY
  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  # STORAGE
  services.fstrim.enable = true;

  # PROCESS PRIORITY
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
  };

  services.printing.enable = true;

  # CLAMSHELL
  services.logind.settings = {
    Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
    };
  };

  # GNOME POWER SETTINGS
  programs.dconf.enable = true;

  programs.dconf.profiles.user.databases = [{
    settings = {

      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-timeout = pkgs.lib.gvariant.mkInt32 0;
        sleep-inactive-battery-timeout = pkgs.lib.gvariant.mkInt32 900;
        idle-dim = false;
      };

      "org/gnome/desktop/session" = {
        idle-delay = pkgs.lib.gvariant.mkUint32 0;
      };
    };
  }];

  # USER
  users.users.ikeshav42 = {
    isNormalUser = true;
    description = "Keshav Sundararaman";

    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "libvirtd"
      "kvm"
    ];

    shell = pkgs.fish;
  };

  programs.fish = {
  enable = true;

  shellAliases = {
    build = "sudo nixos-rebuild build -L";
    rebuild = "sudo nixos-rebuild switch";
    rebuild-test = "sudo nixos-rebuild test";

    update = "sudo nix-channel --update && sudo nixos-rebuild switch";
    rollback = "sudo nixos-rebuild switch --rollback";

    cleanup = "sudo nix-collect-garbage -d";
    generations = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";

    nixconfig = "sudo nano /etc/nixos/configuration.nix";
  };
};
  #PACKAGES
  nixpkgs.config.allowUnfree = true;

  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; [

    vim neovim nano
    wget curl git mesa-demos

    htop btop
    fastfetch

    pciutils usbutils lshw
    powertop brightnessctl

    poetry
    vscodium
    gcc
    python3

    fishPlugins.bass

    claude-code
    sshfs
    virt-manager

    gnome-tweaks
    gnome-extension-manager

    librewolf
    firefox

    discord

    qbittorrent
    celluloid

    openconnect

    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    ffmpeg-full
  ];

  # PODMAN
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  system.stateVersion = "25.11";
}
