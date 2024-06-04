deploy:
	deploy

format:
	alejandra .

iso:
	nix build .#nixosConfigurations.iso.config.system.build.isoImage