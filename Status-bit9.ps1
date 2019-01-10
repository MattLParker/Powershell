    <#
.SYNOPSIS
A script to run immediately after deploying the Bit9 Carbon Black Protect Agent during OS deployment 
and wait for it to complete the initial cache before proceeding.
#>


Write-host (get-date)
$start = (get-date)
#Wait to make sure Bit9 Started
start-sleep -seconds 120

do {
    #Check for timeout
    $tolate = ((get-date) -gt ($start.AddMinutes(40)))
    #break if time is hit
    if ($tolate){Break}
    Write-Host "Sleeping 30 Seconds"
    Start-sleep -seconds 30
    #get status
    $status =  & 'C:\Program Files (x86)\Bit9\Parity Agent\DasCLI.exe' status
    #match if completed
    $Check = $status -match "Initialized"

} While ($null -like $check)

Write-host (get-date)
Write-host "Finished"





