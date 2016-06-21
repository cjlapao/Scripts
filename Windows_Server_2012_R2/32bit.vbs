Dim WshShell
Set WshShell = CreateObject("WScript.Shell")
Bits = GetObject("winmgmts:root\cimv2:Win32_Processor='cpu0'").AddressWidth
msgbox Bits
