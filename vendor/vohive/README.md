# VoHive offline source

This directory pins the source used by the local Nix package:

- Project: `FaLao2011/vohive-next`
- Version: `1.6.0`
- Commit: `d96df01a4f6fa8cc6660e018c26676e42435943d`
- Archive: `vohive-next-1.6.0-d96df01.tar.gz`
- SHA-256: `140e990136373ecd5c5f9b5c9946be228adafb04047c0743c01d848bc91c05d7`
- License: PolyForm Noncommercial 1.0.0

The archive was created without `.git` metadata, with sorted entries, fixed
ownership, and the commit timestamp as its modification time. The package
definition pins the npm and Go dependency sets independently. The local package
also applies safety patches: rejecting the disclaimer logs out instead of
deleting local state, the destructive uninstall API returns HTTP 403, and QMI
uses the packaged `libqmi` proxy instead of the non-NixOS
`/usr/libexec/qmi-proxy` path.

After building the package, `offline/` contains an exported Nix closure and a
manifest. Import that closure on another x86_64 NixOS host before evaluating a
configuration that enables the VoHive module:

```sh
nix-store --import < offline/vohive-next-1.6.0-x86_64-linux.nar-export
```

The target still needs a working local NixOS/nixpkgs configuration; the export
removes the need to download or rebuild VoHive itself.
