format:
	sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./disko.nix
mount:
	sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode mount ./disko.nix
