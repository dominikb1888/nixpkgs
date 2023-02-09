#!/bin/bash
nix build .#homeConfigurations.malo.activationPackage
#sudo mkdir /home/dominikb1888
# sudo ln -s /home/code/.nix-profile /home/dominikb1888/.nix-profile
./result/activate
exec fish
