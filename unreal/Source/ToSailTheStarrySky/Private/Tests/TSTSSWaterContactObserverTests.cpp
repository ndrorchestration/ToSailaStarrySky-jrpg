#include "Misc/AutomationTest.h"
#include "TSTSSWaterContactObserver.h"
#include "TSTSSFirstWakeState.h"

#if WITH_DEV_AUTOMATION_TESTS
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSWaterEvidencePolicyTest,
    "TSTSS.FirstWake.WaterEvidencePolicy",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSWaterEvidencePolicyTest::RunTest(const FString& Parameters)
{
    const auto Stable = [](bool Overlap, bool Simulating, float Speed, float Limit)
    {
        return ATSTSSWaterContactObserver::IsStableSample(Overlap, Simulating, Speed, Limit);
    };
    TestFalse(TEXT("Airborne vessel cannot count as floating"), Stable(false, true, 0.f, 35.f));
    TestFalse(TEXT("Decorative static mesh cannot count as floating"), Stable(true, false, 0.f, 35.f));
    TestFalse(TEXT("Fast downward impact not stable"), Stable(true, true, -100.f, 35.f));
    TestFalse(TEXT("Fast upward movement not stable"), Stable(true, true, 100.f, 35.f));
    TestTrue(TEXT("Slow submerged physics body passes sample"), Stable(true, true, 12.f, 35.f));
    TestTrue(TEXT("Stable boundary included"), Stable(true, true, -35.f, 35.f));
    TestFalse(TEXT("Negative threshold fails closed"), Stable(true, true, 0.f, -1.f));
    TestFalse(TEXT("Nonfinite speed fails closed"), Stable(true, true, TNumericLimits<float>::Infinity(), 35.f));
    TestFalse(TEXT("Nonfinite threshold fails closed"), Stable(true, true, 0.f, TNumericLimits<float>::Infinity()));
    TestTrue(TEXT("Near waterline vessel eligible"),
        ATSTSSWaterContactObserver::IsNearWaterSurface(90.f, 100.f, 150.f));
    TestFalse(TEXT("Deeply submerged vessel not stable flotation"),
        ATSTSSWaterContactObserver::IsNearWaterSurface(-500.f, 100.f, 150.f));
    TestFalse(TEXT("Airborne vessel not stable flotation"),
        ATSTSSWaterContactObserver::IsNearWaterSurface(500.f, 100.f, 150.f));
    TestTrue(TEXT("Waterline distance boundary is inclusive"),
        ATSTSSWaterContactObserver::IsNearWaterSurface(250.f, 100.f, 150.f));
    TestFalse(TEXT("Invalid waterline tolerance fails closed"),
        ATSTSSWaterContactObserver::IsNearWaterSurface(100.f, 100.f, 0.f));
    TestFalse(TEXT("Nonfinite waterline height fails closed"),
        ATSTSSWaterContactObserver::IsNearWaterSurface(100.f, TNumericLimits<float>::Infinity(), 150.f));
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSWaterBeatOrderTest,
    "TSTSS.FirstWake.WaterBeatSequence",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSWaterBeatOrderTest::RunTest(const FString& Parameters)
{
    UTSTSSFirstWakeState* State = NewObject<UTSTSSFirstWakeState>();
    if (!TestNotNull(TEXT("First Wake state"), State)) return false;
    TestTrue(TEXT("Restore verified prelanding checkpoint"), State->Restore(
        true, ETSTSSFirstWakeBeat::Launched, 0x07));
    TestFalse(TEXT("Cannot skip contact"), State->AdvanceTo(ETSTSSFirstWakeBeat::FlotationConfirmed));
    TestFalse(TEXT("Direct contact bypass blocked"), State->AdvanceTo(ETSTSSFirstWakeBeat::SeaContact));
    TestEqual(TEXT("Rejected contact preserves launch"), State->GetCurrentBeat(), ETSTSSFirstWakeBeat::Launched);
    TestFalse(TEXT("Direct flotation bypass blocked"), State->AdvanceTo(ETSTSSFirstWakeBeat::FlotationConfirmed));
    TestEqual(TEXT("Rejected flotation preserves launch"), State->GetCurrentBeat(), ETSTSSFirstWakeBeat::Launched);
    // Positive contact and flotation require native observer/physics integration evidence.
    return true;
}
#endif
