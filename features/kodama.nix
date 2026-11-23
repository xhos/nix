{inputs, ...}: {
  # kodama is a private repo on the tailnet-only forgejo ssh. hosts that don't
  # import this never touch the input, so they don't need to be able to fetch it
  flake.modules.nixos.kodama = {
    imports = [inputs.kodama.nixosModules.default];
    # mk-nixos-system leaves kodama out of its pinned inputs, pin it here instead
    system.extraDependencies = [inputs.kodama];
  };
}
