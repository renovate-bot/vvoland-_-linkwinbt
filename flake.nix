# SPDX-License-Identifier: BSD-3-Clause

{
  description = "Share Bluetooth pairing keys between Windows and Linux";

  inputs.nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = self.packages.${system}.linkwinbt;
          linkwinbt = pkgs.buildGoModule {
            pname = "linkwinbt";
            version = "unstable";
            src = self;

            # Dependencies are checked into vendor/.
            vendorHash = null;
            subPackages = [ "cmd/linkwinbt" ];
            env.CGO_ENABLED = 0;
            ldflags = [
              "-s"
              "-w"
            ];

            nativeBuildInputs = [ pkgs.makeWrapper ];
            postInstall = ''
              wrapProgram "$out/bin/linkwinbt" \
                --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.chntpw ]}
            '';

            checkPhase = ''
              runHook preCheck
              go test ./...
              runHook postCheck
            '';

            meta = {
              description = "Share Bluetooth pairing keys between Windows and Linux";
              homepage = "https://github.com/vvoland/linkwinbt";
              license = pkgs.lib.licenses.bsd3;
              mainProgram = "linkwinbt";
              platforms = systems;
            };
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.go
              pkgs.chntpw
            ];
          };
        }
      );
    };
}
