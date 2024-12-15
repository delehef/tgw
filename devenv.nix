{ pkgs, lib, config, inputs, ... }:

let
  db = {
    user = "tgw";
    password = "asdf";
    dbName = "tgw_dev";
  };
in
{
  cachix.enable = false;

  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = [ pkgs.git pkgs.protobuf pkgs.erlang ];

  # https://devenv.sh/languages/
  languages.elixir.enable = true;

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  services = {
    postgres = {
      enable = true;
      listen_addresses = "127.0.0.1";
      initialScript = ''
    CREATE ROLE ${db.user} WITH PASSWORD '${db.password}' SUPERUSER LOGIN;
    '';
      initialDatabases = [ { name = db.dbName; } ];
    };
  };

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
