Dim oShell

Set oFSO = CreateObject("Scripting.FileSystemObject")
set oShell = CreateObject("WScript.Shell")
Set oNetwork = CreateObject("WScript.Network")


strHomeFolder = oShell.ExpandEnvironmentStrings("%USERPROFILE%")
strPrograms = strHomeFolder & "\Start Menu\"
strShortcutName = "Alara Systems.lnk"
CopyTo = ProgramFile & "\Alara Systems"

If Not oFSO.FileExists(strPrograms + strShortcutName) Then
  set oMyShortcut = oShell.CreateShortcut(strPrograms + strShortcutName)
  oMyShortcut.TargetPath = CopyTo &"\alara_systems.exe"
  oMyShortcut.Arguments = " "
  oMyShortcut.WorkingDirectory = CopyTo
  oMyShortCut.Save
End If

Set sa   = CreateObject("Shell.Application")
Set fldr = sa.NameSpace(strPrograms)
Set lnk  = fldr.ParseName(strShortcutName)
For Each verb In lnk.Verbs
  If verb.Name = "Pin to Tas&kbar" Then verb.DoIt()
Next

' Setting up the Desktop shortcut
strPrograms = strHomeFolder & "\Desktop\"
If Not oFSO.FileExists(strPrograms + strShortcutName) Then
  set oMyShortcut = oShell.CreateShortcut(strPrograms + strShortcutName)
  oMyShortcut.TargetPath = CopyTo &"\alara_systems.exe"
  oMyShortcut.Arguments = " "
  oMyShortcut.WorkingDirectory = CopyTo
  oMyShortCut.Save
End If
