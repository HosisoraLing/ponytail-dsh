#Requires -Version 5.1
<#
.SYNOPSIS
  Install or remove the ponytail-dsh adapter for DeepSeek Harness (dsh).
.EXAMPLE
  pwsh -File install.ps1
  pwsh -File install.ps1 -Uninstall
.NOTES
  Installs the six ponytail skills into $DSH_HOME/skills and the managed
  AGENTS.md block into $DSH_HOME/AGENTS.md. The block is marker-delimited, so
  content you wrote yourself survives install and uninstall.
#>
[CmdletBinding()]
param(
    [switch]$Uninstall,
    [string]$DshHome = $(if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $HOME '.dsh' })
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$names = 'ponytail', 'ponytail-review', 'ponytail-audit', 'ponytail-debt', 'ponytail-gain', 'ponytail-help'
$begin = '<!-- ponytail-dsh:begin'
$end = '<!-- ponytail-dsh:end -->'

function Remove-ManagedBlock([string]$text) {
    $start = $text.IndexOf($begin)
    $stop = $text.IndexOf($end)
    if ($start -lt 0 -or $stop -lt 0) { return $text }
    $text.Remove($start, $stop + $end.Length - $start).TrimEnd() + "`n"
}

$skillsRoot = Join-Path $DshHome 'skills'
$target = Join-Path $DshHome 'AGENTS.md'
$flag = Join-Path $DshHome '.ponytail-active'

if ($Uninstall) {
    foreach ($name in $names) {
        $dir = Join-Path $skillsRoot $name
        if (Test-Path $dir) { Remove-Item -Recurse -Force $dir; Write-Host "removed $dir" }
    }
    if (Test-Path $target) {
        $kept = Remove-ManagedBlock (Get-Content -Raw $target)
        if ($kept -match '\S') {
            Set-Content -Path $target -Value $kept -NoNewline -Encoding utf8
            Write-Host "cleaned $target"
        }
        else {
            Remove-Item $target; Write-Host "removed $target"
        }
    }
    if (Test-Path $flag) { Remove-Item $flag; Write-Host "removed $flag" }
    Write-Host 'ponytail-dsh uninstalled'
    exit 0
}

New-Item -ItemType Directory -Force -Path $skillsRoot | Out-Null
foreach ($name in $names) {
    # Remove the destination first: Copy-Item nests the source inside an
    # existing directory instead of replacing it.
    $dest = Join-Path $skillsRoot $name
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Copy-Item -Recurse -Force (Join-Path $here "skills\$name") $dest
}

$block = (Get-Content -Raw (Join-Path $here 'AGENTS.md')).TrimEnd() + "`n"
$kept = ''
if (Test-Path $target) { $kept = Remove-ManagedBlock (Get-Content -Raw $target) }
if ($kept -match '\S') {
    Set-Content -Path $target -Value ($kept.TrimEnd() + "`n`n" + $block) -NoNewline -Encoding utf8
}
else {
    Set-Content -Path $target -Value $block -NoNewline -Encoding utf8
}

Write-Host "skills  -> $skillsRoot\$($names -join ', ')"
Write-Host "rules   -> $target (managed block '<!-- ponytail-dsh:begin -->')"
Write-Host "level   -> $flag (lite|full|ultra|off, written on level switch)"
Write-Host 'ponytail-dsh installed'
