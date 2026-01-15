{
  config,
  lib,
  ...
}: {
  config = lib.mkIf (config.shell == "nu") {
    programs.nushell = {
      enable = true;

      configFile.text = ''
        $env.TRANSIENT_PROMPT_COMMAND = ""

        alias ns = nix-shell -p
        alias gcl = git clone
        alias cat = bat
        alias fzf = sk

        let fish_completer = {|spans|
            fish --command $'complete "--do-complete=($spans | str join " ")"'
            | $"value(char tab)description(char newline)" + $in
            | from tsv --flexible --no-infer
        }

        let carapace_completer = {|spans|
          carapace $spans.0 nushell ...$spans | from json
        }

        let zoxide_completer = {|spans|
            $spans | skip 1 | zoxide query -l ...$in | lines | where {|x| $x != $env.PWD}
        }

        # This completer will use carapace by default
        let external_completer = {|spans|
            let expanded_alias = scope aliases
            | where name == $spans.0
            | get -i 0.expansion

            let spans = if $expanded_alias != null {
                $spans
                | skip 1
                | prepend ($expanded_alias | split row ' ' | take 1)
            } else {
                $spans
            }

            match $spans.0 {
                # carapace completions are incorrect for nu
                nu => $fish_completer
                # fish completes commits and branch names in a nicer way
                git => $fish_completer
                # carapace doesn't have completions for asdf
                asdf => $fish_completer
                # use zoxide completions for zoxide commands
                __zoxide_z | __zoxide_zi => $zoxide_completer
                _ => $carapace_completer
            } | do $in $spans
        }


        $env.config = {
          show_banner: false,
          completions: {
            external: {
              enable: true
              completer: $external_completer
            }
          }
        }
      '';
    };
  };
}
