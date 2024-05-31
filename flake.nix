{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs }: {
    # replace 'joes-desktop' with your hostname here.
    nixosConfigurations.jonquille = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
    };
  };

}
