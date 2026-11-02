<#
.SYNOPSIS
Restores the gitignored thirdparty/ trees needed to build NX1 Reborn.

.DESCRIPTION
thirdparty/ is gitignored and therefore absent from a fresh clone. It cannot be
restored with `git submodule update`, because this repository has no top-level
.gitmodules file and rexglue-sdk/ + XenosRecomp/ are vendored copies without
their own .git directories.

The trees are taken from upstream ReXGlue commit e8ce24f ("Release v0.8.0"),
which is the base this fork's vendored SDK was derived from.

NOTE: thirdparty/ also contains 11 non-submodule directories that are absent
from any .gitmodules (aes_128, crypto, disasm, disruptorplus, dxbc, dxc,
ffmpeg-overlay, pe, picosha2, renderdoc, tiny-aes-c). Those come from the same
upstream commit and are restored by the extraction step below.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File tools\setup-thirdparty.ps1
#>
[CmdletBinding()]
param(
    [string]$RexglueCommit = 'e8ce24f',
    [string]$XenosCommit = 'HEAD',
    [switch]$SkipSymlinkFix
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$sdkDir  = Join-Path $repoRoot 'rexglue-sdk'
$xenDir  = Join-Path $repoRoot 'XenosRecomp'
$work    = Join-Path $env:TEMP 'nx1-reborn-thirdparty'
$stamp   = Join-Path $repoRoot '.thirdparty-restored'

if (Test-Path $stamp) {
    Write-Host "thirdparty/ already restored (marker: $stamp)." -ForegroundColor Green
    Write-Host 'Delete that file to force a re-restore.' -ForegroundColor DarkGray
    exit 0
}

# ---------------------------------------------------------------------------
function Invoke-Git {
    param([string[]]$GitArgs, [string]$Cwd, [string]$What)
    & git -C $Cwd @GitArgs
    if ($LASTEXITCODE -ne 0) { throw "git $What failed in $Cwd" }
}

function Restore-Tree {
    param(
        [string]$Name,
        [string]$DestRoot,
        [string]$UpstreamUrl,
        [string]$Commit
    )

    Write-Host "`n=== $Name ===" -ForegroundColor Cyan
    $tp = Join-Path $DestRoot 'thirdparty'
    if (Test-Path $tp) { Remove-Item $tp -Recurse -Force }

    if (Test-Path $work) { Remove-Item $work -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $work | Out-Null

    Write-Host "  cloning $UpstreamUrl ..."
    # Full clone: a blob:none/--depth clone cannot fetch an arbitrary SHA, and we
    # need the exact upstream commit this fork's vendored SDK was derived from.
    Invoke-Git @('clone', '--quiet', $UpstreamUrl, $work) $env:TEMP "clone $Name"

    $rev = $Commit
    if ($rev -ne 'HEAD') {
        Write-Host "  fetching $rev ..."
        & git -C $work cat-file -e "$rev^{commit}" 2>$null
        if ($LASTEXITCODE -ne 0) {
            Invoke-Git @('fetch', '--quiet', 'origin', $rev) $work 'fetch commit'
        }
    }

    # thirdparty/CMakeLists.txt and the non-submodule vendored dirs come from the tree itself.
    $tar = Join-Path $env:TEMP 'nx1-thirdparty.tar'
    if (Test-Path $tar) { Remove-Item $tar -Force }
    & git -C $work archive --format=tar -o $tar $rev thirdparty
    if ($LASTEXITCODE -ne 0) { throw "git archive failed for $Name" }

    $extract = Join-Path $env:TEMP 'nx1-thirdparty-extract'
    if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $extract | Out-Null
    & tar -xf $tar -C $extract
    if ($LASTEXITCODE -ne 0) { throw "tar extraction failed for $Name" }

    Move-Item (Join-Path $extract 'thirdparty') $tp
    Remove-Item $tar -Force -EA SilentlyContinue
    Remove-Item $extract -Recurse -Force -EA SilentlyContinue

    # Submodules are empty directories after archive; clone each at its pinned SHA.
    $urlMap = @{}
    $inPath = $false
    foreach ($line in Get-Content (Join-Path $DestRoot '.gitmodules')) {
        if ($line -match '^\s*path\s*=\s*(.+?)\s*$') { $inPath = $Matches[1] }
        elseif ($line -match '^\s*url\s*=\s*(.+?)\s*$' -and $inPath) { $urlMap[$inPath] = $Matches[1]; $inPath = $false }
    }

    $pinned = @()
    foreach ($line in (& git -C $work ls-tree $rev thirdparty/)) {
        if ($line -match '^160000 commit ([0-9a-f]{40})\s+(\S+)$') {
            $commit = $Matches[1]; $path = $Matches[2]
            if ($urlMap.ContainsKey($path)) {
                $pinned += [pscustomobject]@{ Path = $path; Url = $urlMap[$path]; Commit = $commit }
            }
        }
    }

    foreach ($s in $pinned) {
        $target = Join-Path $DestRoot $s.Path
        Write-Host ("  {0,-28} @{1}" -f ($s.Path -replace '^thirdparty/', ''), $s.Commit.Substring(0, 8))
        if (Test-Path $target) { Remove-Item $target -Recurse -Force -EA SilentlyContinue }
        & git clone --quiet --no-checkout --filter=blob:none $s.Url $target 2>&1 | Out-Null
        & git -C $target fetch --quiet origin $s.Commit 2>&1 | Out-Null
        & git -C $target checkout --quiet --force $s.Commit 2>&1 | Out-Null
    }
    Write-Host "  $($pinned.Count) submodules restored." -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
Restore-Tree -Name 'rexglue-sdk' -DestRoot $sdkDir -UpstreamUrl 'https://github.com/rexglue/rexglue-sdk' -Commit $RexglueCommit
Restore-Tree -Name 'XenosRecomp' -DestRoot $xenDir -UpstreamUrl 'https://github.com/hedge-dev/XenosRecomp' -Commit $XenosCommit

if (Test-Path $work) { Remove-Item $work -Recurse -Force -EA SilentlyContinue }

# ---------------------------------------------------------------------------
# Windows git checks out symlinks (mode 120000) as one-line text stubs.
# libmspack has 15 of these; they must become real file copies or compilation fails.
if (-not $SkipSymlinkFix) {
    Write-Host "`n=== symlink stubs ===" -ForegroundColor Cyan
    $fixed = 0
    $roots = @((Join-Path $sdkDir 'thirdparty'), (Join-Path $xenDir 'thirdparty'))
    foreach ($root in $roots) {
        if (-not (Test-Path $root)) { continue }
        $repos = @($root) + (Get-ChildItem $root -Directory -Recurse -Force -EA SilentlyContinue |
            Where-Object { Test-Path (Join-Path $_.FullName '.git') } | ForEach-Object FullName)
        foreach ($repo in $repos) {
            foreach ($e in (& git -C $repo ls-files -s 2>$null)) {
                if ($e -match '^120000 [0-9a-f]{40} \d+\t(.+)$') {
                    $link = Join-Path $repo $Matches[1]
                    if (-not (Test-Path $link)) { continue }
                    if ((Get-Item $link -Force).Length -gt 512) { continue }
                    $tgt = (Get-Content $link -Raw).Trim()
                    if ($tgt -notmatch '^\.\./') { continue }
                    $src = [IO.Path]::GetFullPath((Join-Path (Split-Path $link -Parent) $tgt))
                    if (-not (Test-Path $src)) { continue }
                    Copy-Item $src $link -Force
                    $fixed++
                }
            }
        }
    }
    Write-Host "  $fixed symlink stub(s) replaced with real files." -ForegroundColor DarkGray
}

New-Item -ItemType File -Force -Path $stamp | Out-Null
Write-Host "`nthirdparty/ restore complete." -ForegroundColor Green
Write-Host "Next: place your dump in nx1\ and follow the README build steps."
