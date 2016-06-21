Set wshNetwork = CreateObject("WScript.Network")
Set objFSO = CreateObject("Scripting.FileSystemObject")

If objFSO.FolderExists("\\alarasvr\users\" & wshNetwork.UserName) Then
	wshNetwork.MapNetworkDrive "r:", "\\alarasvr\Users\" & wshNetwork.UserName
End If

