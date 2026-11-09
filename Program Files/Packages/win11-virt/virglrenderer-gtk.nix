{virglrenderer}:
virglrenderer.overrideAttrs (old: {
  pname = "virglrenderer-win11-yttrium-gtk-cursor";
  patches =
    (old.patches or [])
    ++ [
      ./patches/cursor-rgba.patch
    ];
})
