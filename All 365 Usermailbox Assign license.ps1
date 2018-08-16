#Import Required PowerShell Modules
Import-Module MSOnline

#Connect to Office 365 
$CloudUsername = 'Username'
$pwdTxt = Get-Content "azure.txt"
$securePwd = $pwdTxt | ConvertTo-SecureString 
$CloudCred = New-Object System.Management.Automation.PSCredential $CloudUsername, $securePwd
Connect-MsolService -Credential $CloudCred

#Set Variables
$L = New-MsolLicenseOptions -AccountSkuId default:ENTERPRISEPACK
$usagelocation="US"
$SKU="default:ENTERPRISEPACK"

#The Magic Happens.
Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox | Get-MsolUser | 
ForEach-Object {set-msoluser -UserPrincipalName $_.UserPrincipalName -UsageLocation $UsageLocation
        Set-MsolUserLicense -UserPrincipalName $_.UserPrincipalName -addLicense $SKU
        Set-MsolUserLicense -UserPrincipalName $_.UserPrincipalName -LicenseOptions $L}

