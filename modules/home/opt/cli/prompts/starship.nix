{
  config,
  lib,
  ...
}: {
  config = lib.mkIf (config.prompt == "starship") {
    programs.starship = with config.lib.stylix.colors; {
      enable = true;
      enableTransience = true;
      settings = {
        format = "$username $hostname $directory $git_branch $git_state $git_status $cmd_duration $line_break $python $character";

        character = {
          success_symbol = "[ム](purple)";
          error_symbol = "[ム](red)";
          vimcmd_symbol = "[ム](green)";
        };

        directory = {
          style = "blue";
        };

        git_branch = {
          format = "[$branch]($style)";
          style = "bright-black";
        };

        git_status = {
          format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)";
          style = "cyan";
          conflicted = "​";
          untracked = "​";
          modified = "​";
          staged = "​";
          renamed = "​";
          deleted = "​";
          stashed = "≡";
        };

        git_state = {
          format = "([$state( $progress_current/$progress_total)]($style))";
          style = "bright-black";
        };

        cmd_duration = {
          format = "[$duration]($style) ";
          style = "yellow";
        };

        python = {
          format = "[$virtualenv]($style) ";
          style = "bright-black";
        };

        nix_shell = {
          format = "($style)[](fg:#${base05})($style)";
          style = "bg:none fg:#${base01}";
          impure_msg = "";
          pure_msg = "";
          unknown_msg = "";
        };
      };
    };
  };
}
