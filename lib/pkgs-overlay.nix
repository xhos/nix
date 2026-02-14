lib: dir: final: prev:
builtins.listToAttrs (
  lib.mapAttrsToList
  (name: _: {
    name = lib.removeSuffix ".nix" name;
    value = prev.callPackage (dir + "/${name}") {};
  })
  (lib.filterAttrs (n: v: v == "regular" && lib.hasSuffix ".nix" n)
    (builtins.readDir dir))
)
