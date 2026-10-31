#include "AureateWakeWaterObserverComponent.h"
#include "AureateWakePreviewActor.h"
#include "Components/PrimitiveComponent.h"

UAureateWakeWaterObserverComponent::UAureateWakeWaterObserverComponent()
{
    PrimaryComponentTick.bCanEverTick = true;
    PrimaryComponentTick.TickInterval = 0.05f;
}

void UAureateWakeWaterObserverComponent::BeginPlay()
{
    Super::BeginPlay();
    LandingGate = NewObject<UTSTSSWaterLandingGate>(this);
}

void UAureateWakeWaterObserverComponent::TickComponent(float DeltaTime,
    ELevelTick TickType, FActorComponentTickFunction* Function)
{
    Super::TickComponent(DeltaTime, TickType, Function);
    if (!IsValid(PhysicalHull) || !IsValid(WaterCollision) ||
        !IsValid(Story) || !IsValid(LandingGate) ||
        !PhysicalHull->GetGenerateOverlapEvents() || !WaterCollision->GetGenerateOverlapEvents())
    {
        return; // Unwired components must fail closed.
    }

    if (!Story->HasStarted()) return;
    const ETSTSSFirstWakeBeat Beat = Story->GetCurrentBeat();
    if (Beat != ETSTSSFirstWakeBeat::Launched && Beat != ETSTSSFirstWakeBeat::SeaContact)
    {
        return; // Chapter gate: never infer story milestones from geometry.
    }

    const bool bTouchingWater = PhysicalHull->IsOverlappingComponent(WaterCollision);
    const float VerticalSpeed = PhysicalHull->GetComponentVelocity().Z;
    // Presentation is allowed to react to genuine overlap, but cannot authorize contact.
    if (bTouchingWater && IsValid(VisualShip) &&
        VisualShip->GetCurrentForm() == EAureateWakeForm::Skyborne &&
        !VisualShip->IsTransitioning())
    {
        VisualShip->RequestForm(EAureateWakeForm::Seaborne);
    }
    LandingGate->Observe(DeltaTime, bTouchingWater, VerticalSpeed, Story);
}
