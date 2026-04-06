; Inno Setup Script for Marka
#define MyAppName "Marka"
#define MyAppVersion "3.3.6"


#define MyAppPublisher "Asniya"


#define MyAppURL "https://github.com/aimy1/Marka"
#define MyAppExeName "marka.exe"
#define MyAppIcon "resources\app_icon.ico"

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{5D8B4D4E-7C23-4B3F-9A5A-6A3B2D1E4C1A}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
; Remove the following line to run in administrative install mode (install for all users.)
PrivilegesRequired=lowest
OutputDir=..\..\
OutputBaseFilename=Marka-Installer-Windows-{#MyAppArch}
SetupIconFile={#MyAppIcon}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed={#MyAppArch}
ArchitecturesInstallIn64BitMode={#MyAppArch}
ChangesAssociations=yes


[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "chinesesimplified"; MessagesFile: "ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\{#MyAppArch}\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\build\windows\{#MyAppArch}\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\build\windows\{#MyAppArch}\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup: Boolean;
var
  UninstallString, Msg: String;
  ResultCode: Integer;
begin
  Result := True;
  // Deep search in both User and Machine registry for the AppId
  if RegQueryStringValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{5D8B4D4E-7C23-4B3F-9A5A-6A3B2D1E4C1A}_is1', 'UninstallString', UninstallString) or
     RegQueryStringValue(HKLM, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{5D8B4D4E-7C23-4B3F-9A5A-6A3B2D1E4C1A}_is1', 'UninstallString', UninstallString) then
  begin
    // Localized prompt based on selected installer language
    if ActiveLanguage = 'chinesesimplified' then
      Msg := '检测到系统中已安装旧版本的 Marka。建议先卸载旧版本以确保安装环境整洁。' + #13#10 + #13#10 + '是否现在执行卸载过程？'
    else
      Msg := 'An existing version of Marka was detected. It is recommended to uninstall the previous version before continuing.' + #13#10 + #13#10 + 'Would you like to uninstall it now?';

    if MsgBox(Msg, mbConfirmation, MB_YESNO) = IDYES then
    begin
      // Executing uninstaller with /SILENT flag to minimize friction
      Exec(RemoveQuotes(UninstallString), '/SILENT', '', SW_SHOW, ewWaitUntilTerminated, ResultCode);
    end;
  end;
end;

[Registry]
Root: HKA; Subkey: "Software\Classes\.md\OpenWithProgids"; ValueType: string; ValueName: "{#MyAppName}.md"; ValueData: ""; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\{#MyAppName}.md"; ValueType: string; ValueName: ""; ValueData: "Markdown Document"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\{#MyAppName}.md\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName},0"
Root: HKA; Subkey: "Software\Classes\{#MyAppName}.md\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""
Root: HKA; Subkey: "Software\Classes\Applications\{#MyAppExeName}\SupportedTypes"; ValueType: string; ValueName: ".md"; ValueData: ""
