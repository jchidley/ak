param(
    [switch]$Force
)

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$sourcePath = Join-Path $scriptDir 'CredManager.cs'
$dllPath = Join-Path $scriptDir 'CredManager.dll'

if (-not (Test-Path $sourcePath)) {
    throw "CredManager source not found: $sourcePath"
}

$needsBuild = $Force -or -not (Test-Path $dllPath)
if (-not $needsBuild) {
    $needsBuild = (Get-Item $sourcePath).LastWriteTimeUtc -gt (Get-Item $dllPath).LastWriteTimeUtc
}

if (-not $needsBuild) {
    Write-Host "CredManager.dll is up to date"
    return
}

if (Test-Path $dllPath) {
    Remove-Item $dllPath -Force
}

$source = Get-Content $sourcePath -Raw
Add-Type -TypeDefinition $source -Language CSharp -OutputAssembly $dllPath
Write-Host "[OK] Built $dllPath" -ForegroundColor Green
