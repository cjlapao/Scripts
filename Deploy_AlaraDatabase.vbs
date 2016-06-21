Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("Wscript.Shell")
Set oNetwork = CreateObject("WScript.Network")
Const Overwrite = True
Const objStartFolder = "\\alarasvr\database\application\latest_version"
Const CopyTo = "c:\Database"
Dim strHomeFolder, strHome, strUser
Dim intRunError, objShell, objFSO
Dim ver_source, ver_dest

install = False
ver_source = "0.0.0.0"
ver_dest = "0.0.0.0"
userName = LCase(oNetwork.UserName)
computerName =  LCase(oNetwork.ComputerName)

hasAccess = False
if objFSO.FileExists("C:\Program Files (x86)\Microsoft Office\Office\msaccess.exe") Then
  hasAccess = True
  msPath = """C:\Program Files (x86)\Microsoft Office\Office\msaccess.exe"""
  msPathIcon = "C:\Program Files (x86)\Microsoft Office\Office\msaccess.exe,1"
End If
if objFSO.FileExists("C:\Program Files\Microsoft Office\Office\msaccess.exe") Then
  hasAccess = True
  msPath = """C:\Program Files\Microsoft Office\Office\msaccess.exe"""
  msPathIcon = "C:\Program Files\Microsoft Office\Office\msaccess.exe,1"
End If

if hasAccess and userName <> "chris" and userName <> "katrina"  then
  if computerName <> "p1" and computerName <> "p2" then
    '  WScript.Echo(userName)
    ' Checking if the folder exists, if not we will create it
    If Not objFSO.FolderExists(CopyTo) Then
      objFSO.CreateFolder CopyTo
      install = True
      End If

    ' Loading source version
    Set objFolder = objFSO.GetFolder(objStartFolder)
    Set colFiles = objFolder.Files
    For Each objFile in colFiles
      i = InStr(objFile.Name,".ver")
      If i > 0 Then
        ver_source = left(objFile.Name,i-1)
      End If
    Next

    ' Loading destination version
    Set objFolder = objFSO.GetFolder(CopyTo)
    Set colFiles = objFolder.Files
    For Each objFile in colFiles
      i = InStr(objFile.Name,".ver")
      If i > 0 Then
        ver_dest = left(objFile.Name,i-1)
      End If
    Next

    if ver_source > ver_dest Then
      delfile = ver_dest&".ver"
      if objFSO.FileExists(CopyTo&"\"&delfile) Then
        objFSO.DeleteFile(CopyTo&"\"&delfile)
      End If
      install = True
    else
      install = False
    End If

    ' Installing the files if need be
    if install = true Then
      ' Start to copy all files
      strFile = objStartFolder&"\*.*"
      objFSO.CopyFile strFile, CopyTo, Overwrite
      ' Deleting the bat file if it exists already on the folder so we can create it
      if objFSO.FileExists(CopyTo&"\alara.bat") Then
        objFSO.DeleteFile(CopyTo&"\alara.bat")
      End If
      ' Testing the instalation of MS OFFICE on the folder
      if not objFSO.FileExists(CopyTo & "\alara.bat") then
        Set objFile = objFSO.CreateTextFile(CopyTo & "\alara.bat",true)
        if userName = "alex" then
          objFile.writeline(msPath & " ""C:\database\Alara.mdb"" /wrkgrp ""C:\database\ALARASYS.MDW"" /user alex ")
        else
          objFile.writeline(msPath & " ""C:\database\Alara.mdb"" /wrkgrp ""C:\database\ALARASYS.MDW"" /user priidu ")
        end if
        objFile.writeline("exit")
        objFile.close()
      end if
    End If

    ' Reseting the security on the files to be written by everyone
    If objFSO.FolderExists(CopyTo) Then
      intRunError = objShell.Run("%COMSPEC% /c Echo Y| cacls "& chr(34) _
      & CopyTo & chr(34) & " /t /e /c /g everyone:F ", 2, True)
      If intRunError <> 0 Then
        Wscript.Echo "Error assigning permissions for user " _
        & strUser & " to home folder " & strHomeFolder
        End If
    End If

    'Creating the shortcuts
    If objFSO.FolderExists(CopyTo) Then
      strHomeFolder = objShell.ExpandEnvironmentStrings("%USERPROFILE%")
      strPrograms = strHomeFolder & "\Start Menu\"
      strShortcutName = "Alara Database.lnk"

      If Not objFSO.FileExists(strPrograms + strShortcutName) Then
        set oMyShortcut = objShell.CreateShortcut(strPrograms + strShortcutName)
        oMyShortcut.TargetPath = CopyTo &"\alara.bat"
        oMyShortcut.IconLocation = msPathIcon
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
      strPrograms = objShell.SpecialFolders("DESKTOP") & "\"
      If Not objFSO.FileExists(strPrograms + strShortcutName) Then
        set oMyShortcut = objShell.CreateShortcut(strPrograms + strShortcutName)
        oMyShortcut.TargetPath = CopyTo &"\alara.bat"
        oMyShortcut.Arguments = " "
        oMyShortcut.IconLocation = msPathIcon
        oMyShortcut.WorkingDirectory = CopyTo
        oMyShortCut.Save
      End If
    End If
  End If
else
  if userName <> "chris" and userName <> "katrina" then
    WScript.Echo "You do not have office installed, please contact your administrator"
  end if
End if
