        $user = "UPNHere"
        $addresses = (Get-Mailbox $user).EmailAddresses
        $upn = (Get-Mailbox $user).UserPrincipalName

        foreach ($address in $addresses) {
             try {
                  if ($address -like "*mail.onmicrosoft.com") {
                       $target = $address
                            }
                        }
                catch {}
                    }

        Get-ADUser $user | Set-ADUser -Clear homeMDB, homeMTA, mDBUseDefaults, msExchHomeServerName -Replace @{msExchVersion="88218628259840";msExchRecipientDisplayType="-2147483642";msExchRecipientTypeDetails="2147483648";msExchRemoteRecipientType="4";targetAddress=$target}
  