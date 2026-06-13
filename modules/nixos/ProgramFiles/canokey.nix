{pkgs, ...}: {
  boot.initrd.systemd.fido2.enable = true;
  boot.initrd.luks.devices."cryptroot".crypttabExtraOpts = [
    "fido2-device=auto"
  ];

  security.pam.u2f = {
    control = "sufficient";
    settings = {
      cue = true;
      userpresence = 1;
      pinverification = 0;
    };
  };

  security.pam.services.kde.u2f.enable = true;
  security.pam.services.sudo.u2f.enable = true;

  environment.systemPackages = with pkgs; [
    libfido2
    pam_u2f
  ];
}
