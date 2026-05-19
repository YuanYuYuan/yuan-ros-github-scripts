{
  description = "ROS GitHub management scripts";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      py = pkgs.python3;

      rosGithubScripts = py.pkgs.buildPythonPackage {
        pname = "ros-github-scripts";
        version = "0.1.0";
        src = ./.;
        pyproject = true;
        build-system = with py.pkgs; [ setuptools ];
        propagatedBuildInputs = with py.pkgs; [
          markdown2
          pygithub
          pyyaml
          retrying
          jenkinsapi
        ];
        doCheck = false;
      };
    in
    {
      packages.${system}.default = rosGithubScripts;

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          (py.withPackages (ps: with ps; [
            markdown2
            pygithub
            pyyaml
            retrying
            jenkinsapi
            # dev/test extras
            pytest
            flake8
            mypy
          ]))
        ];

        shellHook = ''
          # Install the package in editable mode so entry points work
          pip install -e . --quiet --no-deps 2>/dev/null

          # Load GITHUB_ACCESS_TOKEN from local token file if not already set
          if [ -z "''${GITHUB_ACCESS_TOKEN:-}" ] && [ -f "''${PWD}/GITHUB_TOKEN.txt" ]; then
            export GITHUB_ACCESS_TOKEN=$(cat "''${PWD}/GITHUB_TOKEN.txt")
            echo "GITHUB_ACCESS_TOKEN loaded from GITHUB_TOKEN.txt"
          fi
        '';
      };
    };
}
