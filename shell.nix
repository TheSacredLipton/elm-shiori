with (import <nixpkgs> { });
mkShell {
  buildInputs = [
    mask
    nodejs-16_x
    elmPackages.elm
    elmPackages.elm-test
    elmPackages.elm-format
    elmPackages.elm-verify-examples
  ];
  shellHook = ''
  '';
}
