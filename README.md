`git clone https://github.com/hatch01/server-flake`

`cd server-flake`

`sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./disko.nix`

`sudo nixos-install --flake .#jonquille`