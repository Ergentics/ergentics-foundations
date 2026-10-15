# Swift compiler and WASM

The question was whether the Swift that already builds this package can also emit WebAssembly, or whether that needs a different compiler.

Swift 6.4.1 is one compiler. Its host triple here is `x86_64-unknown-linux-gnu`. That compiler rejects `-target wasm32-unknown-unknown`. It accepts `wasm32-unknown-wasip1` when the matching Swift SDK is installed:

```sh
swift sdk install https://download.swift.org/swift-6.4.1-release/wasm-sdk/swift-6.4.1-RELEASE/swift-6.4.1-RELEASE_wasm.artifactbundle.tar.gz \
  --checksum 783e6128d174d9f975b4eda68be02a5960681b723ef372e6876a7c2543a365d8
swift sdk list
# swift-6.4.1-RELEASE_wasm
# swift-6.4.1-RELEASE_wasm-embedded
```

`CommitmentProbe` builds a two-entry state and prints its commitment. It does not issue a capability, verify, or commit.

```sh
swift run --scratch-path /tmp/foundation-build CommitmentProbe
swift build -c release --swift-sdk swift-6.4.1-RELEASE_wasm --product CommitmentProbe --scratch-path /tmp/foundation-wasm
node reference/swift-wasm-check.mjs /tmp/foundation-wasm/out/Products/Release-webassembly-wasm32/CommitmentProbe.wasm
```

Both the native binary and the WASI module print `d9a07b92d21590167b300c10be7410322ecb78ed1a56ee0e531803fe263ccc22`, the synthetic-base vector. The release module is about 60 MB because it links the Swift WASI runtime and the whole `ChangeFoundation` module. The Rust reader’s `wasm32-unknown-unknown` module is about 50 KB and does not contain the Swift ledger.

`ChangeFoundation` is one module, so the probe binary contains the actor’s code even though the probe never calls it. That is not a second issuer. A WASM port of `ReferenceAuthority` is still not the design. The external WASM checker remains `commitment-reader`.
