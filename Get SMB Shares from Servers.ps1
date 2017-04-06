$computer=get-adcomputer -filter 'OperatingSystem -like "*server*"'|
invoke-command -computername $computer.Name -scriptblock {Get-SmbShare}|
export-csv -path SMBshares.csv -NoTypeInformation
