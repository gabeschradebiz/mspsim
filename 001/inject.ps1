[CmdletBinding()]
param(
[string[]]$RunItemNames=@("CL_AcmeUpdater","CL_ContosoChat"),
[string]$ScheduledTaskName="CL_FabrikamTelemetry",
[int]$DelaySeconds=90,
[string]$WorkDir="C:\ProgramData\CloudLabs\SlowBoot",
[string]$SlowScriptName="slowstart.ps1",
[string]$StartupLinkPath="C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\CloudLabsSlowStart.lnk"
)
$ErrorActionPreference='Stop'
try {
New-Item -Path $WorkDir -ItemType Directory -Force | Out-Null
$slowScriptPath = Join-Path $WorkDir $SlowScriptName
Set-Content -Path $slowScriptPath -Value "Start-Sleep -Seconds $DelaySeconds" -Encoding ASCII

$runPath="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
if (!(Test-Path $runPath)){ New-Item -Path $runPath -Force | Out-Null }
$approvedPath="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
if (!(Test-Path $approvedPath)){ New-Item -Path $approvedPath -Force | Out-Null }

$command = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "$slowScriptPath""
foreach ($name in $RunItemNames){
New-ItemProperty -Path $runPath -Name $name -Value $command -PropertyType String -Force | Out-Null
$enabled = byte[]
New-ItemProperty -Path $approvedPath -Name $name -PropertyType Binary -Value $enabled -Force | Out-Null
}

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "$slowScriptPath""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -GroupId "Users" -RunLevel LeastPrivilege
if (Get-ScheduledTask -TaskName $ScheduledTaskName -ErrorAction SilentlyContinue){
Set-ScheduledTask -TaskName $ScheduledTaskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
Enable-ScheduledTask -TaskName $ScheduledTaskName | Out-Null
} else {
Register-ScheduledTask -TaskName $ScheduledTaskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
}

$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($StartupLinkPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "$slowScriptPath""
$shortcut.WorkingDirectory = $WorkDir
$shortcut.WindowStyle = 7
$shortcut.Save()

Write-Output ("status=ok;run_items={0};task=enabled;link={1}" -f $RunItemNames.Count,$StartupLinkPath)
exit 0
} catch {
Write-Error ("error=" + $_.Exception.Message)
exit 1
}
