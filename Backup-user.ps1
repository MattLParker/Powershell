$storage = "\\nas007\users\"
$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$domain = get-content env:UserDomain
$user = $user.Replace($domain, "")
$user = $user.Replace("\", "")
$outname = $user + ".txt"
$userprofile = $env:USERPROFILE
$outfolder = $storage + $user
New-Item -ItemType directory -Path $outfolder | Out-Null
$out = $outfolder + "\" + $outname
$Userout = "Username: " + $user
$userout | out-file $out -Append   
"
Network Shares: "| out-file $out -Append   
Get-CimInstance -Class Win32_NetworkConnection | where-object {$_.LocalName -ne $null} | Select-Object LocalName, RemoteName| out-file $out -Append   
"
Printers: "| out-file $out -Append 

$fullprinters = get-printer 


$Printers = $fullprinters -notmatch 'PDF|Onenote|WebEx|Microsoft XPS|Fax' | select-object Name, DriverName, PortName 

$Printers | out-file $out -Append   
"
Taskbar: "| out-file $out -Append 

$taskpath = $env:APPDATA + "\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"

$Taskbar = get-childitem -path $taskpath | Foreach-Object {$_.BaseName}

$Taskbar | out-file $out -Append


"
Programs: "| out-file $out -Append 


$prog = @()
$UninstallKey = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall" 
$reg = [microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine', $computername) 
$regkey = $reg.OpenSubKey($UninstallKey) 
$subkeys = $regkey.GetSubKeyNames() 
foreach ($key in $subkeys) {

    $thisKey = $UninstallKey + "\\" + $key 

    $thisSubKey = $reg.OpenSubKey($thisKey) 

    $obj = New-Object PSObject

    $obj | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $($thisSubKey.GetValue("DisplayName"))

    $obj | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value $($thisSubKey.GetValue("DisplayVersion"))

    $obj | Add-Member -MemberType NoteProperty -Name "Publisher" -Value $($thisSubKey.GetValue("Publisher"))

    $prog += $obj

} 


$prog | Where-Object { $_.DisplayName } | Select-Object DisplayName, DisplayVersion, Publisher | Sort-object DisplayName |Format-Table -auto | out-file $out -Append   

#$chrome = $userprofile + "\AppData\Local\Google\Chrome\User Data\Default\"
#Robocopy.exe "`"$chrome'"" "`"$outfolder`"" bookmarks*


#WIP
#robocopy.exe $source $dest /E /ZB /R:0 /W:0 /XJ /NFL /XD appdata OneDrive “Temporary Internet Files” OfficeFileCache Temp *cache* Spotify WER /XF *cache* *.ost

