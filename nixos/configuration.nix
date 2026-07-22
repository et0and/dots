# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
  # Keep Home Manager on the same release as the NixOS channel without relying
  # on a separate, mutable root-level channel.
  homeManager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/4ce190229c73d44536caa7072f6308fb2d8feeb3.tar.gz";
    sha256 = "sha256-ZWyzLbS1yKUTeFJLmdVuWNnHttL333/ldJbEE+KzCrM=";
  };
in

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      (import "${homeManager}/nixos")
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-6d8055fa-cc3d-47aa-956b-ab774dabff58".device = "/dev/disk/by-uuid/6d8055fa-cc3d-47aa-956b-ab774dabff58";
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  hardware.enableRedistributableFirmware = true;
  boot.kernelModules = [ "rtsx_pci" "rtsx_pci_sdmmc" ];

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Pacific/Auckland";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_NZ.UTF-8";
    LC_IDENTIFICATION = "en_NZ.UTF-8";
    LC_MEASUREMENT = "en_NZ.UTF-8";
    LC_MONETARY = "en_NZ.UTF-8";
    LC_NAME = "en_NZ.UTF-8";
    LC_NUMERIC = "en_NZ.UTF-8";
    LC_PAPER = "en_NZ.UTF-8";
    LC_TELEPHONE = "en_NZ.UTF-8";
    LC_TIME = "en_NZ.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  environment.sessionVariables = {
    PATH = [ "$HOME/.opencode/bin" ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tom = {
    isNormalUser = true;
    description = "Tom Hackshaw";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  # Activate Tom's Home Manager configuration with `nixos-rebuild switch`.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.tom = import ../home-manager/home.nix;
  };

  # Enable automatic login for the user.
  services.getty.autologinUser = "tom";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
     neovim
     wget
     curl
     loupe
     unstable.signal-desktop
     vscode
     zed-editor
     gh
     bibata-cursors
     go
     fastfetch
     tailscale
     gcc
     git
     unzip
     btop
     kitty
     pnpm
     nodejs
     bun
     fnm
     firefox
     wayland
     wofi
     dunst
     swww
     waypaper
     grim
     wrangler
     wl-clipboard
     cliphist
     thunar
     thunar-volman
     networkmanagerapplet
     polkit_gnome
  ];
  
  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    opencode
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
   };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.thunar.plugins = with pkgs.xfce; [
    thunar-archive-plugin
    thunar-volman
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  services.greetd = {
    enable = true;
    settings = {
     default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
      user = "greeter";
     };
    };
  };

  services.tailscale.enable = true;
  services.gvfs.enable = true;
  services.devmon.enable = true;
  programs.thunar.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-order-than 30d";
  };

  boot.loader.systemd-boot.configurationLimit = 10;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
