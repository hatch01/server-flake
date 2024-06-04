

` sudo nix run --extra-experimental-features 'nix-command flakes' 'github:nix-community/disko#disko-install' -- --flake 'github:hatch01/server-flake' --disk main /dev/sda`