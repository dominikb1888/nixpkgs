{ lib
, stdenv
, writeShellApplication
, gnused
, gnugrep
, jq
, coreutils
, curl
, litellm
, ollama
, omp
, herdr
, procps ? null
}:

writeShellApplication {
  name = "herdev";
  runtimeInputs = [
    coreutils
    gnused
    gnugrep
    curl
    litellm
    ollama
    omp
    herdr
    jq
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [ procps ];
  text = builtins.readFile ./herdev.sh;
}
