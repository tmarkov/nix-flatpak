{ config, lib, pkgs, ... }@args:
let
  cfg = config.services.nix-flatpak;
  installation = "user";
in
{

  options.services.nix-flatpak = (import ./options.nix args);

  config = lib.mkIf (cfg.enable) {
    systemd.user.services."flatpak-managed-install" = {
      Unit = {
        After = [
          "network.target"
        ];
      };
      Install = {
        WantedBy = [
          "default.target"
        ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${import ./installer.nix {inherit cfg pkgs lib; installation = installation; }}";
      };
    };

    systemd.user.timers."flatpak-managed-install" = lib.mkIf cfg.update.auto.enable {
      Unit.Description = "flatpak update schedule";
      Timer = {
        Unit = "flatpak-managed-install";
        OnCalendar = "${cfg.update.auto.onCalendar}";
        Persistent = "true";
      };
      Install.WantedBy = [ "timers.target" ];
    };

    home.activation = {
      start-service = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        export PATH=${lib.makeBinPath (with pkgs; [ systemd ])}:$PATH

        $DRY_RUN_CMD systemctl is-system-running -q && \
          systemctl --user start flatpak-managed-install.service || true
      '';
    };

    xdg.enable = true;
  };

}
