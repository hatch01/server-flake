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

    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = {
    flake-parts,
    nixpkgs,
    agenix,
    deploy-rs,
    disko,
    impermanence,
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
            modules = [
              ./configuration.nix
              ./disko.nix
              agenix.nixosModules.default
              disko.nixosModules.disko
              impermanence.nixosModules.impermanence
            ];
            specialArgs = {
              inherit inputs hostName;
            };
          };
        };
        deploy.nodes.jonquille = {
          hostname = "onyx.ovh";
          profiles.system = {
            #look at how not to use ssh root login but pass via sudo
            user = "root";
            sshUser = "root";
            remoteBuild = true; # think on it if it is a great option
            autoRollback = false;
            magicRollback = false;
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
