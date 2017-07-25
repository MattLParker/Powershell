cls
Write-Host "Connecting to ActiveDirectory"

$DC = ($env:LOGONSERVER -replace “\\”, “”)
 
#Initiate Remote PS Session to local DC
$ADPowerShell = New-PSSession -ComputerName $DC -Authentication Default 
 
# Import-Module ActiveDirectory
Invoke-Command -Session $ADPowerShell -scriptblock {import-module ActiveDirectory}
Import-PSSession -Session $ADPowerShell -Module ActiveDirectory -AllowClobber -ErrorAction Stop
 
# Retrieve AD Details
$ADDetails = Get-ADDomain
$Domain = $ADDetails.DNSRoot
$Domainname = $ADDetails.Name

$ExchangeServer = Get-ADObject -Filter "(ServicePrincipalNAme -like 'IMAP*')" -SearchBase (Get-ADDomain).DistinguishedName.tostring()  -Properties ServiceDNSName, ServiceClassName | ForEach-Object {Write-Output $($_.Name + "." + $Domain)} | Get-Random
$usagelocation = "US"

cls
Write-Host "********************* NEW USER ***************** by Matt Parker"
Write-Host ""
Write-Host "Please enter the following required details:"
$FirstName = read-host "Firstname"
$FirstName = $FirstName.substring(0, 1).toupper() + $FirstName.substring(1).tolower()   
$MiddleName = read-host "Middle Name or Initial"
$MiddleName = $MiddleName.substring(0, 1).toupper() + $MiddleName.substring(1).tolower()  
$Surname = read-host "Lastname"
$Surname = $Surname.substring(0, 1).toupper() + $Surname.substring(1).tolower()  
$FirstInitial = $FirstName.Substring(0, 1)
$MiddleInitial = $MiddleName.Substring(0, 1)
$getolduser = Read-Host "User to copy from"
Get-aduser -Identity $getolduser -properties *|FL Name, Emailaddress, Description, Department, @{n = 'ParentContainer'; e = {$_.distinguishedname -replace '^.+?,(CN|OU.+)', '$1'}}
$correctuser = Read-Host "Is this the correct user to copy from? Y/N"
if ($correctuser -eq "y") {Write-Host "Awesome!"}
else {break}

$olduser = get-aduser -Identity $getolduser -Properties * | select-object samaccountname, memberof, @{n = 'ParentContainer'; e = {$_.distinguishedname -replace '^.+?,(CN|OU.+)', '$1'}} | ? { ($_.ParentContainer -notlike '*Builtin*')}
$ADPath = $olduser.ParentContainer
$groups = $olduser.memberof 
$groupstoadd = ForEach ($group in $groups) {get-adgroup $group}



# Detect if username already exists and create AD account
Write-Host -ForegroundColor Green "Creating new active directory user accounnt for $Firstname $Surname"
$ADAccountName = ($FirstInitial + $Surname)
$UserCheck = Get-ADUser -LDAPFilter "(sAMAccountName=$ADAccountName)"
If (($UserCheck) -eq $null) {
    write-host -ForegroundColor Green "Active Directory user account created"
    New-ADUser -DisplayName:($Surname + ", " + $FirstName) -GivenName:$FirstName -Name:($Surname + ", " + $FirstName) -Path:$ADPath -SamAccountName:$ADAccountName -Server:$DC -Surname:$Surname -Type:"user" -UserPrincipalName:($ADAccountName + "@" + $Domain) -EmailAddress:($ADAccountName + "@" + $Domain) -AccountPassword:(ConvertTo-SecureString "Welcome01" -AsPlainText -Force) -Enabled:$true
    Set-ADAccountControl -AccountNotDelegated:$false -AllowReversiblePasswordEncryption:$false -CannotChangePassword:$false -DoesNotRequirePreAuth:$false -Identity:$ADAccountName -PasswordNeverExpires:$false -Server:$DC -UseDESKeyOnly:$false
}
Else {
    $ADAccountName = Read-Host "The automatically generated username ($AdAccountName) for $FirstName $Surname already exists. Trying ($FirstInitial + $MiddleInitial + $Surname)" 
    $ADAccountName = ($FirstInitial + $MiddleInitial + $Surname)
    $UserCheck = Get-ADUser -LDAPFilter "(sAMAccountName=$ADAccountName)"
    If (($UserCheck) -eq $null) {
        New-ADUser -DisplayName:($Surname + ", " + $FirstName) -GivenName:$FirstName -Name:($Surname + ", " + $FirstName) -Path:$ADPath -SamAccountName:$ADAccountName -Server:$DC -Surname:$Surname -Type:"user" -UserPrincipalName:($ADAccountName + "@" + $Domain) -Description:$ADAccountName -EmailAddress:($ADAccountName + "@" + $Domain) -AccountPassword:(ConvertTo-SecureString "Welcome01" -AsPlainText -Force) -Enabled:$true
        Set-ADAccountControl -AccountNotDelegated:$false -AllowReversiblePasswordEncryption:$false -CannotChangePassword:$false -DoesNotRequirePreAuth:$false -Identity:$ADAccountName -PasswordNeverExpires:$false -Server:$DC -UseDESKeyOnly:$false
    }
    Else {
        $ADAccountName = Read-Host "The automatically generated username ($AdAccountName) for $FirstName $Surname also failed. Please Try something else"
        $UserCheck = Get-ADUser -LDAPFilter "(sAMAccountName=$ADAccountName)"
        If (($UserCheck) -eq $null) {
            New-ADUser -DisplayName:($Surname + ", " + $FirstName) -GivenName:$FirstName -Name:($Surname + ", " + $FirstName) -Path:$ADPath -SamAccountName:$ADAccountName -Server:$DC -Surname:$Surname -Type:"user" -UserPrincipalName:($ADAccountName + "@" + $Domain) -Description:$ADAccountName -EmailAddress:($ADAccountName + "@" + $Domain) -AccountPassword:(ConvertTo-SecureString "Welcome01" -AsPlainText -Force) -Enabled:$true
            Set-ADAccountControl -AccountNotDelegated:$false -AllowReversiblePasswordEncryption:$false -CannotChangePassword:$false -DoesNotRequirePreAuth:$false -Identity:$ADAccountName -PasswordNeverExpires:$false -Server:$DC -UseDESKeyOnly:$false
        }
        Else {
            Write-host "Name still matches. Please try again."
            break 
        }
    }
}
 
# Require password change on log on
Set-ADUser -ChangePasswordAtLogon:$true -Identity:$ADAccountName -Server:$DC -SmartcardLogonRequired:$false

# All AD groups
foreach ($grouptoadd in $groupstoadd) {add-adgroupmember -Identity $grouptoadd.Name -Members $ADAccountName -Server:$DC -Confirm:$false}
Add-ADGroupMember -Identity alluser -Members $ADAccountName -Server:$DC
Add-ADGroupMember -Identity "all users" -Members $ADAccountName -Server:$DC
Add-ADGroupMember -Identity "All MaconBibb Employees" -Members $ADAccountName -Server:$DC

# Exchange Mailbox creation
Write-Host -ForegroundColor Green "Creating new Microsoft Exchange mailbox for $Firstname $Surname"
$ExchangePowerShell = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchangeServer/Powershell
Import-PSSession $ExchangePowerShell -AllowClobber  -DisableNameChecking| Out-Null
$rdomain = ("@" + $Domainname + ".mail.onmicrosoft.com")
$365 = $ADAccountName + $rDomain
Enable-RemoteMailbox -remoteroutingaddress "$365"  -Identity $ADAccountName -Alias $ADAccountName | Out-Null
invoke-command -computername Azure -ScriptBlock {Start-ADSyncSyncCycle -PolicyType Delta}| Out-Null
Write-Host -ForegroundColor Yellow "Waiting 120 seconds for Exchange details to apply to Azure (O365)"
sleep -Seconds 120
 

#assign 365 liscense

Write-host -ForegroundColor red "Please login to Azure to add license"

#Attempt to connect to Office 365 if function is in profile o365 else do it the slow way
Try{o365}
catch {Import-Module MSOnline
Connect-MsolService}

#Set License Info
$upn = (Get-ADUser $ADAccountName| Select-object UserPrincipalName)
$SKU = (Get-MsolAccountSku | where-object ($_.SkuPartNumber -Like "Enterprise*") | Select-object AccountSkuId)
Set-MsolUser -UserPrincipalName $upn.UserPrincipalName -UsageLocation $usagelocation
Set-MsolUserLicense -UserPrincipalName $upn.UserPrincipalName -AddLicenses $SKU.AccountSkuId



# Notification variables
$ExchangeSMTP = "mail"
$CreatedBy = Get-ADUser "$env:username" -properties Mail
$email = ($ADAccountName + "@" + $Domain)
# Notify Admin
$searcher = [adsisearcher]"(samaccountname=$env:USERNAME)"
$emailcreate = $searcher.FindOne().Properties.mail
$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient($ExchangeSMTP)
$msg.From = "$($CreatedBy.Mail)"
$msg.To.Add("$emailcreate")
$msg.subject = "$email Created"
$msg.body = "$($CreatedBy.Name) has created a new user account for $FirstName $Surname. Username: $email Password is Welcome01" 
$msg.priority = [System.Net.Mail.MailPriority]::Low
$smtp.Send($msg)
 
sleep -Seconds 
 
# Confirm User Account Creation
cls
Write-Host -ForegroundColor Green "********************* NEW USER CREATION COMPLETE *****************"
Write-Host ""
Write-Host -ForegroundColor Green "Displaying Active Directory Account Details"
Get-ADUser $ADAccountName
Get-remoteMailbox -Identity $ADAccountName | ft DisplayName, PrimarySMTPAddress
 
Write-Host -ForegroundColor Green "Password = Welcome01"
 
# Remove Remote PowerShell Sessions
Get-PSSession | remove-pssession
sleep -Seconds 10