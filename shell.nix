scope@{ pkgs ? import <nixpkgs> { } }:

let
  locale = "en_US.UTF8";
in with pkgs;
llvmPackages_14.stdenv.mkDerivation {
  name = "linkerd-proxy-shell";

  buildInputs = [
    (glibcLocales.override { locales = [ locale ]; })
    bash
    bashInteractive
    binutils
    cacert
    cmake
    direnv
    docker
    git
    go
    just
    k3d
    kind
    kubectl
    kubernetes-helm
    nodejs
    openssl
    pkg-config
    protobuf
    rustup
    shellcheck
    stdenv
    # vscode
  ] ++ lib.optional stdenv.isDarwin [ Security libiconv ];

  shellHook = ''
    # set up a shorter alias for kubectl.
    alias k="kubectl"

    # load completions for kubectl and k3d into the shell.
    source <(kubectl completion bash)
    source <(k3d completion bash)

    # install the devcontainer cli, and add it to the PATH.
    npm install @devcontainers/cli
    export PATH="$PATH:`pwd`/node_modules/@devcontainers/cli"

    # From: https://github.com/NixOS/nixpkgs/blob/1fab95f5190d087e66a3502481e34e15d62090aa/pkgs/applications/networking/browsers/firefox/common.nix#L247-L253
    # Set C flags for Rust's bindgen program. Unlike ordinary C
    # compilation, bindgen does not invoke $CC directly. Instead it
    # uses LLVM's libclang. To make sure all necessary flags are
    # included we need to look in a few places.
    export BINDGEN_EXTRA_CLANG_ARGS="$(< ${stdenv.cc}/nix-support/libc-crt1-cflags) \
          $(< ${stdenv.cc}/nix-support/libc-cflags) \
          $(< ${stdenv.cc}/nix-support/cc-cflags) \
          $(< ${stdenv.cc}/nix-support/libcxx-cxxflags) \
          ${
            lib.optionalString stdenv.cc.isClang
            "-idirafter ${stdenv.cc.cc}/lib/clang/${
              lib.getVersion stdenv.cc.cc
            }/include"
          } \
          ${
            lib.optionalString stdenv.cc.isGNU
            "-isystem ${stdenv.cc.cc}/include/c++/${
              lib.getVersion stdenv.cc.cc
            } -isystem ${stdenv.cc.cc}/include/c++/${
              lib.getVersion stdenv.cc.cc
            }/${stdenv.hostPlatform.config} -idirafter ${stdenv.cc.cc}/lib/gcc/${stdenv.hostPlatform.config}/${
              lib.getVersion stdenv.cc.cc
            }/include"
          } \
        "
  '';

  PROTOC = "${protobuf}/bin/protoc";
  PROTOC_INCLUDE = "${protobuf}/include";

  LOCALE_ARCHIVE = "${glibcLocales}/lib/locale/locale-archive";
  LC_ALL = "en_US.UTF-8";

  SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  NIX_SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  GIT_SSL_CAINFO = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  CURL_CA_BUNDLE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

  CARGO_TERM_COLOR = "always";
  RUST_BACKTRACE = "full";
  RUSTFLAGS = "--cfg tokio_unstable";

  LIBCLANG_PATH = "${llvmPackages_14.libclang.lib}/lib";
  ASM = "${stdenv.cc}";

  OPENSSL_DIR = "${openssl.dev}";
  OPENSSL_LIB_DIR = "${openssl.out}/lib";
}
