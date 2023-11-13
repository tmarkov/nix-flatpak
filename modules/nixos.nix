{ config, lib, pkgs, ... }:
let
  cfg = config.services.flatpak.nix-flatpak;
  installation = "system";
in
{
  options.services.flatpak.nix-flatpak = import ./options.nix { inherit cfg lib pkgs; };

  config = lib.mkIf cfg.enable {
    asserttions = [{
      assertion = config.services.flatpak.enable;
      text = "services.flatpak.enable must be true when enabling nix-flatpak";
    }];
    systemd.services."flatpak-managed-install" = {
      wants = [
        "network-online.target"
      ];
      wantedBy = [
        "multi-user.target"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${import ./installer.nix {inherit cfg pkgs lib; installation = installation; }}";
      };
    };
    systemd.timers."flatpak-managed-install" = lib.mkIf cfg.update.auto.enable {
      timerConfig = {
        Unit = "flatpak-managed-install";
        OnCalendar = "${cfg.update.auto.onCalendar}";
        Persistent = "true";
      };
      wantedBy = [ "timers.target" ];
    };
  };
}
