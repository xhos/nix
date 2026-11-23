{
  inputs = {
    # --- core -----------------------------------------------------------
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-24.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- system ---------------------------------------------------------
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    # deliberately NOT following: proxmox packages are built against its own
    # pinned nixpkgs, and following would lose their binary cache hits
    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-secrets = {
      url = "git+ssh://git@enrai.ts.xhos.dev:2222/xhos/nix-secrets?ref=main&allRefs=1";
      flake = false;
    };

    # --- customization --------------------------------------------------
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    transparent-spotify = {
      url = "github:xhos/transparent-spotify";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yawn = {
      url = "github:xhos/yawn";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bootvine = {
      url = "git+https://codeberg.org/wvhulle/bootvine";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    logi-hypr = {
      url = "github:xhos/logi-hypr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # swissh.url = "github:xhos/swissh";

    # --- applications ---------------------------------------------------
    # mkWindowsApp, used by pkgs/adobe-acrobat-reader.nix
    erosanix = {
      url = "github:emmanuelrosa/erosanix";
      flake = false;
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord = {
      url = "github:kaylorben/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nxv = {
      url = "github:xhos/nxv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # --- services -------------------------------------------------------
    declarr = {
      url = "github:xhos/declarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jellarr = {
      url = "github:venkyr77/jellarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niks3 = {
      url = "github:Mic92/niks3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nagomi = {
      url = "github:xhos/nagomi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wled-album-sync = {
      url = "github:xhos/wled-album-sync";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kodama = {
      url = "git+ssh://git@enrai.ts.xhos.dev:2222/xhos/kodama?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- utilities ------------------------------------------------------
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vpn-confinement = {
      url = "github:Maroka-chan/VPN-Confinement";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-parts,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;

    systems = ["x86_64-linux" "aarch64-linux"];
    forEachSystem = nixpkgs.lib.genAttrs systems;
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      inherit systems;

      imports = [
        flake-parts.flakeModules.modules
        ./lib/hosts.nix
        (inputs.import-tree ./features)
        (inputs.import-tree.match ".*/configuration\\.nix" ./systems)
      ];

      flake = {
        # hostname is the ssh alias from modules/home/core/ssh.nix, which carries the ip and key
        deploy.nodes = lib.genAttrs ["melchior" "balthasar" "casper"] (hostname: {
          inherit hostname;
          sshUser = "xhos";
          profiles.system = {
            user = "root";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.${hostname};
          };
        });

        packages =
          forEachSystem (system: {
            installer = import ./pkgs/installer.nix {
              pkgs = nixpkgs.legacyPackages.${system};
            };
            remote-install = import ./pkgs/remote-install.nix {
              pkgs = nixpkgs.legacyPackages.${system};
            };
            pcinfo = import ./pkgs/pcinfo.nix {
              pkgs = nixpkgs.legacyPackages.${system};
            };
            e2-micro-image = self.nixosConfigurations.e2-micro.config.system.build.OCIImage;
          })
          // {
            aarch64-linux.a1-flex-image = self.nixosConfigurations.a1-flex.config.system.build.OCIImage;
          };
      };
    };
}
