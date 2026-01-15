{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.fish = lib.mkIf (config.shell == "fish") {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting # Disable greeting
      thefuck --alias | source
      source (/home/xhos/.nix-profile/bin/starship init fish --print-full-init | psub)
    '';

    shellAliases = {
      ns = "nix-shell -p";
      ff = "fastfetch";
      gcl = "git clone";
      ga = "git add .";
      gp = "git push";
      gc = "git commit -m";
      lg = "lazygit";
      s = "nix search nixpkgs";
      nhs = "nh home switch";
      nos = "nh os switch";
      img = "swayimg";
    };

    plugins = [
      # Enable a plugin (here grc for colorized command output) from nixpkgs
      {
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      }
      # Manually packaging and enable a plugin
      # {
      #   name = "z";
      #   src = pkgs.fetchFromGitHub {
      #     owner = "jethrokuan";
      #     repo = "z";
      #     rev = "e0e1b9dfdba362f8ab1ae8c1afc7ccf62b89f7eb";
      #     sha256 = "0dbnir6jbwjpjalz14snzd3cgdysgcs3raznsijd6savad3qhijc";
      #   };
      # }
    ];
  };
  # };
}
