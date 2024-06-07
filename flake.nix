{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    agenix,
    deploy-rs,
    disko,
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
    hostName = "onyx.ovh";
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [system];

      flake = {
        nixosConfigurations = {
          jonquille = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [./configuration.nix ./disko.nix agenix.nixosModules.default disko.nixosModules.disko];
            specialArgs = {
              inherit inputs hostName;
            };
          };
        };
        deploy.nodes.jonquille = {
          hostname = "192.168.122.47"; #TODO change this to point to the real domain name
          profiles.system = {
            user = "root";
            sshUser = "eymeric";
            # remoteBuild = true; # think on it if it is a great option
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
