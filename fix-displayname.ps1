#Input New domain name
$newdomain = "test.com"
#input old Domain name
$oldDomain = "test.net"
#input a Network location that all systems can write to
$log = "\\server\share\"

$searcher = [adsisearcher]"(samaccountname=$env:USERNAME)"
$checkemail = $searcher.FindOne().Properties.mail

if ($checkemail -like "*$newdomain") {
    #Get outlook version
    $versionreg = reg query "HKEY_CLASSES_ROOT\outlook.Application\CurVer"
    $versionsplit = $versionreg -split "application."
    $ver = $versionsplit[4] + ".0"
    if ($versionsplit[4] -eq 14) {

        $rootSearch = "hkcu:\Software\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem\Profiles"
    }
    Else {
        #Get Profilenames
        $rootSearch = "hkcu:\Software\Microsoft\Office\" + $ver + "\Outlook\Profiles"
    }
    $dbname = get-childitem $rootSearch


    #Get Source code for folder
    foreach ($Profile in $dbname) {
    


        $importname = $Profile.name + "\9207f3e0a3b11019908b08002b2a56c2"
        $hex = reg query $importname /v 01023d00

        #Start extract folder name for actual email key
        $split = $hex -split "REG_BINARY    "
        $m = $split[3].Length 
        $m /= 32
        $n = 0
        while ($n -lt $m) {
            $v = (32 * $n)
            $test = $split[3].Substring($v, 32)

            #Pull Email key
            $exportname = $Profile.name + "\" + $test
            $testname = $exportname -replace "HKEY_CURRENT_USER", "hkcu:"
            $noerror = $null
            $noerror = Get-ItemProperty -Path $testname -name 001f3001 -ErrorAction SilentlyContinue      
            if ($null -ne $noerror) {
            
                $emailinhexfull = reg query $exportname /v 001f3001
 
                #Manipulate email to ACSII 
                $splitemail = $emailinhexfull -split "REG_BINARY    "
                $emailinhex = $splitemail[3] 
                $parsedwithnull = ($emailinhex -split "(..)"|Where-Object {$_}| ForEach-Object {[char][convert]::ToInt16($_, 16)}) -join ""
                $parsed = $parsedwithnull -replace ("\x00", "")
                if ($parsed -notlike "Public Folders*" -and $parsed -notlike "Outlook Data File" -and $parsed -notlike "Sharepoint Lists" -and $parsed -like "*@$olddomain") {
                    #Change EMail
                    $email = $parsed -replace "@.*", "@$newdomain"
                    $email2 = $email
                    #Readd the "null" Characters
                    $x = $email.Length
                    $i = $x
                    while ($i -gt 0) {
                        $email = $email.Insert($i, "`0")
                        $i --
                    }

                    #convert back to HEX
                    $c = $null
                    $b = $email.ToCharArray();
                    Foreach ($element in $b) {$c = $c + "" + [System.String]::Format("{0:X2}", [System.Convert]::ToUInt32($element))}

                    #Import Backin
                
                    reg add $exportname /f /v 001f3001 /t REG_BINARY /d $c

                    $date = (Get-date)
                    $outfile = "$date~$exportname~$parsed~$email2~$env:COMPUTERNAME~$c"
                    $outfile | out-file C:\temp\fix-displayname.log -Append -Encoding ascii
                    $outfile2 = "$date~$exportname~$parsed~$email2~$env:COMPUTERNAME~$c"
                    $netfq = $log + "fix-displayname.log"
                    $outfile2 | out-file $netfq -Append -Encoding ascii
                }
            }
            Else {}
            $n ++
        }
    }
}
else {
    $date = (Get-date)
    $outfile = "$date~~~~Email Not Changed, $checkemail"
    $outfile | out-file C:\temp\fix-displayname.log -Append -Encoding ascii
    $outfile2 = "$date~~~~Email Not Changed, $checkemail~$env:COMPUTERNAME"
    $netfq = $log + "fix-displayname.log"
    $outfile2 | out-file $netfq -Append -Encoding ascii\
}

