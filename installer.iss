[Setup]
AppName=UNOclinic
AppVersion=1.0
DefaultDirName={pf}\UNOclinic
DefaultGroupName=UNOclinic
OutputDir=.
OutputBaseFilename=UNOclinic_Setup
Compression=lzma
SolidCompression=yes

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\UNOclinic"; Filename: "{app}\uno_clinic.exe"
Name: "{commondesktop}\UNOclinic"; Filename: "{app}\uno_clinic.exe"