param($domain)

Start-Transcript  "C:\deploy-ad2-log.txt"

# Pause, otherwise DNS commands fail
Write-Output "Waiting 30 secs for server to warm up"
Start-Sleep 30

# Remove scheduled task so this script only runs once
Write-Output "Remove scheduled task"
Unregister-ScheduledTask -TaskName "SetDNSDynamicUpdate" -Confirm:$false

# Set DNS dynamic updates
Write-Output "Setting DNS dynamic updates for domain $domain"
Set-DnsServerPrimaryZone -Name $domain -DynamicUpdate NonsecureAndSecure

Stop-Transcript
