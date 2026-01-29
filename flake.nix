{
  description = "overcomplicated mess of a system flake that works for some reason";

  inputs = {
    # core
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

    # system
    disko.url = "github:nix-community/disko";
    impermanence.url = "github:nix-community/impermanence";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-secrets = {
      url = "git+ssh://git@github.com/xhos/nix-secrets?ref=main&allRefs=1";
      flake = false;
    };

    # hyprland
    # hyprland = {
    #   url = "github:hyprwm/Hyprland";
    #   inputs.nixpkgs.follows = "nixpkgs";
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

    # customization
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tsutsumi = {
      url = "github:Fuwn/tsutsumi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    yawn.url = "github:xhos/yawn";
    swissh.url = "github:xhos/swissh";

    # applications
    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixcord.url = "github:kaylorben/nixcord";
    nxv.url = "github:xhos/nxv";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    # services
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    wled-album-sync.url = "github:xhos/wled-album-sync";

    # utilities
    import-tree.url = "github:vic/import-tree";
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
    nixosConfigurations = {
      aevon = mkNixosSystem {hostname = "aevon";};
      enrai = mkNixosSystem {hostname = "enrai";};
      nyx = mkNixosSystem {
        hostname = "nyx";
        homeUser = null;
        minimal = true;
      };
      vyverne = mkNixosSystem {hostname = "vyverne";};
      zireael = mkNixosSystem {hostname = "zireael";};
    };

    nixOnDroidConfigurations.pixel = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
      pkgs = import nixpkgs {system = "aarch64-linux";};
      modules = [./modules/droid/_pixel/configuration.nix];
      extraSpecialArgs = {inherit inputs;};
    };

    packages = forEachSystem (
      system: {
        installer = import ./scripts/installer.nix {
          pkgs = nixpkgs.legacyPackages.${system};
        };
      }
    );
  };
}
