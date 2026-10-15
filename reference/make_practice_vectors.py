"""Independent PL-LOG-v1 bytes for the practice ledger. Synthetic values only.

Writes JSON to stdout. The state and relation hashes use the same fixed-binary
carrier as make_vectors.py. This script does not replace those six vectors.
"""
import hashlib, json, struct

def u(n):
    return struct.pack('>Q', n)

def rel(entries):
    body = b''.join(u(e['id']) + struct.pack('>q', e['value']) for e in sorted(entries, key=lambda e: e['id']))
    return b'CF-RELATION-v1\0' + u(len(entries)) + body

def state_bytes(s):
    return b'CF-STATE-v1\0' + u(s['lineage']) + u(s['generation']) + rel(s['entries']) + u(len(s['order'])) + b''.join(map(u, s['order']))

SURFACES = {'problems': 1, 'quiz': 2, 'recall': 3}
KINDS = {'WE': 1, 'PF': 2, 'RP': 3}

def lp(text):
    raw = text.encode('utf-8')
    return u(len(raw)) + raw

def event_bytes(event):
    confident = event['confident']
    flag = 0 if confident is None else (2 if confident else 1)
    score = 0.0 if event['score'] == 0 else event['score']
    return b''.join([
        lp(event['id']),
        lp(event['skillID']),
        bytes([SURFACES[event['surface']], KINDS[event['kind']]]),
        struct.pack('>d', score),
        struct.pack('>q', event['timestampMs']),
        bytes([flag]),
    ])

def log_bytes(events):
    return b'PL-LOG-v1\0' + u(len(events)) + b''.join(event_bytes(e) for e in events)

def chunks(payload):
    pad = (8 - (len(payload) % 8)) % 8
    raw = payload + bytes(pad)
    entries = []
    for index in range(0, len(raw), 8):
        ident = index // 8 + 1
        value = struct.unpack('>q', raw[index:index + 8])[0]
        entries.append({'id': ident, 'value': value})
    return entries, [e['id'] for e in entries]

assert struct.pack('>d', 1.0) == bytes.fromhex('3ff0000000000000')
assert struct.pack('>d', 0.5) == bytes.fromhex('3fe0000000000000')
assert struct.pack('>d', 0.0) == bytes(8)
assert struct.pack('>q', -1) == b'\xff' * 8
assert len(log_bytes([])) == 18

cases = [
    dict(name='empty-generation-0', lineage=1, generation=0, events=[]),
    dict(name='empty-generation-1', lineage=1, generation=1, events=[]),
    dict(name='one-worked-example', lineage=1, generation=1, events=[
        dict(id='rect-area-2x3', skillID='rect-area', surface='problems', kind='WE',
             score=1.0, timestampMs=1_700_000_000_000, confident=None),
    ]),
    dict(name='two-events-submission-order', lineage=4, generation=2, events=[
        dict(id='b', skillID='rect-area', surface='problems', kind='WE',
             score=1.0, timestampMs=1_700_000_000_000, confident=None),
        dict(id='a', skillID='tri-area', surface='quiz', kind='PF',
             score=0.5, timestampMs=1_700_000_000_100, confident=True),
    ]),
    dict(name='signed-timestamp-zero-score', lineage=1, generation=0, events=[
        dict(id='recall-1', skillID='caf\u00e9', surface='recall', kind='RP',
             score=0.0, timestampMs=-1, confident=False),
    ]),
]

out = []
for case in cases:
    entries, order = chunks(log_bytes(case['events']))
    carrier = dict(lineage=case['lineage'], generation=case['generation'], entries=entries, order=order)
    out.append(dict(
        name=case['name'],
        lineage=case['lineage'],
        generation=case['generation'],
        events=case['events'],
        expectedStateCommitment=hashlib.sha256(state_bytes(carrier)).hexdigest(),
        expectedRelationCommitment=hashlib.sha256(rel(entries)).hexdigest(),
    ))

print(json.dumps(out, indent=2, sort_keys=True))
