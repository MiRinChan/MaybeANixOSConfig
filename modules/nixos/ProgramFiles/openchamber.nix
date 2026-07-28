{pkgs, ...}: {
  systemd.services.openchamber = {
    description = "OpenChamber web interface";
    wantedBy = ["multi-user.target"];
    after = ["tailscaled.service"];
    requires = ["tailscaled.service"];
    environment = {
      OPENCODE_BINARY = "${pkgs.llm-agents.opencode}/bin/opencode";
      OPENCHAMBER_ALLOW_UNAUTHENTICATED_LAN = "true";
    };

    serviceConfig = {
      ExecStart = "${pkgs.openchamber}/bin/openchamber serve --foreground --host 100.114.5.14 --port 3000";
      Restart = "on-failure";
      RestartSec = "5s";
      User = "mirin";
      WorkingDirectory = "/home/mirin";
    };
  };
}
