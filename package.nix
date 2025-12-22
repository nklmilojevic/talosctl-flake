{
  lib,
  stdenv,
  fetchurl,
  installShellFiles,
}:
let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  platform = sources.platforms.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "talosctl";
  version = sources.version;

  src = fetchurl {
    url = platform.url;
    hash = platform.hash;
  };

  nativeBuildInputs = [ installShellFiles ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -m755 -D $src $out/bin/talosctl
    runHook postInstall
  '';

  postInstall = ''
    installShellCompletion --cmd talosctl \
      --bash <($out/bin/talosctl completion bash) \
      --zsh <($out/bin/talosctl completion zsh) \
      --fish <($out/bin/talosctl completion fish)
  '';

  meta = {
    description = "CLI for Talos Linux - the Kubernetes operating system";
    homepage = "https://www.talos.dev/";
    license = lib.licenses.mpl20;
    maintainers = [ ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "talosctl";
  };
}
