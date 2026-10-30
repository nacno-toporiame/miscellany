with import <nixpkgs> {} ; # modified from the steam package.
buildFHSEnv {
  name = "run-fhs";
  meta = {
    description = "Run commands in an FHS environment, reduced from steam-run";
    mainProgram = "run-fhs";
    name = "run-fhs";
    license = lib.licenses.mit;
  };

  runScript = writeShellScript "run-fhs" ''
    if [ $# -eq 0 ]; then
      echo "Usage: run-fhs command-to-run args..." >&2
      exit 1
    fi
    exec "$@"
  '';

  multiArch = false; # NO 32-bit junk for me :/
  includeClosures = true;

  # https://gitlab.steamos.cloud/steamrt/steam-runtime-tools/-/blob/main/docs/distro-assumptions.md#command-line-tools
  targetPkgs = pkgs: with pkgs;
    [
      bash
      coreutils
      file

      # xdg-utils # calls xdg-open occasionally
      # xz
      # zenity
      gtk4 wayland

      # lsb-release # not documented, called from Big Picture
      # pciutils # not documented, complains about lspci on startup
      # usbutils # not documented, complains about lsusb on startup (needed for the 'Enter VR Mode' button to appear)

      # Steam expects it to be /sbin specifically
      # (pkgs.runCommand "sbin-ldconfig" { } ''
      #   mkdir -p $out/sbin
      #   ln -s /bin/ldconfig $out/sbin/ldconfig
      # '')

      # crashes on startup if it can't find libX11 locale files
      # (pkgs.runCommand "xorg-locale" { } ''
      #   mkdir -p $out
      #   ln -s ${xorg.libX11}/share $out/share
      # '')
    ];

  # https://gitlab.steamos.cloud/steamrt/steam-runtime-tools/-/blob/main/docs/distro-assumptions.md#shared-libraries
  multiPkgs = pkgs: with pkgs; # just as libraries. I don't support 32-bit.
    [
      glibc
      libxcrypt
      libGL

      libdrm
      libgbm
      udev
      libudev0-shim
      libva
      vulkan-loader

      # networkmanager
    ];

  profile = ''
    # udev event notifications don't work reliably inside containers.
    # SDL2 already tries to automatically detect flatpak and pressure-vessel
    # and falls back to inotify-based discovery [1]. We make SDL2 do the
    # same by telling it explicitly.
    #
    # [1] <https://github.com/libsdl-org/SDL/commit/8e2746cfb6e1f1a1da5088241a1440fd2535e321>
    export SDL_JOYSTICK_DISABLE_UDEV=1

    # This is needed for IME (e.g. iBus, fcitx5) to function correctly on non-CJK locales
    # https://github.com/ValveSoftware/steam-for-linux/issues/781#issuecomment-2004757379
    export GTK_IM_MODULE='xim'

    # See https://gitlab.steamos.cloud/steamrt/steam-runtime-tools/-/blob/main/docs/distro-assumptions.md#graphics-driver
    export LIBGL_DRIVERS_PATH=/run/opengl-driver/lib/dri
    export __EGL_VENDOR_LIBRARY_DIRS=/run/opengl-driver/share/glvnd/egl_vendor.d
    export LIBVA_DRIVERS_PATH=/run/opengl-driver/lib/dri
    export VDPAU_DRIVER_PATH=/run/opengl-driver/lib/vdpau

    set -a
    # extra environment variables
    set +a
    # Extra profile
  '';
}
