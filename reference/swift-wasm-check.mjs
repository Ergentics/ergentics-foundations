// Runs a Swift 6.4.1 WASI build of CommitmentProbe and checks one hash.
// The probe prints a commitment. It does not admit or commit.
// Usage: node reference/swift-wasm-check.mjs path/to/CommitmentProbe.wasm

import { closeSync, fsyncSync, mkdtempSync, openSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { WASI } from "node:wasi";

const wasmPath = process.argv[2];
if (!wasmPath) {
  console.error("usage: node reference/swift-wasm-check.mjs CommitmentProbe.wasm");
  process.exit(2);
}

const captureDir = mkdtempSync(join(tmpdir(), "commitment-probe-"));
const stdoutPath = join(captureDir, "stdout.txt");
const stdout = openSync(stdoutPath, "w");
let status = 1;
let printed = "";
try {
  const wasi = new WASI({
    version: "preview1",
    args: ["CommitmentProbe"],
    env: {},
    stdout,
    returnOnExit: true,
  });
  const wasm = readFileSync(wasmPath);
  const { instance } = await WebAssembly.instantiate(wasm, wasi.getImportObject());
  status = wasi.start(instance);
  fsyncSync(stdout);
  closeSync(stdout);
  printed = readFileSync(stdoutPath, "utf8").trim();
} finally {
  try { closeSync(stdout); } catch { /* already closed after a successful start */ }
  rmSync(captureDir, { recursive: true, force: true });
}
const expected = "d9a07b92d21590167b300c10be7410322ecb78ed1a56ee0e531803fe263ccc22";
if (status !== 0 || printed !== expected) {
  console.error(`swift wasm status=${status} hex=${printed}`);
  process.exit(1);
}
console.log("CommitmentProbe wasm ok");
console.log(printed);
