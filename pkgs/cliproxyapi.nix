{pkgs}:
pkgs.buildGoModule rec {
  pname = "cliproxyapi";
  version = "8.0.15";

  src = pkgs.fetchFromGitHub {
    owner = "router-for-me";
    repo = "CLIProxyAPI";
    rev = "v${version}";
    hash = "sha256-eFwmHcN/NYx/wAXrWb2WbO+XA+fUilsDEW8yCNRx4+w=";
  };

  vendorHash = "sha256-r3yWkdMcM40G9jV7MxW/qNv3E9WrHavFilW24quEf+8=";
  subPackages = ["cmd/server"];
  doCheck = false;

  postInstall = "mv $out/bin/server $out/bin/cli-proxy-api";
}
