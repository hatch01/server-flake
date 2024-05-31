{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default";

    deploy-rs.url = "github:serokell/deploy-rs";

    agenix = {
      url = "github:hatch01/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.agenix.inputs.darwin.follows = "";
    };
  };

  outputs = {
    flake-parts,
    nixpkgs,
    deploy-rs,
    self,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    # Unmodified nixpkgs
    pkgs = import nixpkgs {
      inherit system;
      config = {allowUnfree = true;};
    };
    # nixpkgs with deploy-rs overlay but force the nixpkgs package
    deployPkgs = import nixpkgs {
      inherit system;
      overlays = [
        deploy-rs.overlay # or deploy-rs.overlays.default
        (self: super: {
          deploy-rs = {
            inherit (pkgs) deploy-rs;
            lib = super.deploy-rs.lib;
          };
        })
      ];
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [system];

      # replace 'joes-desktop' with your hostname here.
      flake = {
        nixosConfigurations.jonquille = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [./configuration.nix];
        };

        deploy.nodes.jonquille = {
          hostname = "eymeric.eu";
          profiles.system = {
            user = "root";
            sshUser = "eymeric";
            remoteBuild = true; # think on it if it is a great option
            path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.jonquille;
          };
        };

        # This is highly advised, and will prevent many possible mistakes
        checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
      };

      perSystem = {
        config,
        inputs',
        pkgs,
        system,
        ...
      }: {
        devShells.default = pkgs.mkShell {
          # Inherit all of the pre-commit hooks.
          buildInputs = with pkgs; [pkgs.deploy-rs just alejandra];
        };
      };
    };
}
