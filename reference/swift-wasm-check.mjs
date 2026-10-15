// Runs a Swift 6.4.1 WASI build of CommitmentProbe and checks one hash.
// The probe prints a commitment. It does not admit or commit.
// Usage: node reference/swift-wasm-check.mjs path/to/CommitmentProbe.wasm

import { openSync, readFileSync, closeSync } from "node:fs";
import { WASI } from "node:wasi";

const wasmPath = process.argv[2];
if (!wasmPath) {
  console.error("usage: node reference/swift-wasm-check.mjs CommitmentProbe.wasm");
  process.exit(2);
}

const stdoutPath = "/tmp/commitment-probe-stdout.txt";
const stdout = openSync(stdoutPath, "w");
const wasi = new WASI({
  version: "preview1",
  args: ["CommitmentProbe"],
  env: {},
  stdout,
  returnOnExit: true,
});
const wasm = readFileSync(wasmPath);
const { instance } = await WebAssembly.instantiate(wasm, wasi.getImportObject());
const status = wasi.start(instance);
closeSync(stdout);
const printed = readFileSync(stdoutPath, "utf8").trim();
const expected = "d9a07b92d21590167b300c10be7410322ecb78ed1a56ee0e531803fe263ccc22";
if (status !== 0 || printed !== expected) {
  console.error(`swift wasm status=${status} hex=${printed}`);
  process.exit(1);
}
console.log("CommitmentProbe wasm ok");
console.log(printed);
