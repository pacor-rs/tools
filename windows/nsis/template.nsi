; NSIS 安装程序脚本 - 多语言版本
; 用于 Flutter 应用程序

; 严格错误检查
!pragma warning error all

Unicode True
ManifestDPIAware true
ManifestDPIAwareness PerMonitorV2

; 包含必要的库
!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "WordFunc.nsh"
!include "LogicLib.nsh"

; 应用程序信息定义
!define EXECUTABLE_NAME "{{EXECUTABLE_NAME}}"
!define APP_VERSION "{{APP_VERSION}}"
!define APP_URL "{{APP_URL}}"
!define APP_EXE "{{APP_EXE}}"
!define OUTPUT_DIR "{{OUTPUT_DIR}}"
!define FLUTTER_BUILT_DIR "{{FLUTTER_BUILT_DIR}}"

; ============================================
; 多语言宏配置，通过项目的配置文件生成
; 如 !insertmacro MUI_LANGUAGE "SimpChinese"
; ============================================
{{LANGUAGE_MACROS}}

; ============================================
; 多语言应用信息定义，通过项目的配置文件生成
; 这里定义的变量包括：
;    - 应用显示名称(APP_DISPLAY_NAME)
;    - 公司名称(APP_PUBLISHER)
; 如 LangString APP_DISPLAY_NAME ${LANG_SIMPCHINESE} "果果视频"
; ============================================
{{LANGUAGE_VERSION_INFO}}

; ============================================
; 多语言字符串导入
; 如 !include languages/English.nsh
; ============================================
{{LANGUAGE_INCLUDE}}

; 安装程序信息
Name "$(APP_DISPLAY_NAME) v${APP_VERSION}"
OutFile "${OUTPUT_DIR}\{{SETUP_FILENAME}}"

; 默认安装目录
InstallDir "$LOCALAPPDATA\${EXECUTABLE_NAME}"
InstallDirRegKey HKCU "Software\${EXECUTABLE_NAME}" "InstallDir"

; 请求用户权限
RequestExecutionLevel user

; ============================================
; 界面设置
; ============================================
!define MUI_ABORTWARNING
!define MUI_ICON "{{MUI_ICON}}"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; 显示所有语言，不受用户代码页限制
!define MUI_LANGDLL_ALLLANGUAGES

; 记住安装程序语言选择
!define MUI_LANGDLL_REGISTRY_ROOT "HKCU"
!define MUI_LANGDLL_REGISTRY_KEY "Software\${EXECUTABLE_NAME}"
!define MUI_LANGDLL_REGISTRY_VALUENAME "Installer Language"

; ============================================
; 安装程序页面
; ============================================
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; ============================================
; 卸载程序页面
; ============================================
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; ============================================
; 保留文件（固实压缩优化）
; ============================================
!insertmacro MUI_RESERVEFILE_LANGDLL

; ============================================
; 应用程序信息，通过项目的配置文件生成
; 如 VIAddVersionKey /LANG=${LANG_SIMPCHINESE} "ProductName" "果果视频"
; ===========================================
{{VERSION_INFO}}

; ============================================
; 安装部分
; ============================================
Section "$(SECTION_MAIN)" SecMain
    SectionIn RO
    
    SetOutPath "$INSTDIR"
    
    ; 复制应用程序文件
    File /r "${FLUTTER_BUILT_DIR}\*"
    
    ; 创建卸载程序
    WriteUninstaller "$INSTDIR\Uninstall.exe"
    
    ; 写入注册表信息
    WriteRegStr HKCU "Software\${EXECUTABLE_NAME}" "InstallDir" "$INSTDIR"
    WriteRegStr HKCU "Software\${EXECUTABLE_NAME}" "Version" "${APP_VERSION}"
    
    ; 添加到程序和功能
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${EXECUTABLE_NAME}" "DisplayName" "$(APP_DISPLAY_NAME)"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${EXECUTABLE_NAME}" "DisplayVersion" "${APP_VERSION}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${EXECUTABLE_NAME}" "Publisher" "$(APP_PUBLISHER)"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${EXECUTABLE_NAME}" "URLInfoAbout" "${APP_URL}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${EXECUTABLE_NAME}" "DisplayIcon" "$INSTDIR\${APP_EXE}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${EXECUTABLE_NAME}" "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${EXECUTABLE_NAME}" "QuietUninstallString" "$INSTDIR\Uninstall.exe /S"
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${EXECUTABLE_NAME}" "NoModify" 1
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${EXECUTABLE_NAME}" "NoRepair" 1
    
    ; 获取安装大小
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${EXECUTABLE_NAME}" "EstimatedSize" "$0"
SectionEnd

Section "$(SECTION_DESKTOP)" SecDesktop
    CreateShortcut "$DESKTOP\$(APP_DISPLAY_NAME).lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0
SectionEnd

Section "$(SECTION_STARTMENU)" SecStartMenu
    CreateDirectory "$SMPROGRAMS\${EXECUTABLE_NAME}"
    CreateShortcut "$SMPROGRAMS\${EXECUTABLE_NAME}\$(APP_DISPLAY_NAME).lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0
    CreateShortcut "$SMPROGRAMS\${EXECUTABLE_NAME}\$(SHORTCUT_UNINSTALL).lnk" "$INSTDIR\Uninstall.exe" "" "$INSTDIR\Uninstall.exe" 0
SectionEnd

; ============================================
; 安装程序函数
; ============================================
Function .onInit
    ; 显示语言选择对话框
    !insertmacro MUI_LANGDLL_DISPLAY

    ; 检查应用是否正在运行
    nsExec::ExecToStack 'tasklist /FI "IMAGENAME eq ${APP_EXE}" /NH'
    Pop $0
    Pop $1
    ${If} $1 != "INFO: No tasks are running which match the specified criteria."
        MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "$(MSG_APP_RUNNING)" IDOK +2
        Abort
    ${EndIf}
    
    ; 检查磁盘空间（至少需要 500MB）
    ${GetRoot} "$INSTDIR" $0
    ${DriveSpace} "$0\" "/D=F /S=M" $1
    ${If} $1 < 500
        MessageBox MB_OK|MB_ICONEXCLAMATION "$(MSG_INSUFFICIENT_SPACE)"
        Abort
    ${EndIf}
FunctionEnd

; ============================================
; 组件描述
; ============================================
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecMain} $(DESC_MAIN)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} $(DESC_DESKTOP)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecStartMenu} $(DESC_STARTMENU)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; 安装完成后的函数
Function .onInstSuccess
    MessageBox MB_YESNO "$(MSG_INSTALL_COMPLETE)" IDYES Launch
    Goto NoLaunch
    Launch:
        Exec '"$INSTDIR\${APP_EXE}"'
    NoLaunch:
FunctionEnd

; ============================================
; 卸载部分
; ============================================
Section "Uninstall"
    ; 检查应用是否正在运行
    nsExec::ExecToStack 'tasklist /FI "IMAGENAME eq ${APP_EXE}" /NH'
    Pop $0
    Pop $1
    ${If} $1 != "INFO: No tasks are running which match the specified criteria."
        MessageBox MB_OK|MB_ICONEXCLAMATION "$(MSG_APP_RUNNING_UNINSTALL)"
        Abort
    ${EndIf}
    
    ; 删除整个安装目录及其内容
    RMDir /r "$INSTDIR"
    
    ; 删除快捷方式（添加错误检查）
    ${If} ${FileExists} "$DESKTOP\$(APP_DISPLAY_NAME).lnk"
        Delete "$DESKTOP\$(APP_DISPLAY_NAME).lnk"
    ${EndIf}
    
    ${If} ${FileExists} "$SMPROGRAMS\${EXECUTABLE_NAME}\$(APP_DISPLAY_NAME).lnk"
        Delete "$SMPROGRAMS\${EXECUTABLE_NAME}\$(APP_DISPLAY_NAME).lnk"
    ${EndIf}
    
    ${If} ${FileExists} "$SMPROGRAMS\${EXECUTABLE_NAME}\$(SHORTCUT_UNINSTALL).lnk"
        Delete "$SMPROGRAMS\${EXECUTABLE_NAME}\$(SHORTCUT_UNINSTALL).lnk"
    ${EndIf}
    
    RMDir "$SMPROGRAMS\${EXECUTABLE_NAME}"
    
    ; 删除注册表项
    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${EXECUTABLE_NAME}"
    DeleteRegKey /ifempty HKCU "Software\${EXECUTABLE_NAME}"
    
    ; 显示完成消息
    MessageBox MB_OK "$(MSG_UNINSTALL_COMPLETE)"
SectionEnd

; ============================================
; 卸载程序函数
; ============================================
Function un.onInit
    ; 获取安装时选择的语言
    !insertmacro MUI_UNGETLANGUAGE
    
    ; 卸载前确认（这是正确的位置）
    MessageBox MB_YESNO|MB_ICONQUESTION "$(MSG_UNINSTALL_CONFIRM)" IDYES +2
    Abort
FunctionEnd