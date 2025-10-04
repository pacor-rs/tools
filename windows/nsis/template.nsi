; NSIS Installer Script - Multi-language Version
; For Flutter Applications

; Enable strict error checking
!pragma warning error all

Unicode True
ManifestDPIAware true
ManifestDPIAwareness PerMonitorV2

; Include required libraries
!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "WordFunc.nsh"
!include "LogicLib.nsh"
!include "nsProcess.nsh"

; ============================================
; Application information definitions
; ============================================
!define APP_NAME "{{APP_NAME}}"
!define APP_VERSION "{{APP_VERSION}}"
!define APP_URL "{{APP_URL}}"
!define APP_EXECUTABLE "{{APP_EXECUTABLE}}"
!define APP_ICON "{{APP_ICON_PATH}}"
!define BUILD_OUTPUT_DIR "{{BUILD_OUTPUT_DIR}}" ; e.g., build\windows\x64\runner\Release
!define INSTALLER_OUTPUT_PATH "{{INSTALLER_OUTPUT_PATH}}" ; e.g., dist\MyApp-0.1.0-x64-setup.exe

; ============================================
; Interface Settings
; ============================================
!define MUI_ABORTWARNING
!define MUI_ICON "${APP_ICON}"

; Display all languages regardless of user code page
!define MUI_LANGDLL_ALLLANGUAGES

; ============================================
; Installer Pages
; ============================================
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; ============================================
; Uninstaller Pages
; ============================================
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; ============================================
; Reserve Files (for solid compression optimization)
; ============================================
!insertmacro MUI_RESERVEFILE_LANGDLL

; ============================================
; Remember installer language selection
; ============================================
!define MUI_LANGDLL_REGISTRY_ROOT "HKCU"
!define MUI_LANGDLL_REGISTRY_KEY "Software\${APP_NAME}"
!define MUI_LANGDLL_REGISTRY_VALUENAME "Installer Language"

; ============================================
; Multi-language macro configuration (generated from project config)
; Example: !insertmacro MUI_LANGUAGE "SimpChinese"
; ============================================
{{LANGUAGE_MACROS}}

; ============================================
; Multi-language application info definitions (generated from project config)
; Defines variables such as:
;    - Application display name (APP_DISPLAY_NAME)
;    - Publisher name (APP_PUBLISHER)
; Example: LangString APP_DISPLAY_NAME ${LANG_ENGLISH} "MyApp"
; ============================================
{{LANGUAGE_STRINGS}}

; ============================================
; Multi-language string includes
; Example: !include "${NSISDIR}\languages\English.nsh"
; ============================================
{{LANGUAGE_INCLUDE}}

; ============================================
; Installer metadata
; ============================================
Name "$(APP_DISPLAY_NAME) v${APP_VERSION}"
OutFile "${INSTALLER_OUTPUT_PATH}"

; Default installation directory
InstallDir "$LOCALAPPDATA\${APP_NAME}"
InstallDirRegKey HKCU "Software\${APP_NAME}" "InstallDir"

; Request user-level execution (no admin required)
RequestExecutionLevel user

; ============================================
; Version information (generated from project config)
; Example: VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "MyApp"
; ============================================
{{VERSION_INFO}}

; ============================================
; Installation Sections
; ============================================
Section "$(SECTION_MAIN)" SecMain
    SectionIn RO
    
    SetOutPath "$INSTDIR"
    
    ; Copy application files
    File /r "${BUILD_OUTPUT_DIR}\*"
    
    ; Create uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"
    
    ; Write registry entries
    WriteRegStr HKCU "Software\${APP_NAME}" "InstallDir" "$INSTDIR"
    WriteRegStr HKCU "Software\${APP_NAME}" "Version" "${APP_VERSION}"
    
    ; Add to "Apps & Features" (Programs and Features)
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayName" "$(APP_DISPLAY_NAME)"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayVersion" "${APP_VERSION}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "Publisher" "$(APP_PUBLISHER)"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "URLInfoAbout" "${APP_URL}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayIcon" "$INSTDIR\${APP_EXECUTABLE}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "QuietUninstallString" "$INSTDIR\Uninstall.exe /S"
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoModify" 1
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoRepair" 1
    
    ; Calculate and write estimated installation size
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "EstimatedSize" "$0"
SectionEnd

Section "$(SECTION_DESKTOP)" SecDesktop
    CreateShortcut "$DESKTOP\$(APP_DISPLAY_NAME).lnk" "$INSTDIR\${APP_EXECUTABLE}" "" "$INSTDIR\${APP_EXECUTABLE}" 0
SectionEnd

Section "$(SECTION_STARTMENU)" SecStartMenu
    CreateDirectory "$SMPROGRAMS\${APP_NAME}"
    CreateShortcut "$SMPROGRAMS\${APP_NAME}\$(APP_DISPLAY_NAME).lnk" "$INSTDIR\${APP_EXECUTABLE}" "" "$INSTDIR\${APP_EXECUTABLE}" 0
    CreateShortcut "$SMPROGRAMS\${APP_NAME}\$(SHORTCUT_UNINSTALL).lnk" "$INSTDIR\Uninstall.exe" "" "$INSTDIR\Uninstall.exe" 0
SectionEnd

; ============================================
; Installer Functions
; ============================================
Function .onInit
    ; Display language selection dialog
    !insertmacro MUI_LANGDLL_DISPLAY

    ; Check if the application is currently running
    ${nsProcess::FindProcess} "${APP_EXECUTABLE}" $R0
    ${If} $R0 == 0  ; 0 means process was found
        MessageBox MB_OK|MB_ICONEXCLAMATION "$(MSG_APP_RUNNING)"
        Abort
    ${EndIf}

    ; Check available disk space (minimum 500 MB required)
    ${GetRoot} "$INSTDIR" $0
    ${DriveSpace} "$0\" "/D=F /S=M" $1
    ${If} $1 < 500
        MessageBox MB_OK|MB_ICONEXCLAMATION "$(MSG_INSUFFICIENT_SPACE)"
        Abort
    ${EndIf}
FunctionEnd

; ============================================
; Section Descriptions
; ============================================
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecMain} $(DESC_MAIN)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} $(DESC_DESKTOP)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecStartMenu} $(DESC_STARTMENU)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; Function called after successful installation
Function .onInstSuccess
    MessageBox MB_YESNO "$(MSG_INSTALL_COMPLETE)" IDYES Launch
    Goto NoLaunch
    Launch:
        Exec '"$INSTDIR\${APP_EXECUTABLE}"'
    NoLaunch:
FunctionEnd

; ============================================
; Uninstallation Section
; ============================================
Section "Uninstall"
    ; Check if the application is currently running
    ${nsProcess::FindProcess} "${APP_EXECUTABLE}" $R0
    ${If} $R0 == 0  ; 0 means process was found
        MessageBox MB_OK|MB_ICONEXCLAMATION "$(MSG_APP_RUNNING_UNINSTALL)"
        Abort
    ${EndIf}
    
    ; Remove entire installation directory and contents
    RMDir /r "$INSTDIR"
    
    ; Remove desktop shortcut
    ${If} ${FileExists} "$DESKTOP\$(APP_DISPLAY_NAME).lnk"
        Delete "$DESKTOP\$(APP_DISPLAY_NAME).lnk"
    ${EndIf}
    
    ; Remove Start Menu shortcuts
    ${If} ${FileExists} "$SMPROGRAMS\${APP_NAME}\$(APP_DISPLAY_NAME).lnk"
        Delete "$SMPROGRAMS\${APP_NAME}\$(APP_DISPLAY_NAME).lnk"
    ${EndIf}
    
    ${If} ${FileExists} "$SMPROGRAMS\${APP_NAME}\$(SHORTCUT_UNINSTALL).lnk"
        Delete "$SMPROGRAMS\${APP_NAME}\$(SHORTCUT_UNINSTALL).lnk"
    ${EndIf}
    
    RMDir "$SMPROGRAMS\${APP_NAME}"
    
    ; Remove registry entries
    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
    DeleteRegKey /ifempty HKCU "Software\${APP_NAME}"
    
    ; Show uninstall completion message
    MessageBox MB_OK "$(MSG_UNINSTALL_COMPLETE)"
SectionEnd

; ============================================
; Uninstaller Functions
; ============================================
Function un.onInit
    ; Restore language selected during installation
    !insertmacro MUI_UNGETLANGUAGE
    
    ; Confirm uninstallation
    MessageBox MB_YESNO|MB_ICONQUESTION "$(MSG_UNINSTALL_CONFIRM)" IDYES +2
    Abort
FunctionEnd