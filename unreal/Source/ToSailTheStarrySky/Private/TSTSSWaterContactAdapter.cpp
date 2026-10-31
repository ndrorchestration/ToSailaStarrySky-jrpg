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
    for (const AActor* Other : Overlaps)
    {
        if (IsValid(Other) && Other != this && Other->ActorHasTag(WaterVolumeTag))
        {
            bInWater = true;
            break;
        }
    }
    Gate->Observe(DeltaSeconds, bInWater, Hull->GetPhysicsLinearVelocity().Z, Story);
}
