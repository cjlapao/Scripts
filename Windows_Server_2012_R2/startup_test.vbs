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

If Err.Number <> 0 Then
	StdOut.WriteLine strComputer & Chr(9) & Err.Description & Chr(9) & "" & Chr(9) & "" & _
	 Chr(9) & "" & Chr(9) & "" & Chr(9) & "" & Chr(9) & "" & Chr(9) & Now
	Err.Clear
Else
	strKeyPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
	oReg.EnumKey HKEY_LOCAL_MACHINE, strKeyPath, arrSubKeys
	For Each subkey In arrSubKeys

'      StdOut.WriteLine subkey
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
				If strDisplayName = "" Then
					strDisplayName = subKey
				End If
				WScript.Echo strComputer & Chr(9) & subKey & Chr(9) & strDisplayName & Chr(9) & _
				 strDisplayVersion & Chr(9) & strPublisher & Chr(9) & strQuietDisplayName & Chr(9) & _
				 strInstallDate & Chr(9) & strInstallSource
			End If
'      Else
'      StdOut.WriteLine strComputer & Chr(9) & subKey & Chr(9) & "EMPTY!"
		End If
	Next
End If
'WScript.Echo "finished installing files"
