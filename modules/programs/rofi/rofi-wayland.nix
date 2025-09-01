{ pkgs }:

with pkgs;

stdenv.mkDerivation rec {
  pname = "rofi-wayland";
  version = "1.7.5+wayland3";

  src = fetchFromGitHub {
    owner = "lbonn";
    repo = "rofi";
    rev = "1.7.5+wayland3";
    hash = "sha256-pKxraG3fhBh53m+bLPzCigRr6dBcH/A9vbdf67CO2d8=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    flex
    bison
    wayland-scanner
    wrapGAppsHook3
    cmake
  ];

  buildInputs = [
    cairo
    glib
    libxkbcommon
    pango
    wayland
    wayland-protocols
    libxcb
    xcbutilxrm
    libstartup_notification
    librsvg
    check
    gdk-pixbuf
    libxml2
    libnl
    alsa-lib
    libmpdclient
    xorg.xcbutil
    xorg.xcbutilwm
    xorg.xcbutilcursor
  ];

  mesonFlags = [
    "-Dxcb=enabled"
  ];

  doCheck = false;

  meta = with lib; {
    description = "Rofi - Window switcher, run dialog and dmenu replacement (Wayland fork)";
    homepage = "https://github.com/lbonn/rofi";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "rofi";
  };
}
