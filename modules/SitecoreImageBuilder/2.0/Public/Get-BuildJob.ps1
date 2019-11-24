Set-StrictMode -Version 3.0

function Get-BuildJob
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [array]$Blueprints
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [array]$Specifications
    )

    Process
    {
        # find blueprints compatible with specifications and return jobs
        $Specifications | ForEach-Object {
            $spec = $_

            # reduces list to compatible versions
            $matches = $spec.Compatibility.Versions | ForEach-Object {
                $versionToMatch = $_

                Write-Output @($Blueprints | Where-Object { $_.SitecoreVersion.Name -like $versionToMatch } )
            }

            # reduces list to compatible topologies
            $matches = $spec.Compatibility.Topologies | ForEach-Object {
                $topologyToMatch = $_

                Write-Output @($matches | Where-Object { $_.Topology -like $topologyToMatch.Name } )
            }

            # reduces list to compatible roles
            $matches = $spec.Compatibility.Topologies | ForEach-Object {
                $topologyToMatch = $_

                $topologyToMatch.Roles | ForEach-Object {
                    $role = $_

                    # TODO: somthing is wrong... getting too many jobs (invalid())
                    <<<<
                    Write-Output @($matches | Where-Object { $_.Role -like $role })
                }
            }

            if ($spec.Compatibility.Variants.Length -gt 0)
            {
                # reduces list to compatible variants
                $matches = $spec.Compatibility.Variants | ForEach-Object {
                    $variantToMatch = $_

                    Write-Output @($matches | Where-Object { $_.VariantName -like $variantToMatch } )
                }
            }
            else
            {
                # reduces list to exclude variants
                $matches = @($matches | Where-Object { $_.Type -ne "variant" })
            }

            # done
            $matches | ForEach-Object {
                $blueprint = $_

                Write-Output (New-Object PSObject -Property @{
                        BuildContextPath = $spec.BuildContextPath;
                        DockerFilePath   = $spec.DockerFilePath;
                        DockerEngine     = $blueprint.Platform.Engine;
                        BuildOptions     = @($spec.BuildOptions);
                        Sources          = @($spec.Sources);
                        BaseImages       = @($spec.BaseImages);
                        Tag              = "$($blueprint.Repository):$($blueprint.SitecoreVersion.Name)-$($blueprint.Platform.Name)";
                        Blueprint        = $blueprint
                    })
            }
        }
    }
}