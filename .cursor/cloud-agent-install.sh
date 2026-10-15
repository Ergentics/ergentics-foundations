#!/usr/bin/env bash
# Cloud Agent bootstrap for ergentics-foundations.
# Pins the toolchain the main-branch check uses: Rust 1.83.0 and Swift 6.2.4
# (the swift:6.2 image). Does not start services.
set -euo pipefail

SWIFT_VERSION="6.2.4"
SWIFT_TAG="swift-${SWIFT_VERSION}-RELEASE"
SWIFT_BRANCH="swift-${SWIFT_VERSION}-release"
SWIFT_PLATFORM="ubuntu24.04"
SWIFT_KEY="52BB7E3DE28A71BE22EC05FFEF80A866B47A981F"
SWIFT_ROOT="/opt/${SWIFT_TAG}"
TARBALL="${SWIFT_TAG}-${SWIFT_PLATFORM}.tar.gz"
TARBALL_URL="https://download.swift.org/${SWIFT_BRANCH}/ubuntu2404/${SWIFT_TAG}/${TARBALL}"
KEY_URL="https://www.swift.org/keys/all-keys.asc"

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

rustup target add wasm32-unknown-unknown

# archive.ubuntu.com answers 403 here, so libncurses6 cannot be installed.
# swift-driver only needs the tinfo symbols that libncurses.so.6 re-exports,
# and those symbols are already in libtinfo.so.6. lldb also wants libpanel
# and libform; swift test does not.
if [[ ! -e /usr/lib/x86_64-linux-gnu/libncurses.so.6 && -e /usr/lib/x86_64-linux-gnu/libtinfo.so.6 ]]; then
  sudo ln -sfn libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.6
fi

if ! "${SWIFT_ROOT}/usr/bin/swift" --version 2>/dev/null | grep -q "Swift version ${SWIFT_VERSION}"; then
  work="$(mktemp -d)"
  trap 'rm -rf "$work"' EXIT
  curl -fsSL "$TARBALL_URL" -o "${work}/${TARBALL}"
  curl -fsSL "${TARBALL_URL}.sig" -o "${work}/${TARBALL}.sig"
  curl --compressed -fsSL "$KEY_URL" -o "${work}/all-keys.asc"
  export GNUPGHOME="${work}/gnupg"
  mkdir -p "$GNUPGHOME"
  chmod 700 "$GNUPGHOME"
  gpg --batch --import "${work}/all-keys.asc"
  gpg --batch --list-keys "$SWIFT_KEY" >/dev/null
  gpg --batch --status-fd 1 --verify "${work}/${TARBALL}.sig" "${work}/${TARBALL}" \
    > "${work}/verify.txt"
  if ! grep -q "VALIDSIG ${SWIFT_KEY}" "${work}/verify.txt"; then
    echo "Swift signature did not match ${SWIFT_KEY}" >&2
    cat "${work}/verify.txt" >&2
    exit 1
  fi
  sudo rm -rf "$SWIFT_ROOT"
  sudo mkdir -p "$SWIFT_ROOT"
  sudo tar -xzf "${work}/${TARBALL}" -C "$SWIFT_ROOT" --strip-components=1
  sudo chmod -R a+rX "$SWIFT_ROOT"
  rm -rf "$work"
  trap - EXIT
fi

sudo ln -sfn "${SWIFT_ROOT}/usr/bin/swift" /usr/local/bin/swift
sudo ln -sfn "${SWIFT_ROOT}/usr/bin/swiftc" /usr/local/bin/swiftc

swift --version | grep -q "Swift version ${SWIFT_VERSION}"

missing="$( { ldd "${SWIFT_ROOT}/usr/bin/swift" "${SWIFT_ROOT}/usr/bin/swiftc" | awk '/not found/ { print }'; } || true )"
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
