@{
    # Module manifest for DevOpsToolkit
    # Validate with: Test-ModuleManifest ./src/DevOpsToolkit.psd1

    RootModule        = 'DevOpsToolkit.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '73b6d4a0-81ec-4fad-bb5f-250950fb4d4a'  # to regenerate, use: [guid]::NewGuid()
    Author            = 'Tsvetoslav Atanasov Shalev'
    CompanyName       = 'MrBr1ghtsid3'
    Copyright         = '(c) Tsvetoslav Atanasov Shalev. All rights reserved.'
    Description       = 'Custom cross-platform DevOps helper module. Own takes on and extensions of core PowerShell functionality.'

    # --- Compatibility target ---
    # Previous body of work targeted Windows PowerShell 5.1.
    # This module deliberately targets PowerShell 7+ and is cross-platform.
    PowerShellVersion = '7.4'
    CompatiblePSEditions = @('Core')

    # Dependencies the module expects to be present (prereqs managed at import).
    # RequiredModules   = @()   # e.g. @{ ModuleName = 'Az.Accounts'; ModuleVersion = '3.0.0' }

    # Populated by the build script from Public/*.ps1 — do not edit by hand.
    FunctionsToExport = @('Get-SystemHealth')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags         = @('DevOps', 'CrossPlatform', 'Linux', 'Automation')
            LicenseUri   = ''
            ProjectUri   = 'https://github.com/MrBr1ghtsid3/devops-practice'
            ReleaseNotes = 'Initial skeleton.'
        }
    }
}
