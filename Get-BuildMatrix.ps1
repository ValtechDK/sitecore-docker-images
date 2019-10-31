$ErrorActionPreference = "STOP"
$VerbosePreference = "Continue"

# Producer
# TODO: ...

# Consumer
# TODO: Hvordan merger vi path for tags der bygges ud fra samme folder men med forskellige paramter?

# Other
# NOTE: "requires"/dependencies/build order skal udledes af build-args fra build.json (og IKKE i matrix.json)
# NOTE: Important that there are NO requirements on filesystem layout
# TODO: Rename "mssql-developer-2017" to somthing prefixed with "sitecore-"?
# TODO: Rename "-sqldev" to "-sql" on Windows OR specify both in the matrix.

# load build matrix data
$data = Get-Content -Path (Join-Path $PSScriptRoot ".\build-matrix.json") | ConvertFrom-Json

# parse build matrix data
$versions = $data.versions | ForEach-Object {
    $version = $_

    $version.images | ForEach-Object {
        $image = $_

        $data.platforms | Where-Object { $image.os -contains $_.os } | ForEach-Object {
            $platform = $_
            $repository = "sitecore-$($image.name)";

            Write-Output (New-Object PSObject -Property @{
                    Type            = "dependency";
                    SitecoreVersion = (New-Object PSObject -Property @{ "Name" = "$($version.major).$($version.minor).$($version.patch)"; "Major" = $version.major; "Minor" = $version.minor; "Patch" = $version.patch; "Revision" = $version.revision; });
                    Repository      = $repository;
                    VariantName     = $null;
                    VariantVersion  = (New-Object PSObject -Property @{ "Name" = "0.0.0"; "Major" = "0"; "Minor" = "0"; "Patch" = "0"; "Revision" = "0" });
                    Topology        = $null;
                    Role            = $null;
                    Platform        = "$($platform.name)";
                    DockerEngine    = $platform.engine;
                    Tag             = "$($repository):$($version.major).$($version.minor).$($version.patch)-$($platform.name)";
                })
        }
    }

    $data.topologies | ForEach-Object {
        $topology = $_

        $topology.roles | ForEach-Object {
            $role = $_

            $data.platforms | Where-Object { $role.os -contains $_.os } | ForEach-Object {
                $platform = $_
                $repository = "sitecore-$($topology.name)-$($role.name)";

                Write-Output (New-Object PSObject -Property @{
                        Type            = "platform";
                        SitecoreVersion = (New-Object PSObject -Property @{ "Name" = "$($version.major).$($version.minor).$($version.patch)"; "Major" = $version.major; "Minor" = $version.minor; "Patch" = $version.patch; "Revision" = $version.revision; });
                        Repository      = $repository;
                        VariantName     = $null;
                        VariantVersion  = (New-Object PSObject -Property @{ "Name" = "0.0.0"; "Major" = "0"; "Minor" = "0"; "Patch" = "0"; "Revision" = "0" });
                        Topology        = $topology.name;
                        Role            = $role.name;
                        Platform        = $platform.name;
                        DockerEngine    = $platform.engine;
                        Tag             = "$($repository):$($version.major).$($version.minor).$($version.patch)-$($platform.name)";
                    })
            }
        }
    }

    $version.variants | ForEach-Object {
        $variant = $_

        $variantReference = $data.variants | Where-Object { $_.name -eq $variant.name }

        $variantReference.topologies | ForEach-Object {
            $variantTopology = $_
            $topologyReference = $data.topologies | Where-Object { $_.name -eq $variantTopology.name }

            $variantTopology.roles | ForEach-Object {
                $variantRoleName = $_
                $roleReference = $topologyReference.roles | Where-Object { $_.name -eq $variantRoleName }

                $data.platforms | Where-Object { $roleReference.os -contains $_.os } | ForEach-Object {
                    $platform = $_
                    $repository = "sitecore-$($topologyReference.name)-$($variant.name)-$($roleReference.name)";

                    Write-Output (New-Object PSObject -Property @{
                            Type            = "variant";
                            SitecoreVersion = (New-Object PSObject -Property @{ "Name" = "$($version.major).$($version.minor).$($version.patch)"; "Major" = $version.major; "Minor" = $version.minor; "Patch" = $version.patch; "Revision" = $version.revision; });
                            Repository      = $repository;
                            VariantName     = $variant.name;
                            VariantVersion  = (New-Object PSObject -Property @{ "Name" = "$($variant.version.major).$($variant.version.minor).$($variant.version.patch)"; "Major" = $variant.version.major; "Minor" = $variant.version.minor; "Patch" = $variant.version.patch; "Revision" = $variant.version.revision; }); ;
                            Topology        = $topologyReference.name;
                            Role            = $roleReference.name;
                            Platform        = $platform.name;
                            DockerEngine    = $platform.engine;
                            Tag             = "$($repository):$($version.major).$($version.minor).$($version.patch)-$($platform.name)";
                        })
                }
            }
        }
    }
}

$dependencies = $data.dependencies | ForEach-Object {
    $dependency = $_
    $repository = $dependency.name;

    $data.platforms | Where-Object { $dependency.os -contains $_.os } | ForEach-Object {
        $platform = $_

        Write-Output (New-Object PSObject -Property @{
                Type            = "dependency";
                SitecoreVersion = (New-Object PSObject -Property @{ "Name" = "0.0.0"; "Major" = "0"; "Minor" = "0"; "Patch" = "0"; "Revision" = "0" });
                Repository      = $repository;
                VariantName     = $null;
                VariantVersion  = (New-Object PSObject -Property @{ "Name" = "0.0.0"; "Major" = "0"; "Minor" = "0"; "Patch" = "0"; "Revision" = "0" });
                Topology        = $null;
                Role            = $null;
                Platform        = "$($platform.name)";
                DockerEngine    = $platform.engine;
                Tag             = "$($repository):$($dependency.version)-$($platform.name)";
            })
    }
}

$matrix = [System.Collections.ArrayList]@()
$matrix.AddRange($versions)
$matrix.AddRange($dependencies)

# print build matrix
#$matrix | Sort-Object -Property Type, SitecoreVersion, Platform, Topology, Role | Format-Table -Property SitecoreVersion, VariantVersion, Type, Repository, Topology, Role, Platform, DockerEngine, Tag

# load specifications
$specifications = (Join-Path $PSScriptRoot ".\windows"), (Join-Path $PSScriptRoot ".\linux") | Get-ChildItem -Recurse -File -Include "build.json" | ForEach-Object {
    $buildJsonPath = $_.FullName
    $buildContextPath = $_.Directory.FullName
    $data = Get-Content -Path $buildJsonPath | ConvertFrom-Json

    # check if new format
    if ($data.spec -eq $null)
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

# print specifications
$specifications

# now merge the matrix with specifications
$specifications | ForEach-Object {
    $spec = $_

    # reduces to compatible versions
    $matches = $spec.Compatibility.Versions | ForEach-Object {
        $versionToMatch = $_

        Write-Output ($matrix | Where-Object { $_.SitecoreVersion.Name -like $versionToMatch } )
    }

    $matches.Count

    # reduces to compatible topologies
    $matches = $spec.Compatibility.Topologies | ForEach-Object {
        $topologyToMatch = $_

        Write-Output ($matches | Where-Object { $_.Topology -eq $topologyToMatch.Name } )
    }

    $matches.Count

    # reduces to compatible roles
    $matches = $spec.Compatibility.Topologies | ForEach-Object {
        $topologyToMatch = $_

        Write-Output ($matches | Where-Object { $topologyToMatch.Roles -contains $_.Role } )
    }

    $matches.Count

    if ($spec.Compatibility.Variants.Length -gt 0)
    {
        # reduces to compatible variants
        $matches = $spec.Compatibility.Variants | ForEach-Object {
            $variantToMatch = $_

            Write-Output ($matches | Where-Object { $_.VariantName -eq $variantToMatch } )
        }
    }
    else
    {
        # reducts to without any variants
        $matches = $matches | Where-Object { $_.Type -ne "variant" }
    }

    $matches.Count

    $matches | Format-Table
}

# filtering done before reducing
# find out dependencies to add
# resolve order