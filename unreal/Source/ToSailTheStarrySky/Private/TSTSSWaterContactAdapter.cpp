#include "TSTSSWaterContactAdapter.h"
#include "Components/StaticMeshComponent.h"
#include "TSTSSExplorerCharacter.h"
#include "Kismet/GameplayStatics.h"

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
    if (bAutoBindPlayerStory)
    {
        if (ATSTSSExplorerCharacter* Player = Cast<ATSTSSExplorerCharacter>(UGameplayStatics::GetPlayerCharacter(this, 0)))
        {
            BindStory(Player->GetFirstWakeState());
        }
    }
}

void ATSTSSWaterContactAdapter::BindStory(UTSTSSFirstWakeState* InStory)
{
    Story = InStory;
    if (Gate) Gate->Reset();
}

void ATSTSSWaterContactAdapter::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (!IsValid(Gate)) return;
    // Player BeginPlay may occur after this actor, so retry only while unbound.
    if (!IsValid(Story) && bAutoBindPlayerStory)
    {
        if (ATSTSSExplorerCharacter* Player = Cast<ATSTSSExplorerCharacter>(UGameplayStatics::GetPlayerCharacter(this, 0)))
        {
            if (IsValid(Player->GetFirstWakeState())) BindStory(Player->GetFirstWakeState());
        }
    }
    if (!IsValid(Story) || !IsValid(Hull) || !Hull->IsSimulatingPhysics())
    {
        Gate->Reset();
        return;
    }
    // Avoid repeated water queries after the relevant story event unless buoyancy is active.
    const ETSTSSFirstWakeBeat Beat = Story->GetCurrentBeat();
    if (!bEnablePrototypeBuoyancy && Beat != ETSTSSFirstWakeBeat::Launched &&
        Beat != ETSTSSFirstWakeBeat::SeaContact)
    {
        Gate->Reset();
        return;
    }
    TArray<AActor*> Overlaps;
    Hull->GetOverlappingActors(Overlaps, AActor::StaticClass());
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
    float HullSphereRadius = 0.f;
    Hull->GetComponentBounds(HullOrigin, HullExtent, HullSphereRadius);
    // Invalid authored configuration must never generate buoyancy or landing proof.
    if (!FMath::IsFinite(HullDraftCm) || HullDraftCm <= 1.f ||
        !FMath::IsFinite(DeltaSeconds) || DeltaSeconds <= 0.f)
    {
        Gate->Reset();
        return;
    }
    if (!FMath::IsFinite(HullOrigin.Z) || !FMath::IsFinite(HullExtent.Z) ||
        HullExtent.Z <= 0.f)
    {
        Gate->Reset();
        return;
    }
    const float Draft = HullDraftCm;
    const float Submersion = bInWater && FMath::IsFinite(WaterSurfaceZ)
        ? FMath::Clamp((WaterSurfaceZ - (HullOrigin.Z - Draft)) / (2.f * Draft), 0.f, 1.f)
        : 0.f;
    // Mere overlap with a tagged volume is not sufficient for sea contact.
    // Require the hull's lower bound to be below the authored surface, not
    // merely an overlapping volume's broad bounding box.
    const bool bBelowSurface = bInWater &&
        (HullOrigin.Z - HullExtent.Z) < WaterSurfaceZ;
    const bool bActualImmersion = bBelowSurface && Submersion > 0.01f;
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
        // Bound net force to avoid runaway impulses from invalid tuning.
        const float MaxAcceleration = FMath::Clamp(MaxBuoyantAccelerationCms2, 0.f, 4000.f);
        const float Damping = FMath::Clamp(VerticalDampingPerSecond, 0.f, 10.f);
        const float Acceleration = FMath::Clamp(MaxAcceleration * Submersion -
            Damping * VerticalSpeed, -MaxAcceleration, MaxAcceleration);
        const float Mass = Hull->GetMass();
        if (Mass > 0.f && FMath::IsFinite(Acceleration))
        {
            Hull->AddForce(FVector(0.f, 0.f, Mass * Acceleration));
        }
    }
    Gate->Observe(DeltaSeconds, bActualImmersion, VerticalSpeed, Story);
}
