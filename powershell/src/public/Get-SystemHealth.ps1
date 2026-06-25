#Requires -Version 7.4

function Get-SystemHealth {
    <#
    .SYNOPSIS
        Returns a structured snapshot of host health. The example "own take"
        function — extends core PowerShell rather than a Windows-only module,
        so it runs on the Ubuntu host as well as Windows.

    .DESCRIPTION
        Equivalent role to the previous ActiveDirectory module's custom
        functions: built on an existing body of work (here the cross-platform
        core cmdlets and $PSVersionTable / runtime info) and extended into a
        single, consistent object the rest of the toolkit can consume.

        Body intentionally left as a stub for the placeholder.

    .OUTPUTS
        [pscustomobject] with at least: Hostname, OS, PSVersion, Uptime,
        MemoryUsedPercent, DiskUsedPercent.

    .EXAMPLE
        Get-SystemHealth | Format-List

    .NOTES
        Should call Test-Prerequisite where elevation/auth is needed.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [switch] $IncludeDisk
    )

    begin {
        # TODO: Test-Prerequisite -RequireElevation:$false (none needed for read-only health)
    }

    process {
        # TODO: implement cross-platform collection.
        #   - Hostname:  [System.Net.Dns]::GetHostName()
        #   - OS:        $PSVersionTable.OS / [System.Runtime.InteropServices.RuntimeInformation]
        #   - Uptime:    Get-Uptime
        #   - Memory:    /proc/meminfo on Linux vs CIM on Windows  <-- key divergence
        #   - Disk:      Get-PSDrive / Get-Volume — platform-aware

        [pscustomobject]@{
            Hostname          = $null
            OS                = $null
            PSVersion         = $PSVersionTable.PSVersion
            Uptime            = $null
            MemoryUsedPercent = $null
            DiskUsedPercent   = if ($IncludeDisk) { $null } else { 'skipped' }
        }
    }
}
