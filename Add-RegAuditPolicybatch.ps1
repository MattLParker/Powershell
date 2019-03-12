<#
.SYNOPSIS
To Add all the needed Registry DACLS for Netwrix Windows Server Auditing.
.EXAMPLE
.\add-regauditpolicybatch.ps1 server1.someserver.com
#>
[CmdletBinding()]
param (
    [Array]$Servers = $( Read-Host "Server?" )
)

# If you want to create a batch do it here
# Example $servers = get-content servers.txt 
# or $servers = @("server1","server2")

foreach ($server in $servers) {
    invoke-command -ComputerName $server -ScriptBlock {
        function AddAuditToRegKey {
            param
            (
                [Parameter(Mandatory = $true)]
                [string]$key
            )

            Get-Acl $key -Audit | Format-List Path, AuditToString | Out-File -FilePath 'c:\temp\reg_before.txt' -Width 200 -Append
            $RegKey_ACL = Get-Acl $key
            $AccessRule = New-Object System.Security.AccessControl.RegistryAuditRule("Everyone", "SetValue,CreateSubKey,Delete,ChangePermissions,TakeOwnership", "ContainerInherit,ObjectInherit", "none", "Success")
            $RegKey_ACL.AddAuditRule($AccessRule)
            $RegKey_ACL | Set-Acl $key
            Get-Acl $key -Audit | Format-List Path, AuditToString | Out-File -FilePath 'c:\temp\reg_after.txt' -Width 200 -Append
        }
        $name = $env:COMPUTERNAME
        write-host "Starting to make changes on $name"
        AddAuditToRegKey HKLM:\SYSTEM
        write-host "SYSTEM is done"
        AddAuditToRegKey HKLM:\SOFTWARE
        write-host "SOFTWARE is done"
        New-PSDrive HKU Registry HKEY_USERS | out-null
        AddAuditToRegKey HKU:\.default
        write-host "USERS is done"
    }

}