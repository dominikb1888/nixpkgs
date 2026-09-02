{
  stdenv,
  fetchFromGitHub,
  nodejs_24,
  pnpm,
  pnpmConfigHook,
  fetchPnpmDeps,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "toon-cli";
  version = "2026-09-01";

  src = fetchFromGitHub {
    owner = "toon-format";
    repo = "toon";
    rev = "main";
    hash = "sha256-VPYP84gTXbqpLh9aO8tgrlqLJC3X/N1+XxAJpP4fVg0=";
  };

  nativeBuildInputs = [
    nodejs_24
    pnpm
    pnpmConfigHook
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 4;
    hash = "sha256-1UzOVz6uaU2eHPYGhIfkooZf8SPpV5SIzg8cfga158Q=";
  };

  # Pass the root directory as an environment variable to prevent tools from dropping context
  PREreg_ROOT = "./";

  buildPhase = ''
    runHook preBuild

    # Explicitly build inside the package workspace path rather than relying on global filters
    cd packages/cli
    pnpm run build --config ../../tsdown.config.ts --entry src/index.ts
    cd ../../

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    # Match where tsdown emitted the distribution folder inside the workspace path
    if [ -f "packages/cli/dist/index.js" ]; then
      cp packages/cli/dist/index.js $out/bin/toon
    elif [ -f "packages/cli/dist/index.mjs" ]; then
      cp packages/cli/dist/index.mjs $out/bin/toon
    else
      echo "Build artifacts missing! Listing directory tree:"
      find packages/cli -maxdepth 3
      exit 1
    fi

    chmod +x $out/bin/toon
    sed -i '1s|^|#!/usr/bin/env node\n|' $out/bin/toon

    runHook postInstall
  '';
})
