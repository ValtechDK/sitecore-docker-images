@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'SitecoreImageBuilder.psm1'

    # Version number of this module.
    ModuleVersion     = '2.0'

    # ID used to uniquely identify this module
    GUID              = 'c7c36578-0661-46c1-b11c-d271a41f3802'

    # Author of this module
    Author            = 'pbering'

    # Company or vendor of this module
    CompanyName       = ''

    # Copyright statement for this module
    Copyright         = ''

    # Description of the functionality provided by this module
    Description       = 'Commands for building Sitecore Docker images.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @("Invoke-Build", "Get-BuildJob", "Get-Blueprint", "Get-BuildSpecification")

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        PSData = @{

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/Sitecore/docker-images/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/Sitecore/docker-images'

        }
    }
}