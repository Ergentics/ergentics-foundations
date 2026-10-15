// Runs the wasm32 build of commitment-reader 0.1.0 and checks two committed hashes.
// The module hashes canonical bytes. It does not admit or commit.

import { readFileSync } from "node:fs";

const wasmPath = new URL(
  "./target/wasm32-unknown-unknown/release/commitment_reader.wasm",
  import.meta.url,
);
const { instance } = await WebAssembly.instantiate(readFileSync(wasmPath), {});
const { alloc, dealloc, cf_state_commitment_hex, pl_state_commitment_hex, memory } =
  instance.exports;

function view() {
  return new DataView(memory.buffer);
}

function writeBytes(ptr, bytes) {
  new Uint8Array(memory.buffer, ptr, bytes.length).set(bytes);
}

function readHex(ptr) {
  return new TextDecoder().decode(new Uint8Array(memory.buffer, ptr, 64));
}

const entries = alloc(32);
const order = alloc(16);
const out = alloc(64);
const pack = new Uint8Array(32);
const entryView = new DataView(pack.buffer);
entryView.setBigUint64(0, 1n);
entryView.setBigInt64(8, 10n);
entryView.setBigUint64(16, 2n);
entryView.setBigInt64(24, 20n);
writeBytes(entries, pack);
const orderPack = new Uint8Array(16);
const orderView = new DataView(orderPack.buffer);
orderView.setBigUint64(0, 1n);
orderView.setBigUint64(8, 2n);
writeBytes(order, orderPack);

const stateRc = cf_state_commitment_hex(1n, 0n, entries, 32, order, 16, out);
if (stateRc !== 0) throw new Error(`state call returned ${stateRc}`);
const stateHex = readHex(out);
const expectedState = "d9a07b92d21590167b300c10be7410322ecb78ed1a56ee0e531803fe263ccc22";
if (stateHex !== expectedState) {
  throw new Error(`state wasm ${stateHex} != ${expectedState}`);
}

dealloc(entries, 32);
dealloc(order, 16);

const packed = alloc(8);
writeBytes(packed, new Uint8Array(8));
const practiceRc = pl_state_commitment_hex(1n, 0n, packed, 8, out);
if (practiceRc !== 0) throw new Error(`practice call returned ${practiceRc}`);
const practiceHex = readHex(out);
const expectedPractice = "fffba27d62a7b2751cb6f6556a0863e5a48149c75c683d85a0295f3467a99025";
if (practiceHex !== expectedPractice) {
  throw new Error(`practice wasm ${practiceHex} != ${expectedPractice}`);
}

dealloc(packed, 8);
dealloc(out, 64);
console.log("commitment-reader 0.1.0 wasm ok");
console.log(stateHex);
console.log(practiceHex);
