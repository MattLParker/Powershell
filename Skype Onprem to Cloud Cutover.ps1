get-aduser -filter 'msRTCSIP-DeploymentLocator -like "srv:"'|

Set-adUser -remove @{'msRTCSIP-DeploymentLocator'='srv:'} -add @{'msRTCSIP-DeploymentLocator'='sipfed.online.lync.com'}