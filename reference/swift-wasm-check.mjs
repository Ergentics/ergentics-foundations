// Runs a Swift 6.4.1 WASI build of CommitmentProbe and checks one hash.
// The probe prints a commitment. It does not admit or commit.
// Usage: node reference/swift-wasm-check.mjs path/to/CommitmentProbe.wasm

import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { WASI } from "node:wasi";
import { fileURLToPath } from "node:url";

const wasmPath = process.argv[2];
if (!wasmPath) {
  console.error("usage: node reference/swift-wasm-check.mjs CommitmentProbe.wasm");
  process.exit(2);
}

const expected = "d9a07b92d21590167b300c10be7410322ecb78ed1a56ee0e531803fe263ccc22";

// The probe writes fd 1. The parent reads that pipe. No temp file is opened.
if (process.env.COMMITMENT_PROBE_INNER !== "1") {
  const child = spawnSync(
    process.execPath,
    [fileURLToPath(import.meta.url), wasmPath],
    {
      env: { ...process.env, COMMITMENT_PROBE_INNER: "1" },
      encoding: "utf8",
    },
  );
  const printed = (child.stdout ?? "").trim();
  if (child.status !== 0 || printed !== expected) {
    console.error(`swift wasm status=${child.status} hex=${printed}`);
    process.exit(1);
  }
  console.log("CommitmentProbe wasm ok");
  console.log(printed);
  process.exit(0);
}

const wasi = new WASI({
  version: "preview1",
  args: ["CommitmentProbe"],
  env: {},
  returnOnExit: true,
});
const wasm = readFileSync(wasmPath);
const { instance } = await WebAssembly.instantiate(wasm, wasi.getImportObject());
const status = wasi.start(instance);
process.exit(status ?? 0);
