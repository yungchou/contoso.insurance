param($password,
    $dbsource,
    $defaultDnsDomain = "contoso.com",
    $defaultDomain = $dnsDomain)

Start-Transcript "C:\deploy-sqlvm-log2.txt"

# The SPNs seem to end up in the wrong containers (COMPUTERNAME) as opposed to Domain user
# This is a bit of a hack to make sure it is straight. 
# See also: https://support.microsoft.com/en-sg/help/811889/how-to-troubleshoot-the-cannot-generate-sspi-context-error-message
Write-Output "Resetting SPNs"

$computer = $env:COMPUTERNAM
$dnsDomain = $env:USERDOMAIN
$user = $env:USERNAME

if ($dnsDomain.Contains(".")) {
	$domain = $dnsDomain.Substring(0,$dnsDomain.IndexOf("."))
}
else{
    $domain = $dnsDomain
}

$spn1 = "MSOLAPSvc.3/" + $computer + "." + $dnsDomain
$spn2 = $domain + "\" + $computer + "$"
SetSPN -s "$spn1" "$spn2"
$spn1 = "MSOLAPSvc.3/" + $computer
SetSPN -s "$spn1" "$spn2"
$spn1 = "MSSQLSvc/" + $computer + "." + $dnsDomain 
SetSPN -d "$spn1" "$spn2"
$spn2 = $domain + "\" + $user
SetSPN -s "$spn1" "$spn2"
$spn1 = "MSSQLSvc/" + $computer + "." + $dnsDomain + ":1433"
$spn2 = $domain + "\" + $computer + "$"
SetSPN -d "$spn1" "$spn2"
$spn2 = $domain + "\" + $user
SetSPN -s "$spn1" "$spn2"



SetSPN -s ("MSOLAPSvc.3/" + $computer + "." + $dnsDomain + " " + $domain + "\" + $computer)
SetSPN -s ("MSOLAPSvc.3/" + $computer + " " + $domain + "\" + $computer)
SetSPN -d ("MSSQLSvc/" + $computer + "." + $dnsDomain + " " + $domain + "\" + $computer)
SetSPN -s "MSSQLSvc/$computer.$dnsDomain"
SetSPN -d "MSSQLSvc/$computer.$dnsDomain`:1433"
SetSPN -s "MSSQLSvc/$computer.$dnsDomain`:1433"

# For secondary servers, we skip restoring the DB. So check first if DB was specified
if (($null -ne $dbsource) -and ($dbsource -ne "")) {
    # Get the Contoso Insurance database backup 
    $dbdestination = "D:\ContosoInsurance.bak"
    Write-Output "Download $dbsource to $dbdestination"
    Invoke-WebRequest $dbsource -OutFile $dbdestination
    powershell -ExecutionPolicy Unrestricted "[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; Invoke-WebRequest -uri  $dbsource -OutFile $dbdestination"

    # Restore the database from the backup
    Write-Output "Restore the database from backup"
    $mdf = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("ContosoInsurance", "F:\Data\ContosoInsurance.mdf")
    $ldf = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("ContosoInsurance_Log", "F:\Logs\ContosoInsurance.ldf")
    Restore-SqlDatabase -ServerInstance Localhost -Database ContosoInsurance `
                        -BackupFile $dbdestination -RelocateFile @($mdf,$ldf) -ReplaceDatabase

    # Put the database into full recovery and run a backup (required for SQL AG)
    Write-Output "Put into full recovery and run backup"
    Invoke-Sqlcmd -ServerInstance Localhost -Database "master" -Query "ALTER DATABASE ContosoInsurance SET RECOVERY FULL"
    Backup-SqlDatabase -ServerInstance Localhost -Database ContosoInsurance
} else {
    Write-Output "No source database specified"
}

# Disable IE Enhanced Security Configuration
Write-Output "Disable IE Enhanced Security"
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"

New-Item -Path $adminKey -Force
New-Item -Path $UserKey -Force
New-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
New-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0

$HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\1"
$HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\1"
Set-ItemProperty -Path $HKLM -Name "1803" -Value 0
Set-ItemProperty -Path $HKCU -Name "1803" -Value 0
$HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2"
$HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2"
Set-ItemProperty -Path $HKLM -Name "1803" -Value 0
Set-ItemProperty -Path $HKCU -Name "1803" -Value 0
$HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
$HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
Set-ItemProperty -Path $HKLM -Name "1803" -Value 0
Set-ItemProperty -Path $HKCU -Name "1803" -Value 0
$HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\4"
$HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\4"
Set-ItemProperty -Path $HKLM -Name "1803" -Value 0
Set-ItemProperty -Path $HKCU -Name "1803" -Value 0
$HKLM = "HKLM:\Software\Microsoft\Internet Explorer\Security"
New-ItemProperty -Path $HKLM -Name "DisableSecuritySettingsCheck" -Value 1 -PropertyType DWORD

Write-Output "All done"

Stop-Transcript