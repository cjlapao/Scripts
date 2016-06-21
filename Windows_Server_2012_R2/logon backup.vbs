Const IT_GROUP         = "cn=it admin"
Const User_GROUP         = "cn=Domain Users"
Const Admin_GROUP         = "cn=Domain Admins"

Set wshNetwork = CreateObject("WScript.Network")
wshNetwork.MapNetworkDrive "j:", "\\alarasvr\Users\" & wshNetwork.UserName

wshNetwork.MapNetworkDrive "s:", "\\alarasvr\Database"

Set ADSysInfo = CreateObject("ADSystemInfo")
Set CurrentUser = GetObject("LDAP://" & ADSysInfo.UserName)
strGroups = LCase(Join(CurrentUser.MemberOf))

If InStr(strGroups, IT_GROUP) Then
	wshNetwork.MapNetworkDrive "g:","\\alarasvr\IT"

elseIf InStr(strGroups, User_GROUP) Then
	wshNetwork.MapNetworkDrive "h:","\\alarasvr\Scanner"

elseIf InStr(strGroups, User_GROUP) Then
	wshNetwork.MapNetworkDrive "h:","\\alarasvr\Users"
end if
