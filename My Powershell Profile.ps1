Set-Location C:\users\user\Desktop
function email{
$ExchangePowerShell = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://mail.local.com/Powershell
Import-PSSession $ExchangePowerShell -AllowClobber -DisableNameChecking | Out-Null
}
function password($password){
$secureStringPwd = $password | ConvertTo-SecureString -AsPlainText -Force 
$secureStringText = $secureStringPwd | ConvertFrom-SecureString 
Set-Content "azure.txt" $secureStringText
}
function deleteemail{
    $search = Read-Host "Name of the search already started?"
   New-ComplianceSearchAction -SearchName $search -Purge -PurgeType SoftDelete 
}
function deleteemailstatus{
   Get-ComplianceSearchAction
}
Function disableusers{
    $date = Get-Date -format yy_MM_dd
import-module ActiveDirectory
Write-Host -ForegroundColor Green "Changing Display Names"
Get-ADUser -SearchBase "OU=To Be Disabled,OU=Disabled,DC=Conso,dc=local" -Filter * -Properties displayname| % {Set-ADUser -Identity $_ -DisplayName ($date + "_" + $_.displayname)}
Write-Host -ForegroundColor Green "Changing Descriptions"
Get-ADUser -SearchBase "OU=To Be Disabled,OU=Disabled,DC=Conso,dc=local" -Filter * -Properties displayname| % {Set-ADUser -Identity $_ -Description "Disabled Account"}
Write-Host -ForegroundColor Green "Changing Distinguished Names"
Get-ADUser -SearchBase "OU=To Be Disabled,OU=Disabled,DC=Conso,dc=local" -Filter * -Properties displayname| % {Rename-ADObject -Identity $_ -NewName ($date + "_" + $_.name)}
Write-Host -ForegroundColor Green "Removing Users From Global Address book"
Get-ADUser -SearchBase "OU=To Be Disabled,OU=Disabled,DC=Conso,dc=local" -Filter * -Properties displayname, mailnickname|set-aduser -replace @{msExchHideFromAddressLists="TRUE"}
$Users = Get-ADUser -filter * -SearchBase "OU=To Be Disabled,OU=Disabled,DC=Conso,dc=local" -Properties MemberOf
ForEach($User in $Users){
    $User.MemberOf | Remove-ADGroupMember -Member $User -Confirm:$false
}
Write-Host -ForegroundColor Green "Wait 10 seconds for Exchange"
start-sleep 10
Write-Host -ForegroundColor Green "O365"
#Import Required PowerShell Modules
Import-Module MSOnline
#Connect to Office 365 
Connect-MsolService -Credential $CloudCred
o365
Get-ADUser -SearchBase "OU=To Be Disabled,OU=Disabled,DC=Conso,dc=local" -Filter * -Properties displayname, mailnickname, Emailaddress| % {Set-Mailbox -Identity $_.emailaddress -Type shared}
Get-ADUser -SearchBase "OU=To Be Disabled,OU=Disabled,DC=Conso,dc=local" -Filter * -Properties displayname, mailnickname| % {Set-MsolUserLicense -UserPrincipalName $_.UserPrincipalName -RemoveLicenses maconbibb:ENTERPRISEPACK_GOV}
Write-Host -ForegroundColor Green "Disabling Users"
Get-ADUser -SearchBase "OU=To Be Disabled,OU=Disabled,DC=Conso,dc=local" -Filter *| Disable-ADAccount
Write-Host -ForegroundColor Green "Moving Users to User Folder"
Get-ADUser -SearchBase "OU=To Be Disabled,OU=Disabled,DC=Conso,dc=local" -Filter * -Properties displayname| % {Move-ADObject -Identity $_ -TargetPath "OU=Users,OU=Disabled,DC=Conso,dc=local"}
Write-Host -ForegroundColor Green "Update Offline Addressbook"
$ExchangePowerShell = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://mail.Conso.local/Powershell
Import-PSSession $ExchangePowerShell -AllowClobber -DisableNameChecking | Out-Null
Update-OfflineAddressBook -Identity "Default Offline Address Book"

Write-Host "Press any key to continue ..."

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

}
function o365{
Import-Module MSOnline
    
#Office 365 Admin Credentials
$CloudUsername = 'Username'
$pwdTxt = Get-Content "azure.txt"
$securePwd = $pwdTxt | ConvertTo-SecureString 
$CloudCred = New-Object System.Management.Automation.PSCredential $CloudUsername, $securePwd
    
#Connect to Office 365 
Connect-MsolService -Credential $CloudCred
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $CloudCred -Authentication Basic -AllowRedirection
Import-PSSession $Session
}
function compliance{
$CloudUsername = 'Username'
$pwdTxt = Get-Content "azure.txt"
$securePwd = $pwdTxt | ConvertTo-SecureString 
$CloudCred = New-Object System.Management.Automation.PSCredential $CloudUsername, $securePwd
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid -Credential $Cloudcred -Authentication Basic -AllowRedirection 
Import-PSSession $Session -AllowClobber -DisableNameChecking
}

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
Function desktop{
cd c:\users\username\desktop
}
Function onedrive{
cd "C:\Users\User\OneDrive\Powershell"
}

Function Azure{
# Lync Module Import
Import-Module LyncOnlineConnector
$LyncPowerShell = New-PSSession -ComputerName Azure.Conso.local
Import-PSSession $LyncPowerShell -AllowClobber | Out-Null
}
Function AzureSync{
invoke-command -computername Azure.Conso.local -ScriptBlock {Start-ADSyncSyncCycle -PolicyType Delta}
}
function Disable-InternetExplorerESC($Server) {
    invoke-command -computername $Server -ScriptBlock {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
    Stop-Process -Name Explorer -force
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled on $Server." -ForegroundColor Green
    }
}
function Enable-InternetExplorerESC($Server) {
    invoke-command -computername $Server -ScriptBlock {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 1
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 1
    Stop-Process -Name Explorer -force
    }
    Write-Host "IE Enhanced Security Configuration (ESC) has been enabled on $Server." -ForegroundColor Green
    
}
function Disable-UserAccessControl($Server) {
    invoke-command -computername $Server -ScriptBlock {
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000
    }
    Write-Host "User Access Control (UAC) has been disabled on $Server." -ForegroundColor Green    
    
}
new-alias laps Get-AdmPwdPassword
cls

