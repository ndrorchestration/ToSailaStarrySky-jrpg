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
    // Physical contact and story transitions are owned by TSTSSWaterContactAdapter.
}

void UAureateWakeWaterObserverComponent::TickComponent(float DeltaTime,
    ELevelTick TickType, FActorComponentTickFunction* Function)
{
    Super::TickComponent(DeltaTime, TickType, Function);
    if (!IsValid(Story) || !IsValid(VisualShip) || !Story->HasStarted()) return;
    // Presentation only: foundation contact adapter already confirmed this beat.
    // Request the visual landing only after the story gate has accepted
    // contact. Do not infer acceptance merely from a collider overlap.
    const ETSTSSFirstWakeBeat AcceptedBeat = Story->GetCurrentBeat();
    const bool bContactAccepted =
        AcceptedBeat == ETSTSSFirstWakeBeat::SeaContact ||
        AcceptedBeat == ETSTSSFirstWakeBeat::FlotationConfirmed;
    if (bContactAccepted &&
        VisualShip->GetCurrentForm() == EAureateWakeForm::Skyborne &&
        !VisualShip->IsTransitioning())
    {
        VisualShip->RequestForm(EAureateWakeForm::Seaborne);
    }
}
