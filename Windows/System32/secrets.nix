{repoRoot, ...}: {
  # Keep the system PQ identity ready for future system secrets.
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  # Install secrets via a systemd unit (sysinit.target) so other systemd
  # services can declare an explicit ordering dependency on them.
  sops.useSystemdActivation = true;

  # VeraCrypt keyfile for the HHD volume. Binary secret; the whole
  # ProgramData/SOPS/system.json document decrypts to the raw keyfile.
  # Re-encrypt with: sops --input-type binary --output-type json -e -i ...
  # Root-only: the veracrypt-hhd service reads it as root.
  sops.secrets.veracrypt-hhd-keyfile = {
    sopsFile = repoRoot + "/ProgramData/SOPS/system.json";
    format = "binary";
    mode = "0400";
    owner = "root";
    group = "root";
  };
}
