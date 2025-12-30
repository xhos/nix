{config, ...}: {
  sops.secrets."api/atuin/key" = {};
  sops.secrets."api/atuin/session" = {};

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = ["--disable-up-arrow"];
    settings = {
      sync_address = "https://atuin.xhos.dev";
      enter_accept = true;
      update_check = false;
      filter_mode_shell_up_key_binding = "session";
      inline_height = 10;
      invert = true;
      show_help = false;

      key_path = config.sops.secrets."api/atuin/key".path;
      session_path = config.sops.secrets."api/atuin/session".path;
    };
  };

  programs.zsh.initContent = ''bindkey "$key[Down]"  atuin-up-search'';
}
