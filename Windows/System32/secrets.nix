{...}: {
  # Keep the system PQ identity ready for future system secrets. Do not create
  # an empty SOPS document when there is no actual secret to declare.
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
}
