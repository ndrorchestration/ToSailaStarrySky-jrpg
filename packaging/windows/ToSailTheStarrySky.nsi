; First Wake candidate Windows installer. Original Godot executable only.
; Source export, CI checks and human release approval precede publication.
; NSIS 3, user account install, no admin, no foreign data removal.
Unicode true
!include "LogicLib.nsh"
!ifndef GAME_EXE
  !error "GAME_EXE must be the exact exported Godot game binary"
!endif
!ifndef INSTALLER_OUT
  !error "INSTALLER_OUT must be explicitly provided"
!endif
Name "To Sail the Starry Sky — First Wake Preview"
OutFile "${INSTALLER_OUT}"
InstallDir "$LOCALAPPDATA\Programs\ToSailTheStarrySky-FirstWake"
RequestExecutionLevel user
SetCompressor /SOLID lzma
ShowInstDetails show
ShowUninstDetails show
Page directory
Page instfiles
UninstPage uninstConfirm
UninstPage instfiles

Function .onInit
  ; An existing unrelated program must not be overwritten.
  IfFileExists "$INSTDIR\*" 0 +4
    IfFileExists "$INSTDIR\TSTSS-FirstWake.install" +2 0
      MessageBox MB_ICONSTOP "Install path has unrecognized files. Choose a different directory." /SD IDOK
      Abort
FunctionEnd

Section "First Wake (Playtest)" SEC_MAIN
  SetOutPath "$INSTDIR"
  File /oname=ToSailTheStarrySky.exe "${GAME_EXE}"
  FileOpen $0 "$INSTDIR\TSTSS-FirstWake.install" w
  FileWrite $0 "TSTSS_FIRST_WAKE_GODOT_PREVIEW_INSTALL_V1"
  FileClose $0
  WriteUninstaller "$INSTDIR\Uninstall-ToSailTheStarrySky.exe"
  CreateDirectory "$SMPROGRAMS\To Sail the Starry Sky"
  CreateShortcut "$SMPROGRAMS\To Sail the Starry Sky\First Wake Preview.lnk" "$INSTDIR\ToSailTheStarrySky.exe"
  CreateShortcut "$DESKTOP\To Sail the Starry Sky (First Wake).lnk" "$INSTDIR\ToSailTheStarrySky.exe"
SectionEnd

Section "Uninstall"
  IfFileExists "$INSTDIR\TSTSS-FirstWake.install" 0 not_owned
  FileOpen $0 "$INSTDIR\TSTSS-FirstWake.install" r
  FileRead $0 $1
  FileClose $0
  StrCmp $1 "TSTSS_FIRST_WAKE_GODOT_PREVIEW_INSTALL_V1" owned not_owned
  owned:
    Delete "$DESKTOP\To Sail the Starry Sky (First Wake).lnk"
    Delete "$SMPROGRAMS\To Sail the Starry Sky\First Wake Preview.lnk"
    RMDir "$SMPROGRAMS\To Sail the Starry Sky"
    Delete "$INSTDIR\ToSailTheStarrySky.exe"
    Delete "$INSTDIR\TSTSS-FirstWake.install"
    Delete "$INSTDIR\Uninstall-ToSailTheStarrySky.exe"
    RMDir "$INSTDIR"
    Goto done
  not_owned:
    MessageBox MB_ICONSTOP "Installation marker missing or unrecognized. No files were deleted." /SD IDOK
    SetErrorLevel 3
  done:
SectionEnd
