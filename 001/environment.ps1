[CmdletBinding()]
param(
    [Parameter()][ValidateRange(3,12)][int]$startup_count = 8,
    [Parameter()][ValidateRange(5,120)][int]$script_runtime_seconds = 20
)
$ErrorActionPreference = 'Stop'
try {
    $baseDir = 'C:\ProgramData\CLStartupBloat'
    if (-not (Test-Path -LiteralPath $baseDir)) {
        New-Item -ItemType Directory -Path $baseDir | Out-Null
    }

    $runKeyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
    if (-not (Test-Path -LiteralPath $runKeyPath)) {
        New-Item -Path $runKeyPath -Force | Out-Null
    }

    for ($i = 1; $i -le $startup_count; $i++) {
        $appName = "CLStart_App$($i)"
        $scriptPath = Join-Path $baseDir "CLBloat_App$($i).ps1"

        $scriptContent = @"
param([int]`$Seconds = $script_runtime_seconds)
try { Start-Process -FilePath "notepad.exe" -WindowStyle Minimized -ErrorAction SilentlyContinue | Out-Null } catch {}
`$sw = [Diagnostics.Stopwatch]::StartNew()
while (`$sw.Elapsed.TotalSeconds -lt `$Seconds) {
    [void][Math]::Sqrt((Get-Random -Minimum 1000 -Maximum 100000))
}
exit 0
"@

        Set-Content -LiteralPath $scriptPath -Value $scriptContent -Encoding UTF8

        $runValue = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -Seconds $script_runtime_seconds"
        New-ItemProperty -Path $runKeyPath -Name $appName -Value $runValue -PropertyType String -Force | Out-Null
    }
    exit 0
}
catch {
    Write-Error ("inject_failed: {0}" -f $_.Exception.Message)
    exit 1
}
