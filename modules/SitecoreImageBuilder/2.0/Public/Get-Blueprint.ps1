Set-StrictMode -Version 3.0

function Get-Blueprint
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ -PathType "Leaf" })]
        [string]$Path
    )

    Process
    {

        # load sketch data
        $data = Get-Content -Path $Path | ConvertFrom-Json

        # parse sketch data and return blueprints
        $data.versions | ForEach-Object {
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
                                })
                        }
                    }
                }
            }
        }

        $data.dependencies | ForEach-Object {
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
                    })
            }
        }
    }
}