#Requires -Version 7.4
<#
.SYNOPSIS
    Review gate. Runs PSScriptAnalyzer across the module source.

.DESCRIPTION
    The "review" half of the two-pipeline pattern. Intended to run in CI on
    every PR and locally before commit. Fails (non-zero exit) on any error- or
    warning-severity finding so it can act as a required status check.

.EXAMPLE
    ./build/Invoke-Lint.ps1
#>
[CmdletBinding()]
param(
    [string] $Path = "$PSScriptRoot/../src",
    [ValidateSet('Error', 'Warning', 'Information')]
    [string] $FailOn = 'Warning'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    throw 'PSScriptAnalyzer not installed. Install-Module PSScriptAnalyzer -Scope CurrentUser'
}

$results = Invoke-ScriptAnalyzer -Path $Path -Recurse

if ($results) {
    $results | Format-Table -AutoSize

    $severities = switch ($FailOn) {
        'Error'       { @('Error') }
        'Warning'     { @('Error', 'Warning') }
        'Information' { @('Error', 'Warning', 'Information') }
    }

    $blocking = $results | Where-Object { $_.Severity -in $severities }
    if ($blocking) {
        Write-Error "Lint gate failed: $($blocking.Count) finding(s) at or above '$FailOn'."
        exit 1
    }
}

Write-Host 'Lint gate passed.' -ForegroundColor Green
