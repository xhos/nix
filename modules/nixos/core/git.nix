{
  config,
  lib,
  ...
}: {
  options.forge.remote = lib.mkOption {
    type = lib.types.str;
    # reachable from anywhere; features/tailnet.nix switches it to ssh
    default = "https://git.xhos.dev/xhos/";
    description = "where f: and existing forgejo ssh remotes point";
  };

  config = {
    programs.git = {
      enable = true;
      config = [{
        user = {
          name = "xhos";
          email = "60789741+xhos@users.noreply.github.com";
          signingKey = "/home/xhos/.ssh/github.pub";
        };
        gpg.format = "ssh";
        commit.gpgsign = true;
        url = {
          "https://github.com/" = {
            insteadOf = ["gh:"];
          };
          "git@github.com:xhos/" = {
            insteadOf = ["x:"];
          };
          # existing clones keep their ssh remote and follow forge.remote. no
          # self-rewrite: it would shadow the ci runner's GIT_CONFIG_* override
          ${config.forge.remote} = {
            insteadOf = lib.remove config.forge.remote ["f:" "ssh://git@enrai.ts.xhos.dev:2222/xhos/"];
          };
        };
        # forgejo access token over https, saved on first use
        credential."https://git.xhos.dev".helper = "store";
        status = {
          branch = true;
          showStash = true;
          showUntrackedFiles = "all";
        };
        init.defaultBranch = "main";
      }
      {
        includeIf."gitdir:/home/xhos/work/".path = "/home/xhos/.gitconfig-work";
      }];
    };

    programs.lazygit.enable = true;
  };
}
