$data = Get-Content -Path (Join-Path $PSScriptRoot ".\build-matrix.json") | ConvertFrom-Json

####### HUSK build matrix er kun FORSLAG til hvad der KUNNE være muligt at bygges!

# TODO: OpenJDK, mssql-2017, certificates skal buildes FOR SIG SELV... De er ikke versioneret!
# TODO: Handle build dependencies / order

# TODO: Path skal ikke være her, det er kun til test. Det skal være på consumer siden og checkke om der findes noget der kan bygges.
# TODO: Hvad med 9.0.2/9.1.0 Linux SQL, hvordan filtres det væk på consumer siden?
# TODO: Hvordan merger vi path for tags der bygges ud fra samme folder men med forskellige paramter?

$data.versions | ForEach-Object {
    $version = $_

    $data.dependencies | Where-Object { $_.versions -contains "*" } | ForEach-Object {
        $dependency = $_

        $data.platforms | Where-Object { $dependency.os -contains $_.os } | ForEach-Object {
            $platform = $_

            Write-Output (New-Object PSObject -Property @{
                    SitecoreVersion = "$($version.major).$($version.minor).$($version.patch)";
                    Type            = "dependency";
                    VariantName     = $null;
                    VariantVersion  = $null;
                    Topology        = "*";
                    Role            = "*";
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
                        SitecoreVersion = "$($version.major).$($version.minor).$($version.patch)"
                        Type            = "platform";
                        VariantName     = $null;
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
            $topology = $data.topologies | Where-Object { $_.name -eq $variantTopology.name }

            $variantTopology.roles | ForEach-Object {
                $variantRole = $_
                $role = $topology.roles | Where-Object { $_.name -eq $variantRole.name }

                $data.platforms | Where-Object { $role.os -contains $_.os } | ForEach-Object {
                    $platform = $_

                    Write-Output (New-Object PSObject -Property @{
                            SitecoreVersion = "$($version.major).$($version.minor).$($version.patch)"
                            Type            = "variant";
                            VariantName     = $variant.name;
                            VariantVersion  = "$($variant.version.major).$($variant.version.minor).$($variant.version.patch)";
                            Topology        = $topology.name;
                            Role            = $role.name;
                            Platform        = $platform.name;
                            DockerEngine    = $platform.engine;
                            Tag             = "sitecore-$($topology.name)-$($variant.name)-$($role.name):$($version.major).$($version.minor).$($version.patch)-$($platform.name)";
                        })
                }
            }
        }
    }
} | Sort-Object -Property SitecoreVersion, Type, DockerEngine, Tag | Format-Table -Property SitecoreVersion, VariantVersion, Type, Topology, VariantName, Role, Platform, DockerEngine, Tag