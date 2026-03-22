# tools/run_autotest.ps1
# Launches Foul Ward headlessly, runs the AutoTestDriver, and reports PASS/FAIL.
#
# Usage:
#   powershell -File "D:\Projects\Foul Ward\foul_ward_godot\foul-ward\tools\run_autotest.ps1"

param(
    [string]$GodotExe   = "D:\Apps\Godot\godot.exe",
    [string]$ProjectDir = "D:\Projects\Foul Ward\foul_ward_godot\foul-ward",
    [int]   $TimeoutSec = 300
)

$ErrorActionPreference = "Stop"

$logDir  = Join-Path $ProjectDir "tools"
$logFile = Join-Path $logDir "autotest_last_run.log"
$errFile = Join-Path $logDir "autotest_last_run.err"

if (-not (Test-Path $GodotExe)) {
    Write-Error "Godot executable not found: $GodotExe"
    exit 1
}
if (-not (Test-Path $ProjectDir)) {
    Write-Error "Project directory not found: $ProjectDir"
    exit 1
}

Write-Host ""
Write-Host "=== Foul Ward AutoTest ===" -ForegroundColor Cyan
Write-Host "  Godot  : $GodotExe"      -ForegroundColor DarkGray
Write-Host "  Project: $ProjectDir"     -ForegroundColor DarkGray
Write-Host "  Log    : $logFile"        -ForegroundColor DarkGray
Write-Host ""
Write-Host "Starting headless run (may take several minutes)..." -ForegroundColor Yellow
Write-Host ""

$quotedProject = "`"$ProjectDir`""
$godotArgs = @(
    "--headless",
    "--path", $quotedProject,
    "--",
    "--autotest"
)

$proc = Start-Process `
    -FilePath $GodotExe `
    -ArgumentList $godotArgs `
    -NoNewWindow `
    -RedirectStandardOutput $logFile `
    -RedirectStandardError  $errFile `
    -PassThru

Write-Host "Process PID: $($proc.Id)" -ForegroundColor DarkGray

$finished = $proc.WaitForExit($TimeoutSec * 1000)

if (-not $finished) {
    Write-Host "[ERROR] Timeout after ${TimeoutSec}s - killing process." -ForegroundColor Red
    $proc.Kill()
}

$exitCode = $proc.ExitCode

if (Test-Path $errFile) {
    $stderrContent = Get-Content $errFile -ErrorAction SilentlyContinue
    if ($stderrContent) {
        Add-Content $logFile ""
        Add-Content $logFile "=== STDERR ==="
        Add-Content $logFile $stderrContent
    }
    Remove-Item $errFile -ErrorAction SilentlyContinue
}

$log = Get-Content $logFile -ErrorAction SilentlyContinue

if (-not $log) {
    Write-Host "[ERROR] Log file is empty. Godot may have failed to start." -ForegroundColor Red
    exit 1
}

$log | ForEach-Object {
    if ($_ -match "^\[AUTOTEST\] PASS:")    { Write-Host $_ -ForegroundColor Green  }
    elseif ($_ -match "^\[AUTOTEST\] FAIL:") { Write-Host $_ -ForegroundColor Red   }
    elseif ($_ -match "^\[AUTOTEST\] TIMEOUT:") { Write-Host $_ -ForegroundColor Yellow }
    elseif ($_ -match "^\[AUTOTEST\]")       { Write-Host $_ -ForegroundColor Cyan  }
    else                                     { Write-Host $_                         }
}

$passCount    = @($log | Where-Object { $_ -match "^\[AUTOTEST\] PASS:" }).Count
$failCount    = @($log | Where-Object { $_ -match "^\[AUTOTEST\] FAIL:" }).Count
$timeoutCount = @($log | Where-Object { $_ -match "^\[AUTOTEST\] TIMEOUT:" }).Count

Write-Host ""
Write-Host "=== RESULTS ===" -ForegroundColor Cyan
Write-Host "  PASS   : $passCount"    -ForegroundColor Green
Write-Host "  FAIL   : $failCount"    -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host "  TIMEOUT: $timeoutCount" -ForegroundColor $(if ($timeoutCount -gt 0) { "Yellow" } else { "Green" })
Write-Host "  Exit   : $exitCode"     -ForegroundColor DarkGray
Write-Host ""

if ($failCount -eq 0 -and $timeoutCount -eq 0 -and $passCount -gt 0) {
    Write-Host "All $passCount tests PASSED." -ForegroundColor Green
    exit 0
} else {
    Write-Host "Test run had issues. Full log: $logFile" -ForegroundColor Red
    exit 1
}
