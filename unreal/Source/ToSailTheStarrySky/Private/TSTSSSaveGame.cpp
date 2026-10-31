#include "TSTSSSaveGame.h"

bool UTSTSSSaveGame::IsStructurallyValid() const
{
    if (!IsSupportedVersion() ||
        (InspectionMask & ~0x07u) != 0 ||
        (!bFirstWakeStarted && InspectionMask != 0) ||
        (InspectionMask != 0 && static_cast<uint8>(FirstWakeBeat) < static_cast<uint8>(ETSTSSFirstWakeBeat::BoardedAureateWake)) ||
        (static_cast<uint8>(FirstWakeBeat) >= static_cast<uint8>(ETSTSSFirstWakeBeat::EngineeringChecked) && InspectionMask != 0x07) ||
        static_cast<uint8>(FirstWakeBeat) >
            static_cast<uint8>(ETSTSSFirstWakeBeat::ReturnedToBerth) ||
        (!bFirstWakeStarted && FirstWakeBeat != ETSTSSFirstWakeBeat::FlyerDiscovered))
    {
        return false;
    }
    TSet<FName> Seen;
    for (const FTSTSSCombatant& Member : PartyRoster)
    {
        if (Member.CharacterId.IsNone() || Seen.Contains(Member.CharacterId) ||
            Member.MaxHealth <= 0 || Member.Health < 0 ||
            Member.Health > Member.MaxHealth || Member.MaxResource < 0 ||
            Member.Resource < 0 || Member.Resource > Member.MaxResource ||
            Member.Attack < 0 || Member.Defense < 0)
        {
            return false;
        }
        Seen.Add(Member.CharacterId);
    }
    return true;
}

bool UTSTSSSaveGame::CaptureFirstWake(const UTSTSSFirstWakeState* State)
{
    if (!IsValid(State) || !IsStructurallyValid())
    {
        return false;
    }

    // Snapshot the story into a validated temporary object first. Avoid
    // corrupting this save when the source story has an inconsistent mask.
    UTSTSSSaveGame* Candidate = NewObject<UTSTSSSaveGame>(this);
    Candidate->SchemaVersion = SchemaVersion;
    Candidate->PartyRoster = PartyRoster;
    Candidate->bFirstWakeStarted = State->HasStarted();
    Candidate->FirstWakeBeat = State->GetCurrentBeat();
    Candidate->InspectionMask = State->GetInspectionMask();

    if (!Candidate->IsStructurallyValid())
    {
        return false;
    }

    bFirstWakeStarted = Candidate->bFirstWakeStarted;
    FirstWakeBeat = Candidate->FirstWakeBeat;
    InspectionMask = Candidate->InspectionMask;
    return true;
}

bool UTSTSSSaveGame::CapturePartyRoster(const TArray<FTSTSSCombatant>& Roster)
{
    // A story-only checkpoint must never replace a populated roster with an
    // accidental empty list. New-game roster initialization is a separate step.
    if (Roster.IsEmpty() || !IsStructurallyValid())
    {
        return false;
    }
    UTSTSSSaveGame* Candidate = NewObject<UTSTSSSaveGame>(this);
    Candidate->SchemaVersion = SchemaVersion;
    Candidate->bFirstWakeStarted = bFirstWakeStarted;
    Candidate->FirstWakeBeat = FirstWakeBeat;
    Candidate->InspectionMask = InspectionMask;
    Candidate->PartyRoster = Roster;
    if (!Candidate->IsStructurallyValid())
    {
        return false;
    }
    PartyRoster = Roster;
    return true;
}
