; To Sail the Starry Sky — First Wake native Godot preview setup
; Non-admin, separate from old Aetherwake / NW.js installations.
; Refuses occupied destinations or shortcut slots; does not silently upgrade.
Unicode true
!include "MUI2.nsh"
!include "LogicLib.nsh"
!ifndef GAME_EXE
  !error "GAME_EXE must be the exact exported Godot game binary"
!endif
!ifndef INSTALLER_OUT
  !error "INSTALLER_OUT must be explicitly provided"
!endif
!define PRODUCT_NAME "To Sail the Starry Sky — First Wake Preview"
!define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\ToSailTheStarrySky-FirstWake"
Name "${PRODUCT_NAME}"
OutFile "${INSTALLER_OUT}"
InstallDir "$LOCALAPPDATA\Programs\ToSailTheStarrySky-FirstWake"
RequestExecutionLevel user
SetCompressor /SOLID lzma
ShowInstDetails show
ShowUninstDetails show
VIProductVersion "0.1.0.0"
VIAddVersionKey "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey "FileDescription" "First Wake playable native game installer"
VIAddVersionKey "CompanyName" "ndrorchestration"
VIAddVersionKey "ProductVersion" "0.1.0-preview"
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\ToSailTheStarrySky.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Launch To Sail the Starry Sky"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Function CheckInstallDestination
  ; Checked after directory selection, before any write. Even a previous
  ; preview installation must be explicitly uninstalled first; avoid
  ; overwriting arbitrary user files, shortcuts, or another app's registry.
  IfFileExists "$INSTDIR\*" occupied_dir clear_dir
  occupied_dir:
    MessageBox MB_ICONSTOP "The selected folder is not empty. Please uninstall the older preview or choose an empty folder." /SD IDOK
    SetErrorLevel 3
    Abort
  clear_dir:
  IfFileExists "$DESKTOP\To Sail the Starry Sky (First Wake).lnk" occupied_shortcut
  IfFileExists "$SMPROGRAMS\To Sail the Starry Sky\First Wake Preview.lnk" occupied_shortcut
  ReadRegStr $0 HKCU "${UNINSTALL_KEY}" "UninstallString"
  StrCmp $0 "" clean_destination
    MessageBox MB_ICONSTOP "A First Wake installation is registered already. Uninstall it before installing another copy." /SD IDOK
    SetErrorLevel 3
    Abort
  occupied_shortcut:
    MessageBox MB_ICONSTOP "A desktop or Start Menu shortcut is already using this game's name. The installer will not overwrite it." /SD IDOK
    SetErrorLevel 3
    Abort
  clean_destination:
FunctionEnd

Section "First Wake playable preview" SEC_MAIN
  Call CheckInstallDestination
  SetOutPath "$INSTDIR"
  File /oname=ToSailTheStarrySky.exe "${GAME_EXE}"
  FileOpen $0 "$INSTDIR\TSTSS-FirstWake.install" w
  FileWrite $0 "TSTSS_FIRST_WAKE_GODOT_PREVIEW_INSTALL_V1"
  FileClose $0
  WriteUninstaller "$INSTDIR\Uninstall-ToSailTheStarrySky.exe"
  CreateDirectory "$SMPROGRAMS\To Sail the Starry Sky"
  CreateShortcut "$SMPROGRAMS\To Sail the Starry Sky\First Wake Preview.lnk" "$INSTDIR\ToSailTheStarrySky.exe"
  CreateShortcut "$DESKTOP\To Sail the Starry Sky (First Wake).lnk" "$INSTDIR\ToSailTheStarrySky.exe"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayName" "${PRODUCT_NAME}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "UninstallString" '$"$INSTDIR\Uninstall-ToSailTheStarrySky.exe$"'
  WriteRegStr HKCU "${UNINSTALL_KEY}" "QuietUninstallString" '$"$INSTDIR\Uninstall-ToSailTheStarrySky.exe$" /S'
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayIcon" "$INSTDIR\ToSailTheStarrySky.exe"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayVersion" "0.1.0-preview"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "Publisher" "ndrorchestration"
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair" 1
SectionEnd

Section "Uninstall"
  IfFileExists "$INSTDIR\TSTSS-FirstWake.install" 0 not_owned
  FileOpen $0 "$INSTDIR\TSTSS-FirstWake.install" r
  FileRead $0 $1
  FileClose $0
  StrCmp $1 "TSTSS_FIRST_WAKE_GODOT_PREVIEW_INSTALL_V1" owned not_owned
  owned:
    ; Uninstall only files/shortcuts this preview created; no recursive
    ; folder removal. Godot saves in user:// are intentionally preserved.
    Delete "$DESKTOP\To Sail the Starry Sky (First Wake).lnk"
    Delete "$SMPROGRAMS\To Sail the Starry Sky\First Wake Preview.lnk"
    RMDir "$SMPROGRAMS\To Sail the Starry Sky"
    Delete "$INSTDIR\ToSailTheStarrySky.exe"
    DeleteRegKey HKCU "${UNINSTALL_KEY}"
    Delete "$INSTDIR\TSTSS-FirstWake.install"
    Delete "$INSTDIR\Uninstall-ToSailTheStarrySky.exe"
    RMDir "$INSTDIR"
    Goto done
  not_owned:
    MessageBox MB_ICONSTOP "Installation marker missing or unrecognized. No files were deleted." /SD IDOK
    SetErrorLevel 3
  done:
SectionEnd
