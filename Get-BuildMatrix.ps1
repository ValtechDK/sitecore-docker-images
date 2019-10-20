$data = Get-Content -Path (Join-Path $PSScriptRoot ".\build-matrix.json") | ConvertFrom-Json

####### HUSK build matrix er kun FORSLAG til hvad der KUNNE være muligt at bygges!

# Producer
# TODO: Handle build dependencies / order
# TODO: OpenJDK, mssql-2017, certificates skal buildes FOR SIG SELV, tror ikke de er en del af the matix? De er ikke versionered. Men måske de kunne være en ting såsom "dependencies" eller deps blev flyttet?

# Consumer
# TODO: Path skal ikke være her, det er kun til test. Det skal være på consumer siden og checkke om der findes noget der kan bygges.
# TODO: Hvad med 9.0.2/9.1.0 Linux SQL, hvordan filtres det væk på consumer siden?
# TODO: Hvordan merger vi path for tags der bygges ud fra samme folder men med forskellige paramter?

$data.versions | ForEach-Object {
    $version = $_

    $data.dependencies | ForEach-Object {
        $dependency = $_

        $data.platforms | Where-Object { $dependency.os -contains $_.os } | ForEach-Object {
            $platform = $_

            Write-Output (New-Object PSObject -Property @{
                    SitecoreVersion = "$($version.major).$($version.minor).$($version.patch)";
                    VariantName     = $null;
                    VariantVersion  = $null;
                    Topology        = $null;
                    Role            = $null;
                    Platform        = "$($platform.name)";
                    DockerEngine    = $platform.engine;
                    Tag             = "sitecore-$($dependency.name):$($version.major).$($version.minor).$($version.patch)-$($platform.name)";
                    Requirements    = @();
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
                        VariantName     = $null;
                        VariantVersion  = $null;
                        Topology        = $topology.name;
                        Role            = $role.name;
                        Platform        = $platform.name;
                        DockerEngine    = $platform.engine;
                        Tag             = "sitecore-$($topology.name)-$($role.name):$($version.major).$($version.minor).$($version.patch)-$($platform.name)";
                        Requirements    = @("assets");
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
                    $requirements = @("assets")

                    $variant.requires | ForEach-Object {
                        $required = $_

                        $requirements += $required.name
                    }

                    Write-Output (New-Object PSObject -Property @{
                            SitecoreVersion = "$($version.major).$($version.minor).$($version.patch)"
                            VariantName     = $variant.name;
                            VariantVersion  = "$($variant.version.major).$($variant.version.minor).$($variant.version.patch)";
                            Topology        = $topologyReference.name;
                            Role            = $roleReference.name;
                            Platform        = $platform.name;
                            DockerEngine    = $platform.engine;
                            Tag             = "sitecore-$($topologyReference.name)-$($variant.name)-$($roleReference.name):$($version.major).$($version.minor).$($version.patch)-$($platform.name)";
                            Requirements    = $requirements;
                        })
                }
            }
        }
    }
} | Sort-Object -Property SitecoreVersion, DockerEngine, Tag | Format-Table -Property SitecoreVersion, VariantVersion, Topology, VariantName, Role, Platform, DockerEngine, Requirements, Tag