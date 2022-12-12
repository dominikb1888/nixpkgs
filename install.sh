#!/bin/bash
nix build .#homeConfigurations.malo.activationPackage
./result/activate

