#Requires -Version 7.4

function Verb-Noun {
    <#
    .SYNOPSIS
        [One-line description.]

    .DESCRIPTION
        FUNCTION TEMPLATE.
        Use for repeatable/looping logic that processes pipeline input and
        belongs inside the module (exported via Public/). Pipeline-aware by
        design — the process{} block runs once per input object.

    .PARAMETER InputObject
        [Accepts pipeline input.]

    .EXAMPLE
        1..3 | Verb-Noun

    .NOTES
        Author : Tsvetoslav Shalev
        Target : PowerShell 7+ (cross-platform)
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [object[]] $InputObject
    )

    begin {
        Set-StrictMode -Version Latest
        # One-time setup + prereq guard (Test-Prerequisite ...)
    }

    process {
        foreach ($item in $InputObject) {
            if ($PSCmdlet.ShouldProcess($item, 'Describe action')) {
                # TODO: per-item logic
            }
        }
    }

    end {
        # One-time teardown
    }
}
