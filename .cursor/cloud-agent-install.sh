#!/usr/bin/env bash
# Cloud Agent bootstrap for ergentics-foundations.
# Pins the toolchain the main-branch check uses: Rust 1.83.0 and Swift 6.2.4
# (the swift:6.2 image). Swift comes from the Linux swiftly installer on
# https://www.swift.org/install/linux/. Does not start services.
set -euo pipefail

SWIFT_VERSION="6.2.4"
# Swift Automatic Signing Key #4, published in https://www.swift.org/keys/all-keys.asc.
# It signs the swiftly tarball. swiftly --verify checks the toolchain signature.
SWIFTLY_KEY="E813C892820A6FA13755B268F167DF1ACF9CE069"
KEY_URL="https://www.swift.org/keys/all-keys.asc"
export SWIFTLY_HOME_DIR="/opt/swiftly"
export SWIFTLY_BIN_DIR="${SWIFTLY_HOME_DIR}/bin"
export SWIFTLY_TOOLCHAINS_DIR="${SWIFTLY_HOME_DIR}/toolchains"
SWIFT_BIN="${SWIFTLY_TOOLCHAINS_DIR}/${SWIFT_VERSION}/usr/bin/swift"
SWIFTC_BIN="${SWIFTLY_TOOLCHAINS_DIR}/${SWIFT_VERSION}/usr/bin/swiftc"

export DEBIAN_FRONTEND=noninteractive

# The image already carries the Swift runtime libraries. apt on this network
# answers 403 for archive.ubuntu.com, so a failed update must not hide a
# toolchain that can still run.
if sudo apt-get update -qq; then
  sudo apt-get install -y -qq --no-install-recommends \
    binutils \
    ca-certificates \
    curl \
    git \
    gnupg2 \
    libc6-dev \
    libcurl4-openssl-dev \
    libedit2 \
    libgcc-13-dev \
    libncurses-dev \
    libpython3-dev \
    libsqlite3-0 \
    libstdc++-13-dev \
    libxml2-dev \
    libz3-dev \
    pkg-config \
    tzdata \
    unzip \
    zlib1g-dev
else
  echo "apt update failed; using libraries already installed on the image" >&2
fi

if ! command -v rustup >/dev/null 2>&1 || ! command -v rustc >/dev/null 2>&1; then
  echo "rustup and rustc 1.83.0 must already be on PATH" >&2
  exit 1
fi

rustc_version="$(rustc --version)"
case "$rustc_version" in
  "rustc 1.83.0 "*) ;;
  *)
    echo "expected rustc 1.83.0, found: ${rustc_version}" >&2
    exit 1
    ;;
esac

added=0
for _attempt in 1 2 3 4 5; do
  if rustup target add wasm32-unknown-unknown; then
    added=1
    break
  fi
  sleep $(( _attempt * 2 ))
done
if [[ "$added" != 1 ]]; then
  echo "rustup target add wasm32-unknown-unknown failed" >&2
  exit 1
fi

# archive.ubuntu.com answers 403 here, so libncurses6 cannot be installed.
# swift-driver only needs the tinfo symbols that libncurses.so.6 re-exports,
# and those symbols are already in libtinfo.so.6. lldb also wants libpanel
# and libform; swift test does not.
if [[ ! -e /usr/lib/x86_64-linux-gnu/libncurses.so.6 && -e /usr/lib/x86_64-linux-gnu/libtinfo.so.6 ]]; then
  sudo ln -sfn libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.6
fi

if ! "$SWIFT_BIN" --version 2>/dev/null | grep -q "Swift version ${SWIFT_VERSION}"; then
  arch="$(uname -m)"
  case "$arch" in
    x86_64|aarch64) ;;
    *)
      echo "swiftly has no build for ${arch}" >&2
      exit 1
      ;;
  esac
  work="$(mktemp -d)"
  trap 'rm -rf "$work"' EXIT
  curl_retry() {
    local attempt
    for attempt in 1 2 3 4 5; do
      if curl --retry 5 --retry-all-errors --retry-delay 2 "$@"; then
        return 0
      fi
      sleep $(( attempt * 3 ))
    done
    return 1
  }
  tarball="swiftly-${arch}.tar.gz"
  tarball_url="https://download.swift.org/swiftly/linux/${tarball}"
  curl_retry -fsSL "$tarball_url" -o "${work}/${tarball}"
  curl_retry -fsSL "${tarball_url}.sig" -o "${work}/${tarball}.sig"
  curl_retry --compressed -fsSL "$KEY_URL" -o "${work}/all-keys.asc"
  export GNUPGHOME="${work}/gnupg"
  mkdir -p "$GNUPGHOME"
  chmod 700 "$GNUPGHOME"
  gpg --batch --import "${work}/all-keys.asc"
  gpg --batch --list-keys "$SWIFTLY_KEY" >/dev/null
  gpg --batch --status-fd 1 --verify "${work}/${tarball}.sig" "${work}/${tarball}" \
    > "${work}/verify.txt"
  if ! grep -q "VALIDSIG ${SWIFTLY_KEY}" "${work}/verify.txt"; then
    echo "swiftly signature did not match ${SWIFTLY_KEY}" >&2
    cat "${work}/verify.txt" >&2
    exit 1
  fi
  tar -xzf "${work}/${tarball}" -C "$work"
  sudo mkdir -p "$SWIFTLY_HOME_DIR"
  sudo chown -R "$(id -u):$(id -g)" "$SWIFTLY_HOME_DIR"
  # The install page runs `swiftly init`, which selects the newest release
  # (6.4.1 on that page). This repo's check uses the swift:6.2 image, so init
  # only lays down swiftly and `swiftly install 6.2.4` selects that toolchain.
  "${work}/swiftly" init --quiet-shell-followup --skip-install --no-modify-profile --assume-yes
  # shellcheck disable=SC1091
  . "${SWIFTLY_HOME_DIR}/env.sh"
  hash -r
  set +e
  swiftly install "$SWIFT_VERSION" --use --verify --assume-yes
  install_status=$?
  set -e
  if ! "$SWIFT_BIN" --version 2>/dev/null | grep -q "Swift version ${SWIFT_VERSION}"; then
    echo "swiftly install ${SWIFT_VERSION} failed (exit ${install_status})" >&2
    exit 1
  fi
  sudo chmod -R a+rX "$SWIFTLY_HOME_DIR"
  rm -rf "$work"
  trap - EXIT
fi

sudo ln -sfn "$SWIFT_BIN" /usr/local/bin/swift
sudo ln -sfn "$SWIFTC_BIN" /usr/local/bin/swiftc
sudo tee /usr/local/bin/swiftly >/dev/null <<'EOF'
#!/bin/sh
export SWIFTLY_HOME_DIR=/opt/swiftly
export SWIFTLY_BIN_DIR=/opt/swiftly/bin
export SWIFTLY_TOOLCHAINS_DIR=/opt/swiftly/toolchains
exec /opt/swiftly/bin/swiftly "$@"
EOF
sudo chmod 755 /usr/local/bin/swiftly

hash -r
swift --version | grep -q "Swift version ${SWIFT_VERSION}"

missing="$( { ldd "$SWIFT_BIN" "$SWIFTC_BIN" | awk '/not found/ { print }'; } || true )"
if [[ -n "$missing" ]]; then
  echo "Swift is missing shared libraries:" >&2
  echo "$missing" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "${repo_root}/rust/commitment-reader/Cargo.lock" ]]; then
  fetched=0
  for _attempt in 1 2 3; do
    if cargo fetch --locked --manifest-path "${repo_root}/rust/commitment-reader/Cargo.toml"; then
      fetched=1
      break
    fi
    sleep 2
  done
  if [[ "$fetched" != 1 ]]; then
    echo "cargo fetch failed; Swift and Rust toolchains are still installed" >&2
  fi
fi
