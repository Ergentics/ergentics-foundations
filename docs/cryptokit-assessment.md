# CryptoKit assessment

Decision for this maintenance line: **keep the in-tree SHA-256 on Linux. Do not add a package dependency yet.** Apple builds continue to call CryptoKit.

## What the commitment actually uses

`ChangeFoundation` hashes one thing: the explicit fixed-binary state and relation bytes, with SHA-256, written as lowercase hex. The digest is a commitment to those bytes. It is not an authority, a signature, or a password hash. No other CryptoKit API is used.

On Apple platforms the call is `CryptoKit.SHA256`. The Swift 6.4.1 Linux toolchain installed for this repository has no `CryptoKit` module. `canImport(CryptoKit)` is false there, so `InTreeSHA256` runs instead.

## Checks that pin the Linux hash

- The six original canonical vectors in `Tests/ChangeFoundationTests/vectors.json` pass on Linux. Those digests were produced by Python `hashlib`, not by the Swift implementation.
- `InTreeSHA256` also matches the published SHA-256 answers for the empty message and for `abc`.

Those checks are why an in-tree implementation is acceptable for this one function. They do not make it a second commitment profile. The bytes that are hashed are unchanged.

## The alternative

[Swift Crypto](https://github.com/apple/swift-crypto) is Apple's open-source CryptoKit-shaped package. On Linux the import is `Crypto`, not `CryptoKit`. Current releases require Swift 6.2 or newer, so 6.4.1 can build them. On Apple platforms the package defers to the system CryptoKit.

Adopting it would be the first fetched dependency in this package. The Linux build pulls BoringSSL. This repository's maintenance rule so far is that no external package is fetched, and the only hash we need is SHA-256 of bytes we already specify.

## When to revisit

Add Swift Crypto when a second cryptographic operation shows up: signatures, key agreement, or a hash the in-tree file does not implement. At that point `import Crypto` should replace `InTreeSHA256`, and the same six vectors plus the empty/`abc` answers should be re-run before the in-tree file is removed.

Do not add it in order to rename the Linux hash to CryptoKit. The module name would still be `Crypto` on Linux, and the commitment profile would not change.
