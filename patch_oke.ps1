$ErrorActionPreference = 'Stop'
$file = 'C:\Users\WindowsSucks\Desktop\projects\lmc-configs\oke.xml'
$content = [System.IO.File]::ReadAllText($file)
$report = New-Object System.Collections.Generic.List[string]
$changeCount = 0

function Set-Key {
    param([string]$keyName, [string]$newValue)
    $pattern = '(<string name="' + [regex]::Escape($keyName) + '">)([^<]*)(</string>)'
    $rgx = [regex]$pattern
    $m = $rgx.Match($script:content)
    if (-not $m.Success) {
        $script:report.Add("MISS: $keyName (not present)")
        return
    }
    $oldVal = $m.Groups[2].Value
    if ($oldVal -eq $newValue) {
        $script:report.Add("SKIP: $keyName already = $newValue")
        return
    }
    $script:content = $rgx.Replace($script:content, '${1}' + $newValue + '${3}', 1)
    $script:report.Add("SET : $keyName : '$oldVal' -> '$newValue'")
    $script:changeCount++
}

function Remove-Key {
    param([string]$keyName)
    $pattern = '[ \t]*<string name="' + [regex]::Escape($keyName) + '">[^<]*</string>\r?\n'
    $rgx = [regex]$pattern
    $m = $rgx.Match($script:content)
    if (-not $m.Success) {
        $script:report.Add("MISS: $keyName (already absent)")
        return
    }
    $script:content = $rgx.Replace($script:content, '', 1)
    $script:report.Add("DEL : $keyName")
    $script:changeCount++
}

# SAFE CHANGES ONLY: pref_* keys (SharedPreferences, not LibPatcher targets)
# and deletion of decimal-valued WB constants for UW slot.
# All lib_* changes have been intentionally OMITTED because they go through
# LibPatcher.setValueHex which requires hex-encoded values, not decimal multipliers.

$report.Add('=== Gamma preset (pref_*) ===')
Set-Key 'pref_gammacurve_preset_key'    '4'
Set-Key 'pref_gammacurve_preset_key_2'  '4'
Set-Key 'pref_gammacurve_preset_key_3'  '4'

$report.Add('=== UW WB constant deletions (decimal-valued app prefs) ===')
Remove-Key 'cw_rg_key_3'
Remove-Key 'cw_bg_key_3'
Remove-Key 'gr_key_3'
Remove-Key 'bg_key_3'
Remove-Key 'h_bg_key_3'

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($file, $script:content, $utf8NoBom)

$report | ForEach-Object { Write-Output $_ }
Write-Output ''
Write-Output "TOTAL CHANGES: $changeCount"
