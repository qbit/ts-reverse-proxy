{
  description = "ts-reverse-proxy: a TailScale aware reverse proxy";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs = { self, nixpkgs }:
    let
      supportedSystems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in {
      overlay = final: prev: {
        inherit (self.packages.${prev.system}) ts-reverse-proxy;
      };
      packages = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          ts-reverse-proxy = pkgs.buildGo121Module {
            pname = "ts-reverse-proxy";
            version = "v1.0.1";
            src = ./.;

            vendorSha256 = "sha256-DmmEXXXi+19+OcW6DTQ2bCbebIldDdkMRjvm6Dp3Df0=";
          };
        });

      defaultPackage = forAllSystems (system: self.packages.${system}.ts-reverse-proxy);
      devShells = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          default = pkgs.mkShell {
            shellHook = ''
              PS1='\u@\h:\@; '
              echo "Go `${pkgs.go}/bin/go version`"
              nix run github:qbit/xin#flake-warn
            '';
            nativeBuildInputs = with pkgs; [ git go_1_21 gopls go-tools graphviz ];
          };
        });
    };
}

