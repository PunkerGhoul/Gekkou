{ pkgs }:

with pkgs;

rustPlatform.buildRustPackage rec {
  pname = "eww";
  version = "0.6.0-unstable-2025-06-30";

  src = fetchFromGitHub {
    owner = "elkowar";
    repo = "eww";
    rev = "fddb4a09b107237819e661151e007b99b5cab36d";
    hash = "sha256-PJW4LvW9FmkG9HyUtgXOq7MDjYtBc/iJuOxyf29nD0Y=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  nativeBuildInputs = [ installShellFiles pkg-config wrapGAppsHook3 ];
  buildInputs = [
    gtk3
    gtk-layer-shell
    libdbusmenu-gtk3
    librsvg
    libxkbcommon
  ];

  buildAndTestSubdir = "crates/eww";

  cargoBuildFlags = [
    "--no-default-features"
    "--features" "wayland"
    "--bin" "eww"
    "--frozen"
  ];
  cargoTestFlags = cargoBuildFlags;

  postInstall = ''
    if [ -x $out/bin/eww ]; then
      installShellCompletion --cmd eww \
        --bash <($out/bin/eww shell-completions --shell bash) \
        --fish <($out/bin/eww shell-completions --shell fish) \
        --zsh <($out/bin/eww shell-completions --shell zsh) || true
    fi
  '';

  RUSTC_BOOTSTRAP = 1;
  doCheck = false;

  meta = with lib; {
    description = "Eww (Wayland build; workspace subcrate; lockfile-based)";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "eww";
  };
}

