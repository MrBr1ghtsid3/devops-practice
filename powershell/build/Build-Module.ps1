#Requires -Version 7.4
<#
.SYNOPSIS
    Build gate. Merges Public + Private source into a single distributable
    module and refreshes the manifest's exported function list.

.DESCRIPTION
    The "merge" half of the two-pipeline pattern (your previous repo's
    "merge all scripts and functions into a singular module"). Concatenates
    every Private then Public .ps1 into one .psm1 in the output directory,
    copies the manifest, and updates FunctionsToExport from Public/*.ps1.

    Stub: concatenation and manifest update are marked TODO.

.EXAMPLE
    ./build/Build-Module.ps1 -OutputPath ./dist
#>
[CmdletBinding()]
param(
    [string] $SourcePath = "$PSScriptRoot/../src",
    [string] $OutputPath = "$PSScriptRoot/../dist",
    [string] $ModuleName = 'DevOpsToolkit'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$public  = @(Get-ChildItem "$SourcePath/public/*.ps1"  -ErrorAction SilentlyContinue)
$private = @(Get-ChildItem "$SourcePath/private/*.ps1" -ErrorAction SilentlyContinue)

# TODO: concatenate ($private + $public) bodies into "$OutputPath/$ModuleName.psm1"
#       wrap with a single Export-ModuleMember -Function <public basenames>

# TODO: copy manifest, then
#       Update-ModuleManifest -Path "$OutputPath/$ModuleName.psd1" `
#                             -FunctionsToExport $public.BaseName

Write-Host "Build stub: would merge $($private.Count) private + $($public.Count) public function(s) into $ModuleName." -ForegroundColor Yellow
