param(
    [string]$FindText      = "Sitecore",
    [string]$ReplaceText   = "SiteCore",
    [string]$ScopePaths    = "/sitecore/content"   # comma separated for multiple roots, for example "/sitecore/content/SiteA, /sitecore/content/SiteB"
)

$CaseSensitive = $true
$DryRun        = $false

Set-Location -Path $PSScriptRoot

$config = & "./Resolve-RemotingConfig.ps1" -RemotingConfig $remotingConfig

# Write-Output "ConnectionUri: $($config.connectionUri)"
# Write-Output "Username     : $($config.username)"
# Write-Output "SPE Remoting Secret : $($config.SPE_REMOTING_SECRET)"

Import-Module -Name SPE
$session = New-ScriptSession -ConnectionUri $config.connectionUri -Username $config.username -SharedSecret $config.SPE_REMOTING_SECRET
Invoke-RemoteScript -Session $session -ScriptBlock {


    $CaseSensitive = $true
    $DryRun        = $false


    if ([string]::IsNullOrWhiteSpace($Using:FindText)) { throw "Find cannot be empty." }

    # Prepare scope
    $paths = $Using:ScopePaths -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    if (-not $paths) { $paths = "/sitecore/content" }

    # Prepare regex
    $pattern = [regex]::Escape($Using:FindText)
    $regexOptions = if ($CaseSensitive) { [System.Text.RegularExpressions.RegexOptions]::None } else { [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }

    # Field types to update
    $allowedTypes = @("Single-Line Text","Multi-Line Text","Rich Text")

    # Counters
    $totalItems   = 0
    $itemsChanged = 0
    $fieldsChanged = 0
    $errCount = 0

    # Database
    $database = "master"

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Collect all items under scope, all languages, all versions
    $items = foreach ($root in $paths) {
        Get-ChildItem -Path "$database`:$root" -Recurse -Language * -ErrorAction SilentlyContinue
    }

    if (-not $items) { Write-Output "No items found in scope."; return }

    Write-Output "Scanning $($items.Count) items in $database. DryRun=$DryRun CaseSensitive=$CaseSensitive"

    # Faster bulk update and disable security
    $bulk = New-Object Sitecore.Data.BulkUpdateContext
    $sec  = New-Object Sitecore.SecurityModel.SecurityDisabler
    try {
        foreach ($item in $items) {
            $totalItems++

            if ($item.Paths.Path -like "/sitecore/system*") { continue }

            $itemHadHits = $false
            $fieldHitsOnItem = 0

            $versions = $item.Versions.GetVersions($true)
            if (-not $versions -or $versions.Count -eq 0) { $versions = @($item) }

            foreach ($ver in $versions) {
                $editStarted = $false

                foreach ($field in $ver.Fields) {
                    if ($null -eq $field) { continue }
                    if ($field.ReadOnly) { continue }
                    if ($field.Type -notin $allowedTypes) { continue }

                    $current = [string]$field.Value
                    if ([string]::IsNullOrEmpty($current)) { continue }

                    if ([regex]::IsMatch($current, $pattern, $regexOptions)) {
                        $newValue = [regex]::Replace($current, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $Using:ReplaceText }, $regexOptions)

                        if (-not $DryRun) {
                            if (-not $ver.Editing.IsEditing) { $ver.Editing.BeginEdit() | Out-Null; $editStarted = $true }
                            $field.Value = $newValue
                        }

                        $itemHadHits = $true
                        $fieldHitsOnItem++
                    }
                }

                if ($editStarted -and $ver.Editing.IsEditing) {
                    $ver.Editing.EndEdit() | Out-Null
                }
            }

            if ($itemHadHits) {
                $fieldsChanged += $fieldHitsOnItem
                $itemsChanged++
                Write-Output "[HIT] $($item.Paths.Path) [$($item.Language)] fields: $fieldHitsOnItem"
            }

            if ($totalItems % 200 -eq 0) {
                $pct = [int](100 * $totalItems / [math]::Max(1, $items.Count))
                Write-Progress -Activity "Processing items" -Status "$totalItems scanned, $itemsChanged items with hits" -PercentComplete $pct
            }
        }
    }
    catch {
        $errCount++
        Write-Warning "Error: $_"
    }
    finally {
        if ($bulk) { $bulk.Dispose() }
        if ($sec)  { $sec.Dispose() }
        $stopwatch.Stop()
    }

    Write-Output ""
    Write-Output "Done. Scanned items: $totalItems"
    Write-Output "Items with hits: $itemsChanged"
    Write-Output "Field replacements: $fieldsChanged"
    Write-Output "Dry run: $DryRun"
    Write-Output "Elapsed: $([int]$stopwatch.Elapsed.TotalSeconds)s"

}
Stop-ScriptSession -Session $session