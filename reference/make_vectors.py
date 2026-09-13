"""Independent byte-level canonical reference; synthetic values only. Writes JSON to stdout."""
import hashlib, json, struct

def u(n): return struct.pack('>Q', n)
def rel(entries):
    return b'CF-RELATION-v1\0' + u(len(entries)) + b''.join(u(e['id']) + struct.pack('>q', e['value']) for e in sorted(entries, key=lambda e:e['id']))
def state(s):
    return b'CF-STATE-v1\0' + u(s['lineage']) + u(s['generation']) + rel(s['entries']) + u(len(s['order'])) + b''.join(map(u,s['order']))
cases = [
    dict(name='synthetic-base', lineage=1, generation=0, entries=[dict(id=1,value=10),dict(id=2,value=20)], order=[1,2]),
    dict(name='synthetic-order-change', lineage=1, generation=1, entries=[dict(id=2,value=20),dict(id=1,value=10)], order=[2,1]),
    dict(name='synthetic-source-change', lineage=1, generation=1, entries=[dict(id=1,value=11),dict(id=2,value=20)], order=[1,2]),
    dict(name='synthetic-empty-transition', lineage=1, generation=1, entries=[dict(id=1,value=10),dict(id=2,value=20)], order=[1,2]),
    dict(name='synthetic-signed-bounds', lineage=2, generation=0, entries=[dict(id=0,value=-(2**63)),dict(id=2**64-1,value=2**63-1)], order=[2**64-1,0]),
    dict(name='synthetic-empty-domain', lineage=0, generation=0, entries=[], order=[])
]
for s in cases:
    s['expectedStateCommitment']=hashlib.sha256(state(s)).hexdigest()
    s['expectedRelationCommitment']=hashlib.sha256(rel(s['entries'])).hexdigest()
print(json.dumps(cases, sort_keys=True, indent=2))
