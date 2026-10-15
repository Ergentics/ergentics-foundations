"""Independent decision table for OracleAdmission. Synthetic witnesses only.

Writes JSON to stdout. Scores are restricted to 0, 0.5, and 1 so the comparison
does not depend on JSON floating-point rounding. This is not a corpus harvest.
"""
import json

def judge(case):
    witnesses = case["witnesses"]
    if case["asserted"] != "derived" or not witnesses:
        return "notDerivable"
    owners = {}
    for witness in witnesses:
        for dependency in set(witness["dependencies"]):
            owners[dependency] = owners.get(dependency, 0) + 1
    if any(count >= 2 for count in owners.values()):
        return "sharedDependency"
    if len({witness["family"] for witness in witnesses}) < case["minimumFamilies"]:
        return "tooFewFamilies"
    if any(witness["score"] != case["claimScore"] for witness in witnesses):
        return "discordant"
    if not case["falsifierSettled"]:
        return "falsifierOpen"
    return "seal"

def case(name, asserted, claim, witnesses, minimum=2, settled=True):
    row = dict(
        name=name, asserted=asserted, claimScore=claim, witnesses=witnesses,
        minimumFamilies=minimum, falsifierSettled=settled)
    row["expected"] = judge(row)
    return row

agree = lambda family, deps=(): dict(family=family, dependencies=list(deps), score=1)
out = [
    case("prediction-unbacked", "prediction", 1, []),
    case("recorded-with-witnesses", "recorded", 1, [agree("a"), agree("b")]),
    case("derived-without-witnesses", "derived", 1, []),
    case("one-family", "derived", 1, [agree("a")]),
    case("repeated-family", "derived", 1, [agree("a"), agree("a", ["left"])]),
    case("shared-dependency", "derived", 1, [agree("a", ["prior"]), agree("b", ["prior"])]),
    case("shared-before-family-count", "derived", 1, [agree("a", ["prior"]), agree("a", ["prior"])]),
    case("discordant", "derived", 1, [
        agree("a"),
        dict(family="b", dependencies=[], score=0.5),
    ]),
    case("shared-before-discord", "derived", 1, [
        agree("a", ["prior"]),
        dict(family="b", dependencies=["prior"], score=0),
    ]),
    case("falsifier-open", "derived", 1, [agree("a"), agree("b")], settled=False),
    case("two-families-seal", "derived", 1, [agree("a", ["left"]), agree("b", ["right"])]),
    case("three-family-floor", "derived", 1, [agree("a"), agree("b")], minimum=3),
    case("three-families-seal", "derived", 0.5, [
        dict(family="a", dependencies=[], score=0.5),
        dict(family="b", dependencies=["p"], score=0.5),
        dict(family="c", dependencies=["q"], score=0.5),
    ], minimum=3),
]
print(json.dumps(out, indent=2, sort_keys=True))
