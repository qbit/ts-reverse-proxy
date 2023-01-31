{
  description = "ts-reverse-proxy: a TailScale aware reverse proxy";

  inputs.nixpkgs.url = "nixpkgs/nixos-22.11";

  outputs = { self, nixpkgs }:
    let
      supportedSystems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in {
      overlay = final: prev: {
        ts-reverse-proxy = self.packages.${prev.system}.ts-reverse-proxy;
      };
      packages = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          ts-reverse-proxy = pkgs.buildGoModule {
            pname = "ts-reverse-proxy";
            version = "v0.0.0";
            src = ./.;

            vendorSha256 = "sha256-QcuL7qjNTloLBYnT2pZtYDZlj2/qm8sNS7EUVBbCp7U=";
            proxyVendor = true;
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
            '';
            nativeBuildInputs = with pkgs; [ git go gopls go-tools ];
          };
        });
    };
}

