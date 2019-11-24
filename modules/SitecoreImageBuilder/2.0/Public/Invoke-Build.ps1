Set-StrictMode -Version 3.0

function Invoke-Build
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [hashtable]$InputObject
    )

    Process
    {
        # get blueprints from sketch
        $blueprints = Get-Blueprint -Path (Join-Path $PSScriptRoot "..\..\..\..\sketch.json")

        # select blueprints that matches the matrix
        $selectedBlueprints = $blueprints | Select-Blueprint -Matrix $InputObject

        $selectedBlueprints | Sort-Object -Property Type, Repository, SitecoreVersion, Platform, Topology, Role | Format-Table -Property SitecoreVersion, VariantVersion, DependencyVersion, Type, Repository, Topology, Role, Platform


        # get all specifications
        $specifications = (Join-Path $PSScriptRoot "..\..\..\..\windows"), (Join-Path $PSScriptRoot "..\..\..\..\linux") | Get-BuildSpecification
        # TODO: Find  dependencies from specifications, load find the blueprints and load the specifications and add them
        $specifications | Format-Table

        # get jobs from combatible specifications
        $jobs = Get-BuildJob -Blueprints $selectedBlueprints -Specifications $specifications

        $jobs | ForEach-Object {
            $job = $_

            $buildOptions = New-Object System.Collections.Generic.List[System.Object]
            $job.BuildOptions | ForEach-Object {
                $option = $_

                $buildOptions.Add($option)
            }

            if ($job.DockerEngine -eq "windows")
            {
                $buildOptions.Add("--isolation 'hyperv'")
            }

            $buildOptions.Add("--tag '$($job.Tag)'")
            $buildOptions.Add("--file '$($job.DockerFilePath)'")
            $buildCommand = "docker image build {0} '{1}'" -f ($buildOptions -join " "), $job.BuildContextPath

            Write-Host "$buildCommand`n"
        }

        # TODO: handle nonexisting stuff like matrix.version == 9.2.8, matrix.toplogy == xtx, matrix.variant == zzz yields nothing
        # TODO: foreach job use blueprint to update variables in options and base images
        # TODO: blueprint, job and spec should be classes?
        # TODO: Rename "mssql-developer-2017" to somthing prefixed with "sitecore-"?
        # NOTE: "requires"/dependencies/build order should come from build-args and NOT sketch
        # NOTE: Important that there are NO requirements on filesystem layout
    }
}