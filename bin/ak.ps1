# ak - API Key Manager for PowerShell
# Uses Windows Credential Manager via precompiled CredManager.dll

$global:AK_DIR = "$env:USERPROFILE\tools\api-keys"
$global:SERVICES_DIR = "$AK_DIR\services"
$global:CRED_PREFIX = "ak:"  # Prefix for credential targets
$global:AK_SCRIPT_DIR = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$global:CREDMANAGER_DLL = Join-Path $AK_SCRIPT_DIR 'CredManager.dll'
$global:CREDMANAGER_SOURCE = Join-Path $AK_SCRIPT_DIR 'CredManager.cs'
$global:CREDMANAGER_BUILD = Join-Path $AK_SCRIPT_DIR 'build-credmanager.ps1'

# Load precompiled helper assembly (rebuild only when source changes)
if (-not ([System.Management.Automation.PSTypeName]'CredManager').Type) {
    $needsBuild = -not (Test-Path $CREDMANAGER_DLL)
    if (-not $needsBuild -and (Test-Path $CREDMANAGER_SOURCE)) {
        $needsBuild = (Get-Item $CREDMANAGER_SOURCE).LastWriteTimeUtc -gt (Get-Item $CREDMANAGER_DLL).LastWriteTimeUtc
    }

    if ($needsBuild) {
        if (-not (Test-Path $CREDMANAGER_BUILD)) {
            throw "CredManager build script not found: $CREDMANAGER_BUILD"
        }
        & $CREDMANAGER_BUILD | Out-Null
    }

    if (-not (Test-Path $CREDMANAGER_DLL)) {
        throw "CredManager.dll not found: $CREDMANAGER_DLL"
    }

    Add-Type -Path $CREDMANAGER_DLL
}

function global:Get-AkSecret {
    param([string]$Service)

    $target = "$CRED_PREFIX$Service"
    $secret = [CredManager]::Read($target)

    if ($null -eq $secret) {
        Write-Error "No secret for: $Service"
        return
    }

    return $secret
}

function global:Set-AkSecret {
    param(
        [string]$Service,
        [string]$Value
    )

    if (-not $Value) {
        $secure = Read-Host "Enter secret for '$Service'" -AsSecureString
        $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        $Value = [Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }

    $target = "$CRED_PREFIX$Service"
    $result = [CredManager]::Write($target, $Value, $Service)

    if ($result) {
        Write-Host "[OK] Stored: $Service" -ForegroundColor Green
    } else {
        Write-Error "Failed to store secret for: $Service"
    }
}

function global:Remove-AkSecret {
    param([string]$Service)

    $target = "$CRED_PREFIX$Service"
    $result = [CredManager]::Delete($target)

    if ($result) {
        Write-Host "[OK] Removed: $Service" -ForegroundColor Green
    } else {
        Write-Error "Failed to remove secret for: $Service (may not exist)"
    }
}

function global:Get-AkEnvVar {
    param([string]$Service)

    $serviceFile = Join-Path $SERVICES_DIR "$Service.yaml"
    if (Test-Path $serviceFile) {
        $line = Get-Content $serviceFile | Select-String '^env_var:\s*' | Select-Object -First 1
        if ($line) {
            return (($line.Line -replace '^env_var:\s*', '') -replace '^"|"$', '').Trim()
        }
    }

    return (($Service -replace '-','_').ToUpper() + "_API_KEY")
}

function global:Get-AkList {
    Write-Host "Configured services:"

    if (-not (Test-Path $SERVICES_DIR)) {
        Write-Host "  (no services directory)"
        return
    }

    Get-ChildItem "$SERVICES_DIR\*.yaml" -ErrorAction SilentlyContinue | ForEach-Object {
        $name = $_.BaseName
        $target = "$CRED_PREFIX$name"
        $hasSecret = $null -ne [CredManager]::Read($target)
        $mark = if ($hasSecret) { "[x]" } else { "[ ]" }
        $envVar = Get-AkEnvVar $name
        Write-Host "  $mark $name -> $envVar"
    }
}

function global:Load-ApiKeys {
    if (-not (Test-Path $SERVICES_DIR)) {
        Write-Host "No services directory found" -ForegroundColor Yellow
        return
    }

    Get-ChildItem "$SERVICES_DIR\*.yaml" -ErrorAction SilentlyContinue | ForEach-Object {
        $name = $_.BaseName
        $target = "$CRED_PREFIX$name"
        $value = [CredManager]::Read($target)

        if ($null -ne $value) {
            $envVar = Get-AkEnvVar $name
            Set-Item -Path "env:$envVar" -Value $value
            Write-Host "[OK] Loaded $envVar" -ForegroundColor Green
        }
    }
}

# Aliases
Set-Alias -Name ak-get -Value Get-AkSecret
Set-Alias -Name ak-set -Value Set-AkSecret
Set-Alias -Name ak-rm -Value Remove-AkSecret
Set-Alias -Name ak-list -Value Get-AkList
Set-Alias -Name load-api-keys -Value Load-ApiKeys

Write-Host "ak (Windows Credential Manager) loaded. Commands: ak-get, ak-set, ak-rm, ak-list, load-api-keys" -ForegroundColor Cyan
