{
  lib,
  config,
  inputs,
  ...
}: {
  imports = [inputs.nixcord.homeModules.nixcord];

  options.modules.discord.enable = lib.mkEnableOption "discord with nixcord";

  config = lib.mkIf config.modules.discord.enable {
    programs.nixcord = {
      enable = true;

      config = {
        themeLinks = ["https://raw.githubusercontent.com/refact0r/system24/refs/heads/main/theme/system24.theme.css"];

        frameless = true;

        plugins = {
          biggerStreamPreview.enable = true;
          callTimer.enable = true;
          decor.enable = true;
          fixSpotifyEmbeds.enable = true;
          friendsSince.enable = true;
          gameActivityToggle.enable = true;
          messageLogger.enable = true;
          petpet.enable = true;
          reverseImageSearch.enable = true;

          loadingQuotes = {
            enable = true;
            enablePluginPresetQuotes = false;
            # Titanfall 2 pilot ejection quotes
            additionalQuotes = "It was fun.|Ain't over till it's over.|Until next time, then.|Second star to the right.|Go get 'em, tiger.|Make it so.|See you on the other side.|Wait for the wheel.|Do not throw your shot.|Drop and burn 'em up.|Exhibit no restraint.|Rip and saw.|Code zero zero zero. Destruct. Zero.|Authorization Alpha-Alpha 3-0-5.|Have just the greatest day.|Avenge me.|Stay safe.|Situation normal.|PROTOCOL <3|Fly, you fool.|Never give up. Never surrender.|In case of doubt, attack.|You’re never beaten until you admit it.|Wrong us, shall we not revenge?|Till all are one.|Nothing but the rain.|Sometimes, you have to roll a hard six.|And sometimes, when you fall, you fly.|See you space cowboy...|Just another day at the office.|End of line.|Fortune favors the bold.|A leaf on the wind.|You are who you choose to be.|Always.|Finish the fight.";
          };
        };
      };
    };
  };
}
