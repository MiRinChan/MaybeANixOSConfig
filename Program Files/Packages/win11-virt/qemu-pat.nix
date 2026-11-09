{
  qemu,
  writeShellScriptBin,
}:
writeShellScriptBin "qemu-system-x86_64-win11" ''
  args=()
  previous=""
  for argument in "$@"; do
    if [[ "$previous" == "-accel" && "$argument" == kvm* ]]; then
      argument="$argument,honor-guest-pat=on"
    fi
    args+=("$argument")
    previous="$argument"
  done
  exec ${qemu}/bin/qemu-system-x86_64 "''${args[@]}"
''
