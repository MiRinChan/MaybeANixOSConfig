{qemu_kvm}:
qemu_kvm.overrideAttrs (old: {
  pname = "qemu-win11-yttrium";
  patches =
    (old.patches or [])
    ++ [
      ./patches/qemu/01-cf3bba5c2.patch
      ./patches/qemu/02-91f31718d.patch
      ./patches/qemu/03-4954f0ef7.patch
      ./patches/qemu/04-a4972911a.patch
      ./patches/qemu/05-064f4b3c4.patch
      ./patches/qemu/06-84b5a7928.patch
      ./patches/qemu/07-a9d187ddb.patch
      ./patches/qemu/08-a58f028f3.patch
      ./patches/qemu/09-b35c7394e.patch
      ./patches/qemu/10-2849a6815.patch
      ./patches/qemu/11-ee2236d93.patch
      ./patches/qemu/12-afa64844d.patch
      ./patches/qemu/13-3001a0746.patch
    ];
})
