# ak - API Key Manager for PowerShell
# Requires: age installed and in PATH

$AK_DIR = "$env:USERPROFILE\tools\api-keys"
$SECRETS_DIR = "$AK_DIR\secrets"
$SERVICES_DIR = "$AK_DIR\services"
$KEY_FILE = "$AK_DIR\key.age"

function Get-AkSecret {
    param([string]$Service)
    
    $secretFile = "$SECRETS_DIR\$Service.age"
    if (-not (Test-Path $secretFile)) {
        Write-Error "No secret for: $Service"
        return
    }
    
    # Decrypt the key, then use it to decrypt the secret
    $identity = age -d $KEY_FILE 2>$null
    $identity | age -d -i - $secretFile 2>$null
}

function Set-AkSecret {
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
    
    # Get public key
    $publicKey = (age -d $KEY_FILE 2>$null | Select-String "public key:").ToString().Split(": ")[1]
    
    if (-not (Test-Path $SECRETS_DIR)) {
        New-Item -ItemType Directory -Path $SECRETS_DIR -Force | Out-Null
    }
    
    $Value | age -r $publicKey -o "$SECRETS_DIR\$Service.age"
    Write-Host "✓ Stored: $Service" -ForegroundColor Green
}

function Get-AkList {
    Write-Host "Configured services:"
    Get-ChildItem "$SERVICES_DIR\*.yaml" -ErrorAction SilentlyContinue | ForEach-Object {
        $name = $_.BaseName
        $hasSecret = Test-Path "$SECRETS_DIR\$name.age"
        $mark = if ($hasSecret) { "✓" } else { " " }
        Write-Host "  $mark $name"
    }
}

function Load-ApiKeys {
    Get-ChildItem "$SERVICES_DIR\*.yaml" -ErrorAction SilentlyContinue | ForEach-Object {
        $name = $_.BaseName
        $secretFile = "$SECRETS_DIR\$name.age"
        if (Test-Path $secretFile) {
            $envVar = ($name -replace '-','_').ToUpper() + "_API_KEY"
            $value = Get-AkSecret $name
            Set-Item -Path "env:$envVar" -Value $value
            Write-Host "✓ Loaded $envVar" -ForegroundColor Green
        }
    }
}

# Aliases
Set-Alias -Name ak-get -Value Get-AkSecret
Set-Alias -Name ak-set -Value Set-AkSecret
Set-Alias -Name ak-list -Value Get-AkList
Set-Alias -Name load-api-keys -Value Load-ApiKeys

Write-Host "ak (age-based) loaded. Commands: ak-get, ak-set, ak-list, load-api-keys" -ForegroundColor Cyan
