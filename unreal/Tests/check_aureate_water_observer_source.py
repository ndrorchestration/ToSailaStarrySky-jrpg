#!/usr/bin/env python3
"""Source-only guard for the unique First Wake water-contact authority."""
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
base = ROOT / "Source/ToSailTheStarrySky"
observer = (base / "Private/AureateWakeWaterObserverComponent.cpp").read_text()
header = (base / "Public/AureateWakeWaterObserverComponent.h").read_text()
adapter = (base / "Private/TSTSSWaterContactAdapter.cpp").read_text()
checks = {
    "physical contact owned by foundation": "Gate->Observe(" in adapter,
    "foundation checks physical hull": "GetPhysicsLinearVelocity()" in adapter and "bActualImmersion" in adapter,
    "ship observer never records contact": "Observe(" not in observer and "AdvanceTo(" not in observer,
    "ship observer does not own water gate": "LandingGate" not in observer and "LandingGate" not in header,
    "ship observer does not sample collision": "IsOverlappingComponent" not in observer and "PhysicalHull" not in header,
    "visual trigger requires accepted story beat": "ETSTSSFirstWakeBeat::SeaContact" in observer and "bContactAccepted" in observer,
    "ship only requests visual form": "RequestForm(EAureateWakeForm::Seaborne)" in observer,
}
for label, passed in checks.items():
    print(("PASS" if passed else "FAIL") + ": " + label)
if not all(checks.values()):
    raise SystemExit(1)
print("SOURCE ONLY: native Unreal behavior and rendering remain unverified")
