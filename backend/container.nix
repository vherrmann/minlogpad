{ inputs, ... }:
{ config, pkgs, ... }:

let
  minlogpad-package = pkgs.callPackage ./package.nix { };
  minlogpad-static = pkgs.callPackage ./static.nix { };
  minlog-package =
    pkgs.callPackage (import ./minlog.nix { inherit (inputs) minlogSrc; }) { };
  myttyd = (pkgs.callPackage ./ttyd/default.nix { }).overrideAttrs
    (oldAttrs: rec {
      postPatch = ''
        sed -ie "/window.addEventListener('beforeunload', this.onWindowUnload);/ d" html/src/components/terminal/index.tsx
        sed -ie "s/Connection Closed/Connection closed/" html/src/components/terminal/index.tsx
        sed -ie "s/document.title = data + ' | ' + this.title;/document.title = data;/" html/src/components/terminal/index.tsx
      '';
    });
  mydwm = pkgs.dwm.overrideAttrs (oldAttrs: rec {
    postPatch = ''
      sed -i -e 's/showbar\s*=\s*1/showbar = 0/' config.def.h
    '';
  });
  sharedEmacsPkgs = (epkgs: [
    epkgs.evil
    epkgs.tramp-theme
    epkgs.ahungry-theme
    epkgs.color-theme-sanityinc-tomorrow
    minlog-package
  ]);
  myemacs = pkgs.emacs.pkgs.withPackages
    (epkgs: sharedEmacsPkgs epkgs ++ [ epkgs.polymode epkgs.markdown-mode ]);
  myemacs-nox = pkgs.emacs-nox.pkgs.withPackages sharedEmacsPkgs;
in {
  services.journald.extraConfig = ''
    Storage=volatile
    RuntimeMaxUse=20M
  '';

  time.hardwareClockInLocalTime = true;
  networking.firewall.enable = false;

  # This option defaults to true, but not if the system is itself a container.
  # We need to ensure that this option is set in any case, so that our nested
  # containers will work.
  boot.enableContainers = true;

  # This declaration is redundant if this configuration file is imported as a
  # container from the configuration file of a host system, of if it used for a
  # command such as `nixos-generate -f lxc`. However, for convenience, we also want
  # `nix-build "<nixpkgs/nixos>" -A system -I nixos-config=./container.nix` to work.
  # Without this option, nix-build would rightfully complain about missing file
  # system information.
  boot.isContainer = true;

  # When creating an lxc image using a command like `nixos-generate -c container.nix -f lxc`,
  # the file nixos/virtualisation/lxc-container.nix is included, thereby
  # enabling this option. We require it to be false, though.
  environment.noXlibs = false;

  systemd.services.xprovisor = {
    description = "xprovisor";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart =
        "${pkgs.websocat}/bin/websocat -e -E --binary ws-l:0.0.0.0:6080 sh-c:${minlogpad-package}/xprovisor.pl";
    };
    path = with pkgs; [
      bash
      perl
      coreutils
      util-linux
      xprintidle-ng
      xdotool
      netcat
      gawk
      procps
    ];
  };

  systemd.services.xprovisor-maint = {
    description = "xmaint";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${minlogpad-package}/xprovisor.pl";
      Environment = "WEBSOCAT_URI=/?maintainance";
    };
    path = with pkgs; [
      bash
      perl
      coreutils
      util-linux
      xprintidle-ng
      xdotool
      netcat
      gawk
      procps
    ];
  };

  systemd.timers.xprovisor-maint = {
    wantedBy = [ "timers.target" ];
    description = "xmaint";
    timerConfig = { OnCalendar = "*:0/1"; };
  };

  systemd.services.ttyprovisor = {
    description = "ttyprovisor";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      MemoryMax = "3G";
      ExecStart =
        "${myttyd}/bin/ttyd -b /__tty -a ${minlogpad-package}/ttyprovisor.pl";
    };
    path = with pkgs; [
      bash
      perl
      systemd
      util-linux
      coreutils
      shadow.su
      tmux
      myemacs-nox
    ];
  };

  systemd.services.ttyprovisor-maint = {
    description = "ttymaint";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${minlogpad-package}/ttyprovisor.pl .maintainance";
    };
    path = with pkgs; [
      bash
      perl
      systemd
      util-linux
      coreutils
      shadow.su
      tmux
      myemacs-nox
    ];
  };

  systemd.timers.ttyprovisor-maint = {
    wantedBy = [ "timers.target" ];
    description = "ttymaint";
    timerConfig = { OnCalendar = "*:0/1"; };
  };

  systemd.services.terminate-before-shutdown = {
    description = "terminate-before-shutdown";
    before = [ "shutdown.target" ];
    wantedBy = [ "shutdown.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${minlogpad-package}/xprovisor.pl";
      Environment = "WEBSOCAT_URI=/?terminate";
      TimeoutStartSec = "0";
    };
    path = with pkgs; [
      bash
      perl
      coreutils
      util-linux
      xprintidle-ng
      xdotool
      netcat
      gawk
      procps
    ];
  };

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  users.groups.guest = { gid = 994; };
  users.users.guest = {
    isSystemUser = true;
    group = "guest";
    description = "Guest";
    home = "/home/guest";
    uid = 995;
  };

  systemd.tmpfiles.rules = [
    "C /home/.skeleton/examples 0750 guest guest - ${minlog-package}/share/doc/minlog/examples"
    "d /home/.skeleton/doc/ 0750 guest guest - -"
    "C /home/.skeleton/doc/tutor.pdf 0750 guest guest - ${minlog-package}/share/doc/minlog/tutor.pdf"
    "C /home/.skeleton/doc/ref.pdf 0750 guest guest - ${minlog-package}/share/doc/minlog/ref.pdf"
  ];

  systemd.services.nginx.serviceConfig.BindReadOnlyPaths =
    "/proc/loadavg:/loadavg";
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;

    user = "guest";
    # so nginx can serve /~foo/bar.scm (also read-write using DAV)

    package = pkgs.nginxMainline.override {
      modules = with pkgs.nginxModules; [ brotli dav develkit moreheaders ];
    };

    # important to prevent annoying reconnects
    appendHttpConfig = ''
      proxy_send_timeout 600;
      proxy_read_timeout 600;
      proxy_http_version 1.1;
    '';

    commonHttpConfig = ''
      brotli on;
      brotli_static on;
      brotli_types application/json application/javascript application/xml application/xml+rss image/svg+xml text/css text/html text/javascript text/plain text/xml text/haskell text/x-scheme;
      types {
        text/x-scheme scm rkt;
        text/haskell hs;
        text/x-asm    s;
      }
      charset utf-8;
      charset_types text/haskell text/x-scheme text/x-asm;
      dav_ext_lock_zone zone=foo:10m;
    '';

    virtualHosts.localhost = {
      locations = {
        "/" = {
          root = minlogpad-static;
          extraConfig = ''
            expires 7d;
          '';
        };
        "/index.html" = {
          root = minlogpad-static;
          extraConfig = ''
                        expires 3h;
            #            set_by_lua_block $do_preconnect {
            #              local f = io.open("/loadavg")
            #              local line = f:read("*line")
            #              f:close()
            #              local l1 = string.match(line, "([%d]*%.[%d]*)%s")
            #              if tonumber(l1) >= 2 then
            #                return "0"
            #              else
            #                return "1"
            #              end
            #            }
            #            sub_filter '"__DO_PRECONNECT__"' $do_preconnect;
          '';
        };
        "/__tty" = {
          proxyPass = "http://localhost:7681";
          proxyWebsockets = true;
        };
        "/__vnc" = {
          proxyPass = "http://localhost:6080";
          proxyWebsockets = true;
        };
        "~ ^/~(\\w+)(\\/.*)?$" =
          { # exclude both ".."-style enumeration attacks and access to ".skeleton", ".hot-spare-*" etc.
            alias = "/home/$1$2";
            extraConfig = ''
              expires epoch;
              autoindex on;
              dav_methods     PUT DELETE MKCOL COPY MOVE;
              dav_ext_methods PROPFIND OPTIONS;
              dav_access      user:rw group:rw all:r;
            '';
          };
      };
    };
  };

  # required so nginx can serve /~foo/bar.scm
  systemd.services.nginx.serviceConfig.ProtectHome = "no";

  containers = let
    # config shared by xskeleton and ttyskeleton
    sharedContainerConfig = {
      ephemeral = true;
      privateNetwork = true;
      bindMounts = {
        "/home/guest" = {
          hostPath = "/home/.skeleton";
          isReadOnly = false;
        };
      };
      extraFlags = [ "--setenv=MINLOGPAD_SESSION_NAME=__SESSION_NAME__" ];
    };
    # config shared by xskeleton and ttyskeleton
    sharedSystemConfig = { config, pkgs, ... }: {
      services.journald.extraConfig = ''
        Storage=volatile
        RuntimeMaxUse=1M
      '';

      time.hardwareClockInLocalTime = true;

      networking.hostName = "ada";
      networking.firewall.enable = false;

      programs.bash.enableCompletion = false;

      environment.systemPackages = with pkgs; [ chez ];

      environment.variables.MINLOGPATH = "${minlog-package}/share/minlog";

      users.groups.guest = { gid = 994; };
      users.users.guest = {
        isSystemUser = true;
        group = "guest";
        description = "Guest";
        home = "/home/guest";
        uid = 995;
      };

      system.stateVersion = "23.05";
    };
  in {
    ttyskeleton = sharedContainerConfig // {
      config = { config, pkgs, ... }: {
        imports = [ sharedSystemConfig ];
        environment.systemPackages = with pkgs; [
          bash
          perl
          tmux
          vim
          myemacs-nox
        ];
      };
    };
    xskeleton = sharedContainerConfig // {
      config = { config, pkgs, ... }: {
        imports = [ sharedSystemConfig ];
        hardware.pulseaudio.enable = true;

        environment.systemPackages = with pkgs; [
          tigervnc
          myemacs
          screenkey
          st
          mydwm
          netcat
          xosd
        ];

        fonts.fontconfig.enable = true;
        fonts.fonts = with pkgs; [ hack-font ubuntu_font_family ];

        services.xserver = {
          enable = true;
          # desktopManager.xfce.enable = true;
          displayManager.startx.enable = true;
        };

        systemd.services.vnc = {
          wantedBy = [ "multi-user.target" ];
          description = "vnc";
          serviceConfig = {
            User = "guest";
            ExecStart = "${minlogpad-package}/vncinit.sh";
          };
          postStop = "${minlogpad-package}/vncdown.sh";
          path = with pkgs; [
            bash
            util-linux
            xorg.xauth
            tigervnc
            netcat
            coreutils
            mydwm
            myemacs
          ];
        };

        systemd.paths.poweroff = {
          wantedBy = [ "multi-user.target" ];
          description = "poweroff after VNC logout";
          pathConfig = { PathExists = "/tmp/poweroff"; };
        };

        systemd.services.poweroff = {
          description = "poweroff after VNC logout";
          serviceConfig = { ExecStart = "${pkgs.systemd}/bin/poweroff"; };
        };
      };
    };
  };

  system.stateVersion = "23.05";
}
