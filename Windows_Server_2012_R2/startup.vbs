Set WshShell = WScript.CreateObject("WScript.Shell")

const HKEY_LOCAL_MACHINE = &H80000002
const REG_SZ = 1
const REG_EXPAND_SZ = 2
const REG_BINARY = 3
const REG_DWORD = 4
const REG_MULTI_SZ = 7
Const ADS_SCOPE_SUBTREE = 2
const HKEY_CURRENT_USER = &H80000001
Set objConnection = CreateObject("ADODB.Connection")
Set objCommand =   CreateObject("ADODB.Command")
strComputer = "."

Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" &_
strComputer & "\root\default:StdRegProv")

deployprintxp = true
deploynet35 = true
deploynet40 = true
deploypdfreader = true
deployoffice2000 = true
deployfirefox = true
deploythunderbird = true

strKeyPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
oReg.EnumKey HKEY_LOCAL_MACHINE, strKeyPath, arrSubKeys

For Each subkey In arrSubKeys
	strSubKeyPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" & subkey
	oReg.EnumValues HKEY_LOCAL_MACHINE, strSubKeyPath,_
	 arrValueNames, arrValueTypes

	strDisplayName = ""
	strDisplayVersion = ""
	strPublisher = ""
	strQuietDisplayName = ""
	strInstallDate = ""
	strInstallSource = ""

	If not Isnull(arrValueNames) Then
		intWrite = 0
		For i=0 to ubound(arrValueNames)
'           StdOut.WriteLine "Value Name: " & arrValueNames(i)
			 Select Case arrValueTypes(i)
					Case REG_SZ
'                  StdOut.WriteLine "Data Type: String"
							strValueName = arrValueNames(i)
							oReg.GetStringValue HKEY_LOCAL_MACHINE,strSubKeyPath,strValueName,strValue
'                  StdOut.WriteLine "Data Value: '" & strValue & "'"
							Select Case strValueName
								Case "DisplayName"
									strDisplayName = strValue
									intWrite = 1
								Case "DisplayVersion"
									strDisplayVersion = strValue
									intWrite = 1
								Case "Publisher"
									strPublisher = strValue
									intWrite = 1
								Case "QuietDisplayName"
									strQuietDisplayName = strValue
									intWrite = 1
								Case "InstallDate"
									strInstallDate = strValue
									intWrite = 1
								Case InstallSource
									strInstallSource = strValue
									intWrite = 1
							End Select
					Case REG_EXPAND_SZ
'                  StdOut.WriteLine "Data Type: Expanded String"
					Case REG_BINARY
'                  StdOut.WriteLine "Data Type: Binary"
					Case REG_DWORD
'                  StdOut.WriteLine "Data Type: DWORD"
					Case REG_MULTI_SZ
'                  StdOut.WriteLine "Data Type: Multi String"
			End Select
'          StdOut.WriteBlankLines(1)
		Next
		If intWrite = 1 Then

			If InStr(strDisplayName, "Microsoft .NET Framework") > 0 Then
			'		WScript.Echo objItem.Version
				if InStr(strDisplayVersion,"3.5") then
					deploynet35 = false
				End If
				if InStr(strDisplayVersion,"4.0") then
					deploynet40 = false
				End If
			End If
			if InStr(strDisplayName, "Adobe Reader XI") > 0 then
				deploypdfreader = false
			End If
			if InStr(strDisplayName, "Microsoft Office 2000") > 0 then
				deployoffice2000 = false
			End If
			if InStr(strDisplayName, "Mozilla Firefox") > 0 then
				deployfirefox = false
			End If
			if InStr(strDisplayName, "Mozilla Thunderbird") > 0 then
				deploythunderbird = false
			End If
			if InStr(strDisplayName, "KB943729") > 0 then
				deployprintxp = false
			End If

		End If
'      Else
'      StdOut.WriteLine strComputer & Chr(9) & subKey & Chr(9) & "EMPTY!"
	End If
Next

if deploynet35 = true then
	WshShell.Run "\\alarasvr\Deployment\Microsoft_libraries\Windows-KB943729-x86-ENU.exe /q",1,true
End If

if deploynet35 = true then
	WshShell.Run "\\alarasvr\Deployment\Microsoft_libraries\dotNetFramework_3.5\dotNetFx35setup.exe /q",1,true
End If

if deploynet40 = true then
	WshShell.Run "\\alarasvr\Deployment\Microsoft_libraries\dotNetFx40_Full_x86_x64.exe /q /x86 /x64",1,true
End If

if deploypdfreader = true then
	WshShell.Run "\\alarasvr\Deployment\acrobat_reader\AdbeRdr11008_en_US.exe /sPB /rs",1,true
End If

if deployoffice2000 = true then
	WshShell.Run "\\alarasvr\Deployment\Microsoft_Office_2000_Premium\setup.exe TRANSFORMS=""\\alarasvr\Deployment\Microsoft_Office_2000_Premium\alara_wholefoods.MST"" PIDKEY=DT3FTBFH4MGYYH8PG9C38K2FJ /passive",1,true
End If

if deployfirefox = true then
	WshShell.Run "\\alarasvr\Deployment\Mozzila\firefox_setup.exe /S",1,true
End If

if deploythunderbird = true then
	WshShell.Run "\\alarasvr\Deployment\Mozzila\thunderbird_setup.exe /S",1,true
End If

'WScript.Echo "finished installing files"
