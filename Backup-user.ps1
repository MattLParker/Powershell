$storage = "H:\temp\"
$BackupFolders = @("Documents","Pictures","Desktop","Links","Videos")


$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$domain = get-content env:UserDomain
$user = $user.Replace($domain, "")
$user = $user.Replace("\", "")
$outname = $user + ".txt"
$userprofile = $env:USERPROFILE
$outfolder = $storage + $user
try { get-item $outfolder -ErrorAction stop | Out-Null}
catch [System.Management.Automation.ItemNotFoundException]{
    New-Item -ItemType directory -Path $outfolder | Out-Null
}
write-host "Starting TXT file"
$out = $outfolder + "\" + $outname
$Userout = "Username: " + $user
$userout | out-file $out -Append   
"
HostName: "| out-file $out -Append
$env:computername | out-file $out -Append

Get-NetIPAddress | Where-object addressstate -EQ preferred| Select-Object IPAddress | out-file $out -Append
"Network Shares: "| out-file $out -Append   
Get-CimInstance -Class Win32_NetworkConnection | where-object {$_.LocalName -ne $null} | Select-Object LocalName, RemoteName| out-file $out -Append   
"
Printers: "| out-file $out -Append 

$fullprinters = get-printer 


$Printers = $fullprinters -notmatch 'PDF|Onenote|WebEx|Microsoft XPS|Fax|ImageRight|Document Converter' | select-object Name, DriverName, PortName 

$Printers | out-file $out -Append   
"
Taskbar: "| out-file $out -Append 

$taskpath = $env:APPDATA + "\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"

$Taskbar = get-childitem -path $taskpath | Foreach-Object {$_.BaseName}

$Taskbar | out-file $out -Append


"
Programs: "| out-file $out -Append 

write-host "Getting Installed Apps"
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

#Chrome Backup
if (test-path "$userprofile\appdata\local\google\"){
    write-host "Backing up Chrome Bookmarks"
$chrome = $userprofile + "\AppData\Local\Google\Chrome\User Data"
Get-ChildItem $chrome -include Bookmarks* -Recurse | copy-item -Destination $outfolder
}
#PST backup
write-host "Killing Outlook/Skype/Teams to backup all psts in $userprofile"
get-process *outlook* | Stop-Process
get-process *teams* | Stop-Process
get-process *Lync* | Stop-Process
get-process *skype* | Stop-Process
Write-host "Finding and coping all .psts"
get-childitem $userprofile -name -File -include *.pst -recurse -force| 
Write-host "Backing up user Data Folders"
foreach ($folder in $BackupFolders) {
    copy-item "$userprofile\$folder" "$outfolder\$folder" -Recurse
}
