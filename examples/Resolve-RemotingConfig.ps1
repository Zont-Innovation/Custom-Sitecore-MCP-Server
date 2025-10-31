[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] $RemotingConfig
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$config = if (-not [string]::IsNullOrWhiteSpace($remotingConfig)) {
    $remotingConfig = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($remotingConfig))
    $remotingConfig | ConvertFrom-Json
} else {
    try {
        $configFile = Join-Path $PSScriptRoot "./config.LOCAL.json"
        Get-Content -Raw $configFile | ConvertFrom-Json
    }
    catch {
        Write-Error "Could not load config at '$configFile': $_"
        exit 1
    }
}
foreach ($p in 'connectionUri','username','SPE_REMOTING_SECRET') {
    if (-not $config.$p) {
        Write-Error "Missing '$p' in config.<ENV>.json"
        exit 1
    }
}

# Return the config object to the caller
Write-Output $config
