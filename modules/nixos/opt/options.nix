{lib, ...}: {
  options = with lib; {
    # All module enable options have been moved to their respective module files
    # This file now only contains global/non-module options

    headless = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "disable all gui related stuff";
    };

    greeter = mkOption {
      type = types.enum ["autologin" "sddm" "yawn" "none"];
      default = "none";
      description = "which greeter to use (requires greetd.enable = true)";
    };
  };
}
