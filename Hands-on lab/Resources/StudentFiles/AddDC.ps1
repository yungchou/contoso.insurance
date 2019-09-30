param($user, $password, $domain)

Start-Transcript "C:\AddDC-log.txt"

# Format data disk
Write-Output "Format data disk"
$disk = Get-Disk | ? { $_.PartitionStyle -eq "RAW" }
Initialize-Disk -Number $disk.DiskNumber -PartitionStyle GPT
New-Partition -DiskNumber $disk.DiskNumber -UseMaximumSize -DriveLetter F
Format-Volume -DriveLetter F -FileSystem NTFS -NewFileSystemLabel DATA

# Create credentials objects
Write-Output "Create credentials objects"
$smPassword = (ConvertTo-SecureString $password -AsPlainText -Force)
$cred = new-object -typename System.Management.Automation.PSCredential `
         -argumentlist $user, $smPassword

# Install AD
Write-Output "Install AD"
Install-WindowsFeature -Name "AD-Domain-Services" `
                       -IncludeManagementTools `
                       -IncludeAllSubFeature 

# Promote this machine to be a Domain Controller, attached to existing domain
Write-Output "Promote to DC"
Install-ADDSDomainController -DomainName $domain `
                             -NoGlobalCatalog:$false `
                             -CreateDnsDelegation:$false `
                             -Credential $cred `
                             -CriticalReplicationOnly:$false `
                             -DatabasePath "F:\Windows\NTDS" `
                             -InstallDns:$true `
                             -LogPath "F:\Windows\NTDS" `
                             -NoRebootOnCompletion:$false `
                             -SiteName "Default-First-Site-Name" `
                             -SysvolPath "F:\Windows\SYSVOL" `
                             -Force:$true `
                             -SafeModeAdministratorPassword $smPassword 

Stop-Transcript