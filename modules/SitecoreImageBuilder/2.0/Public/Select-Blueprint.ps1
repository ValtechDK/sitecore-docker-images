Set-StrictMode -Version 3.0

function Select-Blueprint
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [array]$InputObject
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [hashtable]$Matrix
    )

    Process
    {
        if (!$Matrix.ContainsKey("Versions"))
        {
            $Matrix.Versions = @()
        }

        if (!$Matrix.ContainsKey("Topologies"))
        {
            $Matrix.Topologies = @()
        }

        if (!$Matrix.ContainsKey("Variants"))
        {
            $Matrix.Variants = @()
        }

        if (!$Matrix.ContainsKey("Platforms"))
        {
            $Matrix.Platforms = @()
        }

        $versions = @($Matrix.Versions)
        $topologies = @($Matrix.Topologies)
        $variants = @($Matrix.Variants)
        $platforms = @($Matrix.Platforms)

        # TODO: handle dependencies, fx sxa-cm required spe-cm that requires cm. Maybe start with ignoring dependencies and resoleve in job

        $InputObject | ForEach-Object {
            $blueprint = $_

            if ($blueprint.SitecoreVersion.Name -ne "0.0.0")
            {
                if ($versions.Count -gt 0)
                {
                    $matchesVersion = @($versions | Where-Object { $blueprint.SitecoreVersion.Name -like "*$_*" }).Count -gt 0
                }
                else
                {
                    $matchesVersion = $false
                }
            }
            else
            {
                $matchesVersion = $true
            }

            if ($null -ne $blueprint.Topology)
            {
                if ($topologies.Count -gt 0)
                {
                    $matchesTopology = @($topologies | Where-Object { $blueprint.Topology -like "*$_*" }).Count -gt 0
                }
                else
                {
                    $matchesTopology = $false
                }
            }
            else
            {
                $matchesTopology = $true
            }

            $matchesVariant = $true
            # if ($blueprint.Type -eq "variant")
            # {
            #     if ($variants.Count -gt 0)
            #     {
            #         $matchesVariant = @($variants | Where-Object { $blueprint.VariantName -like "*$_*" }).Count -gt 0
            #     }
            #     else
            #     {
            #         $matchesVariant = $false
            #     }
            # }
            # else
            # {
            #     $matchesVariant = $true
            # }

            if ($platforms.Count -gt 0)
            {
                $matchesPlatform = @($platforms | Where-Object { $blueprint.Platform.Build -eq $_ -or $blueprint.Platform.Name -like "*$_*" -or $blueprint.Platform.Compatibility -like "*$_*" }).Count -gt 0
            }
            else
            {
                $matchesPlatform = $true
            }

            if ($matchesVersion -and $matchesTopology -and $matchesVariant -and $matchesPlatform )
            {
                Write-Output $blueprint
            }
        }
    }
}