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
    # Match the full line including leading indent and trailing newline
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

# Build key lists for chroma + luma families that have low/mid bands
# Chroma low (l1..l5) and mid (m1..m5), plus '-a' variants
$chromaBaseStems = @(
    'lib_chromadl1','lib_chromadl1a','lib_chromadl2','lib_chromadl2a',
    'lib_chromadl3','lib_chromadl3a','lib_chromadl4','lib_chromadl4a',
    'lib_chromadl5','lib_chromadl5a',
    'lib_chromadm1','lib_chromadm1a','lib_chromadm2','lib_chromadm2a',
    'lib_chromadm3','lib_chromadm3a','lib_chromadm4','lib_chromadm4a',
    'lib_chromadm5','lib_chromadm5a'
)

# Luma denoise sabre low (lumadlsabre l1..l5) + mid (lumadmsabre l1..l5), incl. a/b variants
$lumaBaseStems = @(
    'lib_lumadlsabre_l1','lib_lumadlsabre_l1a','lib_lumadlsabre_l1b',
    'lib_lumadlsabre_l2','lib_lumadlsabre_l2a','lib_lumadlsabre_l2b',
    'lib_lumadlsabre_l3','lib_lumadlsabre_l3a','lib_lumadlsabre_l3b',
    'lib_lumadlsabre_l4','lib_lumadlsabre_l4a','lib_lumadlsabre_l4b',
    'lib_lumadlsabre_l5','lib_lumadlsabre_l5a',
    'lib_lumadmsabre_l1','lib_lumadmsabre_l1b',
    'lib_lumadmsabre_l2','lib_lumadmsabre_l2a','lib_lumadmsabre_l2b',
    'lib_lumadmsabre_l3','lib_lumadmsabre_l3a','lib_lumadmsabre_l3b',
    'lib_lumadmsabre_l4','lib_lumadmsabre_l4a','lib_lumadmsabre_l4b',
    'lib_lumadmsabre_l5','lib_lumadmsabre_l5a'
)

# ---------- MAIN (bare key) ----------
$report.Add('=== MAIN (bare key) ===')
Set-Key 'lib_spatial_a_key'              '0.125'
Set-Key 'lib_colsatparam_shadow_ldr_key' '0.8'
Set-Key 'pref_gammacurve_preset_key'     '4'
foreach ($stem in $chromaBaseStems) { Set-Key ($stem + '_key') '1.25' }
foreach ($stem in $lumaBaseStems)   { Set-Key ($stem + '_key') '0.85' }

# ---------- TELE CROP (_key_2 clone of main) ----------
$report.Add('=== TELE CROP (_key_2) ===')
Set-Key 'lib_spatial_a_key_2'            '0.125'
Set-Key 'pref_gammacurve_preset_key_2'   '4'
foreach ($stem in $chromaBaseStems) { Set-Key ($stem + '_key_2') '1.25' }
foreach ($stem in $lumaBaseStems)   { Set-Key ($stem + '_key_2') '0.85' }

# ---------- UW (_key_3) ----------
$report.Add('=== UW (_key_3) ===')
Set-Key 'pref_gammacurve_preset_key_3'   '4'
Set-Key 'lib_colsatparam_shadow_key_3'   '0.3'
foreach ($stem in $chromaBaseStems) { Set-Key ($stem + '_key_3') '1.5'  }
foreach ($stem in $lumaBaseStems)   { Set-Key ($stem + '_key_3') '1.65' }

# DELETE UW WB constants so AWB profile 59 runs free
$report.Add('=== UW WB DELETIONS ===')
Remove-Key 'cw_rg_key_3'
Remove-Key 'cw_bg_key_3'
Remove-Key 'gr_key_3'
Remove-Key 'bg_key_3'
Remove-Key 'h_bg_key_3'

# Write back as UTF-8 NO BOM, preserving LF
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($file, $script:content, $utf8NoBom)

# Emit report
$report | ForEach-Object { Write-Output $_ }
Write-Output ''
Write-Output "TOTAL CHANGES: $changeCount"
