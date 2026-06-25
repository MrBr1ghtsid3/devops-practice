#Requires -Version 7.4
<#
.SYNOPSIS
    [One-line description.]

.DESCRIPTION
    STANDALONE SCRIPT TEMPLATE.
    Use for one-shot administrative tasks that run to completion and are NOT
    expected to run concurrently or loop. For repeatable/looping logic, use
    Function.Template.ps1 instead and ship it inside the module.

.PARAMETER Example
    [Describe parameters.]

.EXAMPLE
    ./Verb-Noun.ps1 -Example 'value'

.NOTES
    Author : Tsvetoslav Shalev
    Target : PowerShell 7+ (cross-platform)
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string] $Example
)

begin {
    $ErrorActionPreference = 'Stop'
    Set-StrictMode -Version Latest

    # Environment expectations declared up front:
    #   - elevation? cert? MI/SP auth? Guard here before doing work.
}

process {
    if ($PSCmdlet.ShouldProcess($Example, 'Describe action')) {
        # TODO: implement
    }
}

end {
    # TODO: cleanup / summary output
}
