using UnrealBuildTool;
using System.Collections.Generic;

public class ToSailTheStarrySkyTarget : TargetRules
{
    public ToSailTheStarrySkyTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.V5;
        ExtraModuleNames.Add("ToSailTheStarrySky");
    }
}
