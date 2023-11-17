{
  description = "ts-reverse-proxy: a TailScale aware reverse proxy";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs = { self, nixpkgs }:
    let
      goVer = "_1_21";
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
        buildGoModule = pkgs.buildGo121Module;
        in {
          ts-reverse-proxy = buildGoModule {
            pname = "ts-reverse-proxy";
            version = "v1.0.3";
            src = ./.;

            vendorHash = "sha256-gRj6rSZqyMbQB4VRQuOT/jQKcKNR11igvuVt/Bv1zqM=";
          };
        });

      defaultPackage = forAllSystems (system: self.packages.${system}.ts-reverse-proxy);
      devShells = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        go = pkgs."go${goVer}";
        in {
          default = pkgs.mkShell {
            shellHook = ''
              PS1='\u@\h:\@; '
              echo "Go `${go}/bin/go version`"
              nix run github:qbit/xin#flake-warn
            '';
            nativeBuildInputs = with pkgs; [ git go gopls go-tools graphviz ];
          };
        });
    };
}

