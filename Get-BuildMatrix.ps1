$data = Get-Content -Path (Join-Path $PSScriptRoot ".\build-matrix.json") | ConvertFrom-Json

####### HUSK build matrix er kun FORSLAG til hvad der KUNNE være muligt at bygges!

# Producer
# TODO: ...

# Consumer
# TODO: Path skal ikke være her, det er kun til test. Det skal være på consumer siden og checkke om der findes noget der kan bygges.
# TODO: Hvad med 9.0.2/9.1.0 Linux SQL, hvordan filtres det væk på consumer siden?
# TODO: Hvordan merger vi path for tags der bygges ud fra samme folder men med forskellige paramter?

# NOTES: "requires"/dependencies skal udledes af build-args fra build.json

$versions = $data.versions | ForEach-Object {
    $version = $_

    $version.dependencies | ForEach-Object {
        $dependency = $_

        $data.platforms | Where-Object { $dependency.os -contains $_.os } | ForEach-Object {
            $platform = $_

            Write-Output (New-Object PSObject -Property @{
                    Type            = "dependency";
                    SitecoreVersion = "$($version.major).$($version.minor).$($version.patch)";
                    Name            = $dependency.name;
                    VariantVersion  = $null;
                    Topology        = $null;
                    Role            = $null;
                    Platform        = "$($platform.name)";
                    DockerEngine    = $platform.engine;
                    Tag             = "sitecore-$($dependency.name):$($version.major).$($version.minor).$($version.patch)-$($platform.name)";
                })
        }
    }

    $data.topologies | ForEach-Object {
        $topology = $_

        $topology.roles | ForEach-Object {
            $role = $_

            $data.platforms | Where-Object { $role.os -contains $_.os } | ForEach-Object {
                $platform = $_

                Write-Output (New-Object PSObject -Property @{
                        Type            = "platform";
                        SitecoreVersion = "$($version.major).$($version.minor).$($version.patch)"
                        Name            = $role.name;
                        VariantVersion  = $null;
                        Topology        = $topology.name;
                        Role            = $role.name;
                        Platform        = $platform.name;
                        DockerEngine    = $platform.engine;
                        Tag             = "sitecore-$($topology.name)-$($role.name):$($version.major).$($version.minor).$($version.patch)-$($platform.name)";
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

                    Write-Output (New-Object PSObject -Property @{
                            Type            = "variant";
                            SitecoreVersion = "$($version.major).$($version.minor).$($version.patch)"
                            Name            = $variant.name;
                            VariantVersion  = "$($variant.version.major).$($variant.version.minor).$($variant.version.patch)";
                            Topology        = $topologyReference.name;
                            Role            = $roleReference.name;
                            Platform        = $platform.name;
                            DockerEngine    = $platform.engine;
                            Tag             = "sitecore-$($topologyReference.name)-$($variant.name)-$($roleReference.name):$($version.major).$($version.minor).$($version.patch)-$($platform.name)";
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

        Write-Output (New-Object PSObject -Property @{
                Type            = "dependency";
                SitecoreVersion = $null;
                Name            = $dependency.name;
                VariantVersion  = $null;
                Topology        = $null;
                Role            = $null;
                Platform        = "$($platform.name)";
                DockerEngine    = $platform.engine;
                Tag             = "sitecore-$($dependency.name):????-$($platform.name)";
            })
    }
}

$matrix = [array]$versions, [array]$dependencies
$matrix | Sort-Object -Property Type, SitecoreVersion, Platform, Topology, Role | Format-Table -Property SitecoreVersion, VariantVersion, Type, Name, Topology, Role, Platform, DockerEngine, Tag
