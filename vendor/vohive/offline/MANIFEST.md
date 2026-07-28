# VoHive 1.6.0 x86_64-linux offline closure

- Package: `/nix/store/hswispjw28nvlhm28v14gsk9kv7asid9-vohive-next-1.6.0`
- Export: `vohive-next-1.6.0-x86_64-linux.nar-export`
- Export SHA-256: `e4900768143acf6c5b9a36724796d6135261f82e470637ffff10ebd679c1e45e`
- Export size: 204,183,832 bytes
- Source SHA-256: `140e990136373ecd5c5f9b5c9946be228adafb04047c0743c01d848bc91c05d7`
- npm dependency hash: `sha256-bnU4VQGVXPAyTEQjETgtj9SHzR4d+oF5O971RVfkDbY=`
- Go vendor hash: `sha256-TamCszS0ATuOu6HSkWk88pFuPf391d8ReZT6VcUv1W4=`

Import and verify:

```sh
sha256sum -c SHA256SUMS
nix-store --import < vohive-next-1.6.0-x86_64-linux.nar-export
nix-store --verify-path /nix/store/hswispjw28nvlhm28v14gsk9kv7asid9-vohive-next-1.6.0
```

The build ran the upstream Go test suite. It skips exactly three tests: one
known-failing deprecated-config migration test and two websheet tests that
require public DNS/network access inside the Nix build sandbox.

This closure includes the local safety patches that replace the destructive
disclaimer rejection flow with logout and make the authenticated uninstall API
return `403 uninstall_disabled`. It also includes `libqmi` and the NixOS QMI
patch that replaces VoHive's hard-coded `/usr/libexec/qmi-proxy` fallback with
the immutable `libqmi` store path.

Closure paths:

```text
/nix/store/dxszpyw0pn7h1cxi1y6l33nmwk7f5knn-libunistring-1.4.2
/nix/store/clqknm3pgln8pxb6n7iamffk313nr91r-libidn2-2.3.8
/nix/store/hps7pxvcgq32x46yx5a2nx53js5j41vb-xgcc-15.2.0-libgcc
/nix/store/ias8xacs1h3jy7xgwi2awvim61k2ji6c-glibc-2.42-67
/nix/store/s8bvq48mqjiw3firz3l9wx19h55vldy4-libxcrypt-4.5.2
/nix/store/4ksxs7pb2k4jbm9ivk1nyhcb9ay33irk-util-linux-minimal-2.42.2-login
/nix/store/s5n27jdfikq95618hl8x1mz9rnb9hsl8-systemd-minimal-libs-261
/nix/store/bnz12q7krhpam19qyy7my8vyy2fq9vkx-util-linux-minimal-2.42.2-lib
/nix/store/n2r7cb0l9w9wx02k2hpwgzzp5vmb216a-pcre2-10.46
/nix/store/cb5yp2g2hvx9dd40j6qx78c1778crrfi-libselinux-3.10
/nix/store/rkfkkdgwz8y31hk76i4b9s59h5raya9n-libffi-3.5.2
/nix/store/vx2aqxs99ii6pkzndddnbrsqbc4jwpb6-glib-2.88.1
/nix/store/1jcjkhs4fl8nlmsdrlzx7dcxrvxx1bzd-libgudev-238
/nix/store/1vjpl6h5av7iagcmrkzcnlskj5p2vkyk-iana-etc-20251215
/nix/store/62qhvy2m2lpqj7ca39j9wvp2kkcxwdcg-ncurses-6.6
/nix/store/3yfiiflma4rfll7fyjzk5f2k58j859jq-readline-8.3p3
/nix/store/a9b4pxh302r6c9zk9ihhiyygis1djj04-libqrtr-glib-1.2.2
/nix/store/bbzjxfam8vv1nyikn5dsrazsw4ya5vzx-bash-interactive-5.3p9
/nix/store/bzzvmj6wh8a7mqvq9i54fmvpsdxz4zqj-tzdata-2026b
/nix/store/l3y37q7npzc92hnpz6xqss0cjhzvx07p-mailcap-2.1.54
/nix/store/n0nhgw1dm9xm0ifn3zsg9xfsid9nl1zg-libmbim-1.34.0
/nix/store/v8llyqw71lygr2llhmcc8ya5bdlzq45v-bash-5.3p9
/nix/store/pk612fnr3hmax4mbk3qdpvbrh8srp6c3-libqmi-1.38.0
/nix/store/hswispjw28nvlhm28v14gsk9kv7asid9-vohive-next-1.6.0
```
