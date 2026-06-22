#Requires -Version 7.4

<#
    DevOpsToolkit root module.

    Loads Private helpers first, then Public functions, then exports only
    the Public surface. This is the development-time loader; the build
    script (build/build-module.ps1) flattens these into a single .psm1
    for distribution, mirroring the merge-pipeline pattern.
#>

$ErrorActionPreference = 'Stop'

# Resolve function files
$public  = @(Get-ChildItem -Path "$PSScriptRoot/public/*.ps1"  -ErrorAction SilentlyContinue)
$private = @(Get-ChildItem -Path "$PSScriptRoot/private/*.ps1" -ErrorAction SilentlyContinue)

# Dot-source private first (helpers), then public
foreach ($file in @($private + $public)) {
    try {
        . $file.FullName
    }
    catch {
        Write-Error "Failed to import function $($file.FullName): $_"
    }
}

# Export only the public function names
Export-ModuleMember -Function $public.BaseName
