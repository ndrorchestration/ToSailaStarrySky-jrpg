#include "TSTSSExplorerCharacter.h"
#include "TSTSSMilestoneActor.h"
#include "Camera/CameraComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Components/InputComponent.h"
#include "Engine/World.h"
#include "CollisionQueryParams.h"

ATSTSSExplorerCharacter::ATSTSSExplorerCharacter()
{
    PrimaryActorTick.bCanEverTick = false;
    CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
    CameraBoom->SetupAttachment(GetRootComponent());
    CameraBoom->TargetArmLength = 360.f;
    CameraBoom->bUsePawnControlRotation = true;
    FollowCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("FollowCamera"));
    FollowCamera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName);
    FollowCamera->bUsePawnControlRotation = false;
    bUseControllerRotationYaw = false;
    GetCharacterMovement()->bOrientRotationToMovement = true;
}

void ATSTSSExplorerCharacter::BeginPlay()
{
    Super::BeginPlay();
    FirstWakeState = NewObject<UTSTSSFirstWakeState>(this);
}

void ATSTSSExplorerCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);
    check(PlayerInputComponent);
    PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &ATSTSSExplorerCharacter::MoveForward);
    PlayerInputComponent->BindAxis(TEXT("MoveRight"), this, &ATSTSSExplorerCharacter::MoveRight);
    PlayerInputComponent->BindAxis(TEXT("Turn"), this, &ATSTSSExplorerCharacter::Turn);
    PlayerInputComponent->BindAxis(TEXT("LookUp"), this, &ATSTSSExplorerCharacter::LookUp);
    PlayerInputComponent->BindAction(TEXT("Interact"), IE_Pressed, this, &ATSTSSExplorerCharacter::Interact);
}

void ATSTSSExplorerCharacter::MoveForward(float Value)
{
    if (Controller && !FMath::IsNearlyZero(Value))
    {
        const FRotator Yaw(0.f, Controller->GetControlRotation().Yaw, 0.f);
        AddMovementInput(FRotationMatrix(Yaw).GetUnitAxis(EAxis::X), Value);
    }
}
void ATSTSSExplorerCharacter::MoveRight(float Value)
{
    if (Controller && !FMath::IsNearlyZero(Value))
    {
        const FRotator Yaw(0.f, Controller->GetControlRotation().Yaw, 0.f);
        AddMovementInput(FRotationMatrix(Yaw).GetUnitAxis(EAxis::Y), Value);
    }
}
void ATSTSSExplorerCharacter::Turn(float Value) { AddControllerYawInput(Value); }
void ATSTSSExplorerCharacter::LookUp(float Value) { AddControllerPitchInput(Value); }

void ATSTSSExplorerCharacter::Interact()
{
    if (!FirstWakeState || !FollowCamera || !GetWorld()) return;
    const FVector Start = FollowCamera->GetComponentLocation();
    const FVector End = Start + FollowCamera->GetForwardVector() * FMath::Max(0.f, InteractionDistance);
    FHitResult Hit;
    FCollisionQueryParams Query(SCENE_QUERY_STAT(TSTSSInteract), false, this);
    if (GetWorld()->LineTraceSingleByChannel(Hit, Start, End, ECC_Visibility, Query))
    {
        if (ATSTSSMilestoneActor* Milestone = Cast<ATSTSSMilestoneActor>(Hit.GetActor()))
        {
            Milestone->TryActivate(FirstWakeState);
        }
    }
}
