{
  inputs = {
    # --- core -----------------------------------------------------------
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-24.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- system ---------------------------------------------------------
    disko.url = "github:nix-community/disko";
    impermanence.url = "github:nix-community/impermanence";
    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-secrets = {
      url = "git+ssh://git@github.com/xhos/nix-secrets?ref=main&allRefs=1";
      flake = false;
    };

    # --- hyprland -------------------------------------------------------
    # hyprland = {
    # url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    # inputs.nixpkgs.follows = "nixpkgs";
    # };
    # hypr-dynamic-cursors = {
    #   url = "github:VirtCode/hypr-dynamic-cursors";
    #   inputs.hyprland.follows = "hyprland";
    # };
    # hyprgrass = {
    #   url = "github:horriblename/hyprgrass";
    #   inputs.hyprland.follows = "hyprland";
    # };
    # hyprsplit = {
    #   url = "github:shezdy/hyprsplit";
    #   inputs.hyprland.follows = "hyprland";
    # };
    logi-hypr.url = "github:xhos/logi-hypr";

    # --- customization --------------------------------------------------
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yawn.url = "github:xhos/yawn";
    # swissh.url = "github:xhos/swissh";

    # --- applications ---------------------------------------------------
    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord.url = "github:kaylorben/nixcord";
    nxv.url = "github:xhos/nxv";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    # --- services -------------------------------------------------------
    declarr = {
      url = "github:xhos/declarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server.url = "github:nix-community/nixos-vscode-server";
    wled-album-sync.url = "github:xhos/wled-album-sync";

    # --- utilities ------------------------------------------------------
    import-tree.url = "github:vic/import-tree";
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;

    # custom functions
    import-tree = import ./lib/import-tree.nix {inherit inputs lib;};

    # shared modules across all hosts with home-manager
    sharedNixosModules = [
      home-manager.nixosModules.home-manager
      inputs.stylix.nixosModules.stylix
      inputs.impermanence.nixosModules.impermanence
    ];

    mkNixosSystem = import ./lib/mk-nixos-system.nix {
      inherit
        lib
        inputs
        import-tree
        sharedNixosModules
        ;
    };

    systems = ["x86_64-linux" "aarch64-linux"];
    forEachSystem = nixpkgs.lib.genAttrs systems;
  in {
    nixosConfigurations = builtins.mapAttrs (hostname: args: mkNixosSystem ({inherit hostname;} // args)) {
      aevon = {};
      mizore = {
        homeUser = null;
      };
      arashi = {};
      a1-flex = {
        homeUser = null;
        minimal = true;
      };
      e2-micro = {
        homeUser = null;
        minimal = true;
      };
      enrai = {
        homelab = true;
      };
      nyx = {
        homeUser = null;
        minimal = true;
      };
      proxy-1 = {
        homeUser = null;
        minimal = true;
      };
      vyverne = {};
      zireael = {};
    };

    packages =
      forEachSystem (system: {
        installer = import ./pkgs/installer.nix {
          pkgs = nixpkgs.legacyPackages.${system};
        };
        e2-micro-image = self.nixosConfigurations.e2-micro.config.system.build.OCIImage;
      })
      // {
        aarch64-linux.a1-flex-image = self.nixosConfigurations.a1-flex.config.system.build.OCIImage;
      };
  };
}
