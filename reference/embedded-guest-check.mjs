// Runs the embedded Swift guest and the Rust reader on the synthetic base.
// Each module constructs that state. This check compares the two hex strings
// to each other and to the Python vector. It does not copy one result into
// the other module.
// Usage: node reference/embedded-guest-check.mjs guest.wasm reader.wasm

import { readFileSync } from "node:fs";

const guestPath = process.argv[2];
const readerPath = process.argv[3];
if (!guestPath || !readerPath) {
  console.error("usage: node reference/embedded-guest-check.mjs guest.wasm reader.wasm");
  process.exit(2);
}

const expected = "d9a07b92d21590167b300c10be7410322ecb78ed1a56ee0e531803fe263ccc22";
const limit = 25 * 1024 * 1024;

function readWasm(path) {
  const bytes = readFileSync(path);
  if (bytes.length >= limit) {
    console.error(`${path} is ${bytes.length} bytes, at or above 25 MiB`);
    process.exit(1);
  }
  return bytes;
}

const guestBytes = readWasm(guestPath);
const readerBytes = readWasm(readerPath);
const guestModule = await WebAssembly.compile(guestBytes);
if (WebAssembly.Module.exports(guestModule).some((item) => item.name === "_start")) {
  console.error("guest exports _start; the page asset must be a reactor");
  process.exit(1);
}
let guestMemory;
let randomCalls = 0;
const guest = await WebAssembly.instantiate(guestModule, {
  wasi_snapshot_preview1: {
    random_get(ptr, len) {
      randomCalls += 1;
      new Uint8Array(guestMemory.buffer, ptr, len).fill(0);
      return 0;
    },
  },
});
guestMemory = guest.exports.memory;
if (guest.exports._initialize) guest.exports._initialize();
const swiftRc = guest.exports.cf_synthetic_base_hex();
const swiftPtr = guest.exports.cf_synthetic_base_ptr();
const swiftHex = new TextDecoder().decode(new Uint8Array(guest.exports.memory.buffer, swiftPtr, 64));

const reader = await WebAssembly.instantiate(readerBytes, {});
const { alloc, dealloc, cf_state_commitment_hex, memory } = reader.instance.exports;
const entries = new Uint8Array(32);
const order = new Uint8Array(16);
const entryView = new DataView(entries.buffer);
const orderView = new DataView(order.buffer);
entryView.setBigUint64(0, 1n);
entryView.setBigInt64(8, 10n);
entryView.setBigUint64(16, 2n);
entryView.setBigInt64(24, 20n);
orderView.setBigUint64(0, 1n);
orderView.setBigUint64(8, 2n);
const entryPtr = alloc(entries.length);
const orderPtr = alloc(order.length);
const out = alloc(64);
new Uint8Array(memory.buffer, entryPtr, entries.length).set(entries);
new Uint8Array(memory.buffer, orderPtr, order.length).set(order);
const rustRc = cf_state_commitment_hex(1n, 0n, entryPtr, entries.length, orderPtr, order.length, out);
const rustHex = new TextDecoder().decode(new Uint8Array(memory.buffer, out, 64));
dealloc(entryPtr, entries.length);
dealloc(orderPtr, order.length);
dealloc(out, 64);

const guestHasHash = guestBytes.includes(Buffer.from(expected));
if (swiftRc !== 0 || rustRc !== 0 || swiftHex !== expected || rustHex !== expected || swiftHex !== rustHex || guestHasHash) {
  console.error(`swift rc=${swiftRc} hex=${swiftHex}`);
  console.error(`rust rc=${rustRc} hex=${rustHex}`);
  console.error(`guest contains published hex=${guestHasHash} random_get calls=${randomCalls}`);
  process.exit(1);
}
console.log("embedded guest and rust reader agree");
console.log(swiftHex);
console.log(`guest ${guestBytes.length} bytes; random_get calls ${randomCalls}`);
