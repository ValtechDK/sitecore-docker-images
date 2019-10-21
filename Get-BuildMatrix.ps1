$data = Get-Content -Path (Join-Path $PSScriptRoot ".\build-matrix.json") | ConvertFrom-Json

####### HUSK build matrix er kun FORSLAG til hvad der KUNNE være muligt at bygges!

# Producer
# TODO: ...

# Consumer
# TODO: Path skal ikke være her, det er kun til test. Det skal være på consumer siden og checkke om der findes noget der kan bygges.
# TODO: Hvordan merger vi path for tags der bygges ud fra samme folder men med forskellige paramter?

# NOTES: "requires"/dependencies/build order skal udledes af build-args fra build.json

$versions = $data.versions | ForEach-Object {
    $version = $_

    $version.dependencies | ForEach-Object {
        $dependency = $_

        $data.platforms | Where-Object { $dependency.os -contains $_.os } | ForEach-Object {
            $platform = $_
            $repository = "sitecore-$($dependency.name)";

            Write-Output (New-Object PSObject -Property @{
                    Type            = "dependency";
                    SitecoreVersion = (New-Object PSObject -Property @{ "Major" = $version.major; "Minor" = $version.minor; "Patch" = $version.patch; "Revision" = $version.revision; });
                    Repository      = $repository;
                    Key             = $dependency.name;
                    VariantVersion  = (New-Object PSObject -Property @{ "Major" = "0"; "Minor" = "0"; "Patch" = "0"; "Revision" = "0" });
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
                        SitecoreVersion = (New-Object PSObject -Property @{ "Major" = $version.major; "Minor" = $version.minor; "Patch" = $version.patch; "Revision" = $version.revision; });
                        Repository      = $repository;
                        Key             = $null;
                        VariantVersion  = (New-Object PSObject -Property @{ "Major" = "0"; "Minor" = "0"; "Patch" = "0"; "Revision" = "0" });
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
                            SitecoreVersion = (New-Object PSObject -Property @{ "Major" = $version.major; "Minor" = $version.minor; "Patch" = $version.patch; "Revision" = $version.revision; });
                            Repository      = $repository;
                            Key             = $variant.name;
                            VariantVersion  = (New-Object PSObject -Property @{ "Major" = $variant.version.major; "Minor" = $variant.version.minor; "Patch" = $variant.version.patch; "Revision" = $variant.version.revision; }); ;
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

    $data.platforms | Where-Object { $dependency.os -contains $_.os } | ForEach-Object {
        $platform = $_
        $repository = "sitecore-$($dependency.name)"

        Write-Output (New-Object PSObject -Property @{
                Type            = "dependency";
                SitecoreVersion = (New-Object PSObject -Property @{ "Major" = "0"; "Minor" = "0"; "Patch" = "0"; "Revision" = "0" });
                Repository      = $repository;
                Key             = $dependency.name;
                VariantVersion  = (New-Object PSObject -Property @{ "Major" = "0"; "Minor" = "0"; "Patch" = "0"; "Revision" = "0" });
                Topology        = $null;
                Role            = $null;
                Platform        = "$($platform.name)";
                DockerEngine    = $platform.engine;
                Tag             = "$($respository):????-$($platform.name)";
            })
    }
}

$matrix = [System.Collections.ArrayList]@()
$matrix.AddRange($versions)
$matrix.AddRange($dependencies)

#$matrix | Sort-Object -Property Type, SitecoreVersion, Platform, Topology, Role | Format-Table -Property SitecoreVersion, VariantVersion, Type, Key, Repository, Topology, Role, Platform, DockerEngine, Tag

$prospects = $matrix | Where-Object { ($_.SitecoreVersion.Major -eq "9" -and $_.SitecoreVersion.Minor -eq "2") } | ForEach-Object {
    $prospect = $_

    $versionFolders = @(
        ("{0}.{1}.{2}" -f $prospect.SitecoreVersion.Major, $prospect.SitecoreVersion.Minor, $prospect.SitecoreVersion.Patch),
        ("{0}.{1}.x" -f $prospect.SitecoreVersion.Major, $prospect.SitecoreVersion.Minor),
        ("{0}.x.x" -f $prospect.SitecoreVersion.Major)
    )

    $fixedRepository = $prospect.Repository

    # TODO: Remove when Windows SQL images are renamed from "-sqldev" to "-sql"
    if ($prospect.Platform -ne "linux" -and $fixedRepository -like "*-sql")
    {
        $fixedRepository = $fixedRepository.Replace("-sql", "-sqldev")
    }

    $repositoryFolders = @(
        ("{0}" -f $fixedRepository),
        ("sitecore-{0}-{1}" -f $prospect.Topology, $prospect.Key),
        ("sitecore-{0}" -f $prospect.Topology)
    )

    $found = $false

    :Outer foreach ($repositoryFolder in $repositoryFolders)
    {
        $repositoryPaths = @()

        $versionFolders | ForEach-Object {
            $versionFolder = $_

            $repositoryPaths += Join-Path $PSScriptRoot ("\{0}\{1}\{2}" -f $prospect.DockerEngine, $versionFolder, $repositoryFolder)
        }

        foreach ($repositoryPath in $repositoryPaths)
        {
            if (Test-Path -Path $repositoryPath -PathType Container)
            {
                $found = $true

                Write-Output (New-Object PSObject -Property @{
                        Path     = $repositoryPath;
                        Prospect = $prospect;
                    })

                break :Outer
            }
        }
    }

    if (!$found)
    {
        Write-Output (New-Object PSObject -Property @{
                Path     = $null;
                Prospect = $prospect;
            })
    }
}

# here we have prospects, most with context folder that can be build
$prospects | Format-Table -Property Path, @{ Name = "Tag"; Expression = { $_.Prospect.Tag } }, Prospect

# find context folders NOT covered
(Join-Path $PSScriptRoot "\windows"), (Join-Path $PSScriptRoot "\linux") | ForEach-Object {
    $enginePath = $_

    Get-ChildItem -Path $enginePath -Filter "Dockerfile" -Recurse | ForEach-Object {
        $contextPath = $_.Directory.FullName
        $foundProspect = ($prospects | Where-Object { $_.Path -eq $contextPath }).Length -gt 0

        if ($foundProspect)
        {
            Write-Host "$contextPath" -ForegroundColor Gray
        }
        else
        {
            Write-Host "NOT FOUND: $contextPath" -ForegroundColor Red
        }

    }
}
