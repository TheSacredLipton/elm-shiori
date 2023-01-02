with (import <nixpkgs> { });
mkShell {
  buildInputs = [
    mask
    nodejs-16_x
    nodePackages_latest.pnpm
    elmPackages.elm
    elmPackages.elm-format
  ];
  shellHook = ''
  '';
}
