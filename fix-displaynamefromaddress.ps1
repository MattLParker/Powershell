$newemaildomain = "newdomain.com"
$log = "\\server\share\"
#filename for log
$netfq = $log + "fix-displayname.log"

#Get outlook version
$versionreg = reg query "HKEY_CLASSES_ROOT\outlook.Application\CurVer"
$versionemail = $versionreg -split "application."
$ver = $versionemail[4] + ".0"
if ($versionemail[4] -eq 14) {

    $rootSearch = "hkcu:\Software\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem\Profiles"
}
Else {
    #Get Profilenames
    $rootSearch = "hkcu:\Software\Microsoft\Office\" + $ver + "\Outlook\Profiles"
}
$dbname = get-childitem $rootSearch


#Get Source code for folder
foreach ($Profile in $dbname) {
    
    $getci = $Profile.name + "\9375CFF0413111d3B88A00104B2A6676"
    $getci = $getci -replace "HKEY_CURRENT_USER", "hkcu:"
    $folders = get-childitem $getci
    foreach ($Folder in $folders) {
        if ($versionemail[4] -eq 14) {
            $d = reg query $folder /v "Account name"
            $email = reg query $folder /v "Account name"
            $email = $email -split "REG_BINARY    "
            $email = $email[3] 
            $email = ($email -split "(..)"|Where-Object {$_}| ForEach-Object {[char][convert]::ToInt16($_, 16)}) -join ""
            $email = $email -replace ("\x00", "")
            $email = $email -replace "@.*", "@$newemaildomain"
            $emailfromreg = $email
            $test = $null
            $test = (([adsisearcher]"(mail=$email)").findall()).properties
                if ($test) {

                $x = $email.Length
                    $i = $x
                    $email = $email.Insert($i, "`0`0")
                    while ($i -gt 0) {
                        $email = $email.Insert($i, "`0")
                        $i --
                    }

                    #convert back to HEX
                    $c = $null
                    $b = $email.ToCharArray();
                    Foreach ($element in $b) {$c = $c + "" + [System.String]::Format("{0:X2}", [System.Convert]::ToUInt32($element))}

                    #Import Backin
                
                    reg add $Folder /f /v "Account name" /t REG_BINARY /d $c
                $date = (Get-date)
                "$date~$folder~$emailfromreg~$newemail~$env:COMPUTERNAME~$c~$d"| out-file C:\temp\fix-displayname.log -Append -Encoding ascii
                "$date~$folder~$emailfromreg~$newemail~$env:COMPUTERNAME~$c~$d"| out-file $netfq -Append -Encoding ascii
            }
            Else {
                $date = (Get-date)
               "$date~$folder~$newemail~not changed~$env:COMPUTERNAME"| out-file C:\temp\fix-displayname.log -Append -Encoding ascii
               "$date~$folder~$newemail~not changed~$env:COMPUTERNAME"| out-file $netfq -Append -Encoding ascii
            }
        }
        Else {
        $email = reg query $folder /v "Account name"
        $email = $email -split "REG_SZ    "
        $newemail = $email[3] -replace "@.*", "@$newemaildomain"
        $emailfromreg = $email[3]
        $test = $null
        $test = (([adsisearcher]"(mail=$email)").findall()).properties

        if ($test) {
            reg add $folder /f /v "Account name" /t REG_SZ /d $newemail
            $date = (Get-date)
            "$date~$folder~$emailfromreg~$newemail~$env:COMPUTERNAME"| out-file C:\temp\fix-displayname.log -Append -Encoding ascii
            "$date~$folder~$emailfromreg~$newemail~$env:COMPUTERNAME"| out-file $netfq -Append -Encoding ascii
        }
        Else {
            $date = (Get-date)
           "$date~$folder~$newemail~not changed~$env:COMPUTERNAME"| out-file C:\temp\fix-displayname.log -Append -Encoding ascii
           "$date~$folder~$newemail~not changed~$env:COMPUTERNAME"| out-file $netfq -Append -Encoding ascii
        }
        }



        

    }

}
