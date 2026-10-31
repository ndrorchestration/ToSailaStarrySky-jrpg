#include "TSTSSFirstWakeHUD.h"

#include "TSTSSExplorerCharacter.h"
#include "TSTSSFirstWakeState.h"
#include "GameFramework/PlayerController.h"
#include "Engine/Canvas.h"

void ATSTSSFirstWakeHUD::DrawHUD()
{
    Super::DrawHUD();

    if (!bShowObjective || !Canvas || !PlayerOwner)
    {
        return;
    }

    const ATSTSSExplorerCharacter* Explorer = Cast<ATSTSSExplorerCharacter>(PlayerOwner->GetPawn());
    const UTSTSSFirstWakeState* Story = IsValid(Explorer) ? Explorer->GetFirstWakeState() : nullptr;
    if (!IsValid(Story))
    {
        return;
    }

    const float Scale = FMath::Clamp(ObjectiveScale, 0.5f, 3.f);
    const float Left = 24.f;
    const float Top = 24.f;
    const float BackgroundWidth = FMath::Min(Canvas->SizeX - 2.f * Left, 900.f);
    if (BackgroundWidth <= 0.f)
    {
        return;
    }

    // Readability-first prototype: no HUD asset dependency or gameplay mutation.
    DrawRect(FLinearColor(0.015f, 0.025f, 0.06f, 0.8f),
        Left - 12.f, Top - 12.f, BackgroundWidth, 88.f * Scale);
    DrawText(Story->GetCurrentObjective().ToString(), FLinearColor::White,
        Left, Top, nullptr, Scale, false);
}
