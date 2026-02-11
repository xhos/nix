{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.shell == "zsh") {
    programs.zoxide.enable = true;
    programs.zoxide.enableZshIntegration = true;
    programs.zsh = {
      enable = true;
      history.path = "${config.xdg.dataHome}/zsh/zsh_history";
      plugins = [
        {
          name = pkgs.zsh-autosuggestions.pname;
          src = pkgs.zsh-autosuggestions.src;
        }
        {
          name = pkgs.zsh-syntax-highlighting.pname;
          src = pkgs.zsh-syntax-highlighting.src;
        }
      ];
      initContent = "disable r";
      envExtra = ''
        bindkey '^[[1;5D' backward-word
        bindkey '^[[1;5C' forward-word
        bindkey -s '^[[1;2D' '^[b'  # Shift + Left Arrow to select the word to the left
        bindkey -s '^[[1;2C' '^[f'  # Shift + Right Arrow to select the word to the right
      '';
    };
  };
}
