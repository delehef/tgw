{ pkgs, lib, config, inputs, ... }:

{
  cachix.enable = false;
  
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = [ pkgs.git pkgs.protobuf ];

  # https://devenv.sh/languages/
  languages.elixir.enable = true;

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.hello.exec = ''
  '';

  enterShell = ''
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
  '';

  # https://devenv.sh/pre-commit-hooks/
  # pre-commit.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
