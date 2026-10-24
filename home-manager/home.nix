{ config, pkgs, unstable, ... }:

let
  # IRIS pinned to commit 7c1e449 (2026-10-17). Not in nixpkgs yet, so build
  # the Go module directly from a pinned GitHub tarball.
  iris = pkgs.buildGoModule {
    pname = "iris";
    version = "0-unstable-2026-10-17";
    src = pkgs.fetchFromGitHub {
      owner = "versenilvis";
      repo = "IRIS";
      rev = "7c1e449529fbaea329a698774b2dcb0c5d9ba368";
      hash = "sha256-MeemUaqWEbBFMO0Q8sXey3PdPAFO/IcoYHCb38W628k=";
    };
    subPackages = [ "cmd/iris" ];
    proxyVendor = true;
    vendorHash = "sha256-huyTWK6ef42KY2zmFIQuFoeR8B8XKHE7OVfFnfefeCU=";
    doCheck = false;
    meta = {
      description = "Shell auto-completion tool";
      homepage = "https://github.com/versenilvis/IRIS";
      license = pkgs.lib.licenses.bsd0;
      mainProgram = "iris";
    };
  };
in

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "tom";
  home.homeDirectory = "/home/tom";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  home.packages = [
    pkgs.playerctl
    iris
    unstable.opencode-desktop
  ];

  # Start IRIS for interactive bash sessions. IRIS execs itself and runs bash
  # underneath; `iris` must be on PATH (home.packages above guarantees that).
  programs.bash = {
    enable = true;
    initExtra = ''
      eval "$(iris init bash)"
    '';
  };

  # Provide Bibata consistently to Hyprland, GTK, XWayland, and applications.
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };
  gtk.enable = true;

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Config files version-controlled in ~/Dev/dots. These are out-of-store
  # symlinks: the repo stays the source of truth and edits apply without a
  # Home Manager rebuild (run `hyprctl reload` for hyprland.conf).
  xdg.configFile = {
    "hypr/hyprland.conf".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/Dev/dots/config/hypr/hyprland.conf";
    "waypaper/config.ini".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/Dev/dots/config/waypaper/config.ini";
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/tom/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        output = null;
        modules-left = [
          "hyprland/workspaces"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "pulseaudio"
          "network"
          "battery"
          "tray"
        ];
        "hyprland/workspaces" = {
          format = "{name}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "10";
          };
          persistent-workspaces = {
            "*" = 10;
          };
        };
        "clock" = {
          format = "{:%H:%M  %a %d %b}";
          tooltip-format = "{:%Y-%m-%d | %H:%M}";
        };
        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 Muted";
          format-icons = {
            default = [ "" "" "" ];
          };
          scroll-step = 5;
          on-click = "pavucontrol";
        };
        "network" = {
          format-wifi = " {essid}";
          format-ethernet = " {ipaddr}";
          format-disconnected = "⚠ Disconnected";
          tooltip-format = "{ifname}";
        };
        "battery" = {
          format = "{icon} {capacity}%";
          format-icons = [ "" "" "" "" "" ];
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
        };
        "tray" = {
          spacing = 10;
        };
      };
    };
    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font", "Noto Sans", sans-serif;
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: rgba(30, 30, 30, 0.9);
        border-bottom: 2px solid rgba(51, 51, 51, 0.8);
        color: #ffffff;
      }

      #workspaces button {
        padding: 0 8px;
        background: transparent;
        color: #bbbbbb;
        border-bottom: 2px solid transparent;
      }

      #workspaces button.active {
        color: #ffffff;
        border-bottom: 2px solid #33ccff;
      }

      #workspaces button.urgent {
        background: #e53935;
      }

      #workspaces button:hover {
        background: rgba(51, 204, 255, 0.15);
        color: #ffffff;
        text-shadow: none;
        box-shadow: none;
      }

      #clock,
      #pulseaudio,
      #network,
      #battery,
      #tray {
        padding: 0 10px;
        margin: 0 2px;
      }

      #clock {
        color: #ffffff;
      }

      #pulseaudio {
        color: #a6e3a1;
      }

      #network {
        color: #89b4fa;
      }

      #battery {
        color: #f9e2af;
      }

      #battery.warning {
        color: #fab387;
      }

      #battery.critical {
        color: #f38ba8;
      }

      #battery.charging {
        color: #a6e3a1;
      }

      #tray {
        background: rgba(255, 255, 255, 0.05);
        border-radius: 4px;
        padding: 0 6px;
      }
    '';
  };
}
