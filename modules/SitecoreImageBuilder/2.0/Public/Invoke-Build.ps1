Set-StrictMode -Version 3.0

function Invoke-Build
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$InputObject
    )

    Process
    {
        Write-Host "INPUT: "

        $InputObject

        $blueprints = Get-Blueprint -Path (Join-Path $PSScriptRoot "..\..\..\..\sketch.json")

        $specifications = (Join-Path $PSScriptRoot "..\..\..\..\windows"), (Join-Path $PSScriptRoot "..\..\..\..\linux") | Get-BuildSpecification

        Get-BuildJob -Blueprints $blueprints -Specifications $specifications
    }
}