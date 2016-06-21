Const strFile = "\\alaranas\Share\IT\Alara_Systems\*.*"
Const Overwrite = True

Dim oFSO
Dim strHomeFolder, strHome, strUser
Dim intRunError, objShell, objFSO

Set oFSO = CreateObject("Scripting.FileSystemObject")

ProgramFile = "c:"
CopyTo = ProgramFile & "\Alara Systems"

If Not oFSO.FolderExists(CopyTo) Then
  oFSO.CreateFolder CopyTo
  oFSO.CopyFile strFile, CopyTo, Overwrite

End If
CreateObject("WScript.Shell").Run "\\alarasvr\SYSVOL\factory.alara.co.uk\scripts\Deploy_AlaraSystemsShortcut.vbs"

strHomeFolder = "C:\Alara Systems"

Set objShell = CreateObject("Wscript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")
If objFSO.FolderExists(strHomeFolder) Then
  intRunError = objShell.Run("%COMSPEC% /c Echo Y| cacls "& chr(34) _
    & strHomeFolder & chr(34) & " /t /e /c /g everyone:F ", 2, True)

  If intRunError <> 0 Then
    Wscript.Echo "Error assigning permissions for user " _
    & strUser & " to home folder " & strHomeFolder
 End If
End If
