param($domain, $password)

Start-Transcript  "C:\deploy-ad-log.txt"

$smPassword = (ConvertTo-SecureString $password -AsPlainText -Force)

# Download post-reboot script
Write-Output "Downloading post-reboot script"
$downloads = @( "https://cloudworkshop.blob.core.windows.net/building-resilient-iaas-architecture/lab-resources/script-extensions/deploy-ad2.ps1" )
$destinationFiles = @( "C:\deploy-ad2.ps1" )
Import-Module BitsTransfer
Start-BitsTransfer -Source $downloads -Destination $destinationFiles

# Configure post-reboot script to run
Write-Output "Creating scheduled task for post-reboot script"
$action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument "-executionPolicy Unrestricted -File C:\deploy-ad2.ps1 -domain $domain"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName "SetDNSDynamicUpdate" -Action $action -Trigger $trigger -Principal $principal

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
