{
  fetchFromGitHub,
  virglrenderer,
}:
virglrenderer.overrideAttrs (old: {
  pname = "virglrenderer-win11-yttrium";
  src = fetchFromGitHub {
    owner = "arehnman";
    repo = "virglrenderer";
    rev = "3d681c0a1a25694d20f655e95a2f95e70b62e7c6";
    sha256 = "13c4kfl80rqz0fx2v2ifl08784wqlx0df1y8q3bz1a37yahgikqg";
  };
  patches = [];
  postPatch =
    (old.postPatch or "")
    + ''
      substituteInPlace src/proxy/proxy_server.c \
        --replace-fail '      setpgid(0, 0);' '      /* libvirt seccomp denies setpgid. */'
    '';
})
