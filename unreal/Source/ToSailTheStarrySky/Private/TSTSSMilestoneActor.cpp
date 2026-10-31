#include "TSTSSMilestoneActor.h"
#include "Components/StaticMeshComponent.h"

ATSTSSMilestoneActor::ATSTSSMilestoneActor()
{
    PrimaryActorTick.bCanEverTick = false;
    InteractionMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("InteractionMesh"));
    RootComponent = InteractionMesh;
    InteractionMesh->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
    InteractionMesh->SetCollisionResponseToChannel(ECC_Visibility, ECR_Block);
}

bool ATSTSSMilestoneActor::TryActivate(UTSTSSFirstWakeState* State)
{
    if (!IsValid(State) || !State->AdvanceTo(Milestone)) return false;
    OnMilestoneActivated();
    return true;
}
