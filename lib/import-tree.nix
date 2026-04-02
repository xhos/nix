{inputs}:
# no custom api yet
inputs.import-tree
# old one for future reference:
# {
#   inputs,
#   lib,
# }:
# inputs.import-tree.addAPI {
#   # import all modules from _hostname subdirectories, except modules.nix
#   forHost = self: hostname: path:
#     (self.filterNot (lib.hasSuffix "/modules.nix")) (
#       lib.optional (builtins.pathExists (path + "/core/_${hostname}")) (path + "/core/_${hostname}")
#       ++ lib.optional (builtins.pathExists (path + "/opt/_${hostname}")) (path + "/opt/_${hostname}")
#     );
# }

