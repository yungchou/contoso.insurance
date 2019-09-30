param($domain, $password)

Start-Transcript  "C:\deploy-ad-log.txt"

$smPassword = (ConvertTo-SecureString $password -AsPlainText -Force)

# Set up DNS and Domain Controller
# Last step triggers a reboot
Write-Output "Installing Domain Services"
Install-WindowsFeature -Name "AD-Domain-Services" `
                       -IncludeManagementTools `
                       -IncludeAllSubFeature 

Write-Output "Installing DNS"
Install-WindowsFeature -Name DNS -IncludeManagementTools

Write-Output "Installing ADDSForest"
Install-ADDSForest -DomainName $domain `
                   -DomainMode Win2012 `
                   -ForestMode Win2012 `
                   -Force `
                   -SafeModeAdministratorPassword $smPassword `
                   -NoRebootOnCompletion

Write-Output "Restarting"
Stop-Transcript
Restart-Computer
