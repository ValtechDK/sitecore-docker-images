Set-StrictMode -Version 3.0

function Get-BuildSpecification
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript( { Test-Path $_ -PathType "Container" })]
        [string]$Path
    )

    Process
    {
        Set-StrictMode -Off

        # load specifications
        Get-ChildItem -Path $Path -Recurse -File -Include "build.json" | ForEach-Object {
            $buildJsonPath = $_.FullName
            $buildContextPath = $_.Directory.FullName
            $data = Get-Content -Path $buildJsonPath | ConvertFrom-Json

            # check if new format
            if ($null -eq $data.spec)
            {
                # skip build.json files with old format...

                return
            }

            # use new format
            $data = $data.spec

            # check if there is a Dockerfile
            $dockerFilePath = Join-Path $buildContextPath "\Dockerfile"

            if (!(Test-Path -Path $dockerFilePath -PathType "Leaf"))
            {
                throw ("No Dockerfile was found at '{0}'." -f $dockerFilePath)
            }

            # find base images
            $dockerFileContent = Get-Content -Path $dockerFilePath
            $dockerFileArgLines = $dockerFileContent | Select-String -SimpleMatch "ARG " -CaseSensitive | ForEach-Object { Write-Output $_.ToString().Replace("ARG ", "") }
            $dockerFileFromLines = $dockerFileContent | Select-String -SimpleMatch "FROM " -CaseSensitive | ForEach-Object { Write-Output $_.ToString().Replace("FROM ", "") }

            $baseImages = $dockerFileFromLines | ForEach-Object {
                $from = $_
                $image = $null

                # remove multi-stage name
                if ($from -like "* as *")
                {
                    $from = $from.Substring(0, $from.IndexOf(" as "))
                }

                # if variable, find the base image in build-options or from ARG default value, if not use the as is
                if ($from -like "`$*")
                {
                    $argName = $from.Replace("`$", "").Replace("{", "").Replace("}", "")
                    $matchingOption = $data.'build-options' | Where-Object { $_.Contains($argName) } | Select-Object -First 1

                    if ($null -ne $matchingOption)
                    {
                        # resolved image from ARG passed as build-args defined in build-options
                        $image = $matchingOption.Substring($matchingOption.IndexOf($argName) + $argName.Length).Replace("=", "")
                    }
                    else
                    {
                        $argDefaultValue = $dockerFileArgLines | Where-Object { $_ -match $argName } | ForEach-Object {
                            Write-Output $_.Replace($argName, "").Replace("=", "")
                        }

                        if ([string]::IsNullOrEmpty($argDefaultValue) -eq $false)
                        {
                            # resolved image from ARG default value
                            $image = $argDefaultValue
                        }
                        else
                        {
                            throw ("Parse error in '{0}', Dockerfile is expecting ARG '{1}' but it has no default value and is not found in 'build-options'." -f $buildJsonPath, $argName)
                        }
                    }
                }
                else
                {
                    # resolved image name directly
                    $image = $from
                }

                # done
                Write-Output $image
            }

            # if no base images found then something is very wrong
            if ($null -eq $baseImages -or $baseImages.Length -eq 0)
            {
                throw ("Parse error, no base images was found in Dockerfile '{0}'." -f $dockerFilePath)
            }

            # setup build options
            $options = $data.'build-options'

            if ($null -eq $options)
            {
                $options = @()
            }

            # setup sources
            $sources = @()

            if ($null -ne $data.sources)
            {
                $sources = $data.sources
            }

            # setup compatibility
            $compatibility = (New-Object PSObject -Property @{
                    Versions   = @($data.compatibility.versions);
                    Topologies = @($data.compatibility.topologies | ForEach-Object { New-Object PSObject -Property @{
                                Name  = $_.name;
                                Roles = @($_.roles);
                            } });
                    Variants   = @($data.compatibility.variants);
                })

            # done
            Write-Output (New-Object PSObject -Property @{
                    BuildContextPath = $buildContextPath;
                    DockerFilePath   = $dockerFilePath;
                    Compatibility    = $compatibility;
                    BuildOptions     = @($options);
                    BaseImages       = @($baseImages | Select-Object -Unique);
                    Sources          = @($sources);
                })
        }
    }
}