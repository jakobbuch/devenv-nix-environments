{
  pkgs,
  lib,
  config,
  ...
}:

let
  buildPackages = with pkgs; [
    stdenv.cc
  ];
in
{
  # https://devenv.sh/packages/
  packages =
    with pkgs;
    [
      hello
      docker-compose
    ]
    ++ buildPackages;

  # https://devenv.sh/scripts/
  scripts = {
    # bifrost aliases
    bifrostStart = {
      exec = ''
        docker compose -f databases.yml up -d ; docker compose -f docker-compose.yml up -d
      '';
      description = "Start all bifrost docker containers";
    };

    bifrostStartAndBuild = {
      exec = ''
        docker compose -f databases.yml up -d ; docker compose -f docker-compose.yml up -d --build
      '';
      description = "Start all bifrost docker containers and build them";
    };

    bifrostStop = {
      exec = ''
        docker compose -f databases.yml down ; docker compose down
      '';
      description = "Stop all bifrost docker containers";
    };

    bifrostRestart = {
      exec = ''
        bifrostStop && bifrostStart
      '';
      description = "Restart all bifrost docker containers";
    };

    bifrostRestartAndBuild = {
      exec = ''
        bifrostStop && bifrostStartAndBuild
      '';
      description = "Restart all bifrost docker containers and build them";
    };

    bifrostUpdate = {
      exec = ''
        docker compose -f databases.yml pull ; docker compose pull
      '';
      description = "Update all bifrost docker containers";
    };

    bifrostRunsClean = {
      exec = ''
        docker compose -f databases.yml down -v ; docker compose down -v
      '';
      description = "Delete all runs by removing all volumes";
    };

    bifrostSettlementClean = {
      exec = ''
        bifrostRunsClean ; rm -rf user_data/bifrost/*
      '';
      description = "Delete all settlements by deleting the user_data, use when adding new dynamics";
    };

    bifrostBuildingJsonClean = {
      exec = ''
        rm -rf user_data/building_data/json_files_store/* ; rm -rf user_data/building_data/json_files_temp/*
      '';
      description = "Delete all building model jsons";
    };

    bifrostWeatherCsvClean = {
      exec = ''
        rm -f user_data/weather_data/climate_data* ; rm -f user_data/weather_config/weather/climate_data*
      '';
      description = "Delete climate_data* weather files";
    };

    bifrostFullClean = {
      exec = ''
        bifrostSettlementClean ; bifrostBuildingJsonClean ; bifrostWeatherCsvClean
      '';
      description = "Delete all bifrost data for a clean setup, beware weather data and building jsons are deleted";
    };

    dockerCleanup = {
      exec = ''
        docker system prune -af --volumes
      '';
      description = "Remove all unused Docker data";
    };
  };

  enterShell = ''
    hello
    echo
    echo "Helper scripts:"
    ${pkgs.gnused}/bin/sed -e 's| |••|g' -e 's|=| |' <<EOF | ${pkgs.util-linuxMinimal}/bin/column -t | ${pkgs.gnused}/bin/sed -e 's|^| |' -e 's|••| |g'
    ${lib.generators.toKeyValue { } (lib.mapAttrs (name: value: value.description) config.scripts)}
    EOF
    echo
  '';
}
