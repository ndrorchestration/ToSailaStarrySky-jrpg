#include "TSTSSWaterContactAdapter.h"
#include "Components/StaticMeshComponent.h"

ATSTSSWaterContactAdapter::ATSTSSWaterContactAdapter()
{
    PrimaryActorTick.bCanEverTick = true;
    Hull = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Hull"));
    RootComponent = Hull;
    Hull->SetGenerateOverlapEvents(true);
}

void ATSTSSWaterContactAdapter::BeginPlay()
{
    Super::BeginPlay();
    Gate = NewObject<UTSTSSWaterLandingGate>(this);
}

void ATSTSSWaterContactAdapter::BindStory(UTSTSSFirstWakeState* InStory)
{
    Story = InStory;
    if (Gate) Gate->Reset();
}

void ATSTSSWaterContactAdapter::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (!IsValid(Story) || !IsValid(Gate) || !IsValid(Hull) ||
        !Hull->IsSimulatingPhysics()) return;
    TArray<AActor*> Overlaps;
    Hull->GetOverlappingActors(Overlaps);
    bool bInWater = false;
    float WaterSurfaceZ = -TNumericLimits<float>::Max();
    for (const AActor* Other : Overlaps)
    {
        if (IsValid(Other) && Other != this && Other->ActorHasTag(WaterVolumeTag))
        {
            // Only bounded water volumes with valid world-space bounds count.
            FVector Origin, Extent;
            Other->GetActorBounds(false, Origin, Extent);
            if (FMath::IsFinite(Origin.Z) && FMath::IsFinite(Extent.Z) && Extent.Z > 0.f)
            {
                bInWater = true;
                WaterSurfaceZ = FMath::Max(WaterSurfaceZ, Origin.Z + Extent.Z);
            }
        }
    }
    FVector HullOrigin, HullExtent;
    Hull->GetComponentBounds(HullOrigin, HullExtent, false);
    // Invalid authored configuration must never generate buoyancy or landing proof.
    if (!FMath::IsFinite(HullDraftCm) || HullDraftCm <= 1.f ||
        !FMath::IsFinite(DeltaSeconds) || DeltaSeconds <= 0.f)
    {
        Gate->Reset();
        return;
    }
    const float Draft = HullDraftCm;
    const float Submersion = bInWater && FMath::IsFinite(WaterSurfaceZ)
        ? FMath::Clamp((WaterSurfaceZ - (HullOrigin.Z - Draft)) / (2.f * Draft), 0.f, 1.f)
        : 0.f;
    // Mere overlap with a tagged volume is not sufficient for sea contact.
    const bool bActualImmersion = bInWater && Submersion > 0.01f;
    const float VerticalSpeed = Hull->GetPhysicsLinearVelocity().Z;
    if (!FMath::IsFinite(VerticalSpeed) || !FMath::IsFinite(Submersion))
    {
        Gate->Reset();
        return;
    }
    if (bActualImmersion && bEnablePrototypeBuoyancy && HullDraftCm > 1.f &&
        FMath::IsFinite(MaxBuoyantAccelerationCms2) &&
        FMath::IsFinite(VerticalDampingPerSecond) &&
        FMath::IsFinite(WaterSurfaceZ))
    {
        const float Acceleration = FMath::Max(0.f, MaxBuoyantAccelerationCms2) * Submersion -
            FMath::Max(0.f, VerticalDampingPerSecond) * VerticalSpeed;
        const float Mass = Hull->GetMass();
        if (Mass > 0.f && FMath::IsFinite(Acceleration))
        {
            Hull->AddForce(FVector(0.f, 0.f, Mass * Acceleration));
        }
    }
    Gate->Observe(DeltaSeconds, bActualImmersion, VerticalSpeed, Story);
}
