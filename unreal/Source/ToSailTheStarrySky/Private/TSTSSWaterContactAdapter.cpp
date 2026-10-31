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
    const float VerticalSpeed = Hull->GetPhysicsLinearVelocity().Z;
    if (bInWater && bEnablePrototypeBuoyancy && HullDraftCm > 1.f &&
        FMath::IsFinite(MaxBuoyantAccelerationCms2) &&
        FMath::IsFinite(VerticalDampingPerSecond) &&
        FMath::IsFinite(WaterSurfaceZ))
    {
        FVector HullOrigin, HullExtent;
        Hull->GetComponentBounds(HullOrigin, HullExtent, false);
        const float Submersion = FMath::Clamp(
            (WaterSurfaceZ - (HullOrigin.Z - HullDraftCm)) / (2.f * HullDraftCm), 0.f, 1.f);
        const float Acceleration = FMath::Max(0.f, MaxBuoyantAccelerationCms2) * Submersion -
            FMath::Max(0.f, VerticalDampingPerSecond) * VerticalSpeed;
        const float Mass = Hull->GetMass();
        if (Mass > 0.f && FMath::IsFinite(Acceleration))
        {
            Hull->AddForce(FVector(0.f, 0.f, Mass * Acceleration));
        }
    }
    Gate->Observe(DeltaSeconds, bInWater, VerticalSpeed, Story);
}
