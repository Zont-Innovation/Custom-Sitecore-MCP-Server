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

    Write-Error "Could not load configuration, check .env file: $_"
    exit 1

}
foreach ($p in 'connectionUri','username','SPE_REMOTING_SECRET') {
    if (-not $config.$p) {
        Write-Error "Missing '$p' in config.<ENV>.json"
        exit 1
    }
}

# Return the config object to the caller
Write-Output $config
