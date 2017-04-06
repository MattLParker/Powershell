# Get all mailboxes
$Mailboxes = get-mailbox -ResultSize Unlimited;
 
$Mailboxes | foreach{
    for ($i=0;$i -lt $_.EmailAddresses.Count; $i++)
    {
        $address = $_.EmailAddresses[$i]
        if ($address -like "*.us" -or $address -like "x500*" -or $address -like "x400*" -or $address -like "*.local" -or $address -like "ccmail*")
        {
            Write-host($address.AddressString.ToString() | out-file addressesRemoved.txt -append )
            $_.EmailAddresses.RemoveAt($i)
            $i--
        }
    }
    Set-Mailbox -Identity $_.Identity -EmailAddresses $_.EmailAddresses
}