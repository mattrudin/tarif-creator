#---------------------------------------------------------[Script Parameters]------------------------------------------------------
[CmdletBinding()]
param(
    $path = 'C:\bz-core\'
)

#-----------------------------------------------------------[Functions]------------------------------------------------------------
function Update-DbRefdataDefaultProperties {
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        [ValidateNotNullorEmpty()]
        [string]
        $Path,
        [ValidateRange(2015, 9998)]
        [int]$Year = (Get-Date).year
    )
    $pathToRefdata = Join-Path -Path $Path -ChildPath '\nil-core\nil-refdata\src\scripts\'
    $pathToRefdataProperties = Join-Path -Path $pathToRefdata -ChildPath 'dbRefdata_default.properties'
    $sb = [System.Text.StringBuilder]::new()
    $lastYear = $Year - 1
    $searchParameter = 'refdata.tarif_' + $lastYear + '.file=tarif_' + $lastYear + '.xml'
    $searchParameterVk = 'refdata.tarifvk_' + $lastYear + '.file=tarifvk_' + $lastYear + '.xml'
    $tarif = 'refdata.tarif_' + $Year + '.file=tarif_' + $Year + '.xml'
    $tarifVk = 'refdata.tarifvk_' + $Year + '.file=tarifvk_' + $Year + '.xml'
    foreach($line in [System.IO.File]::ReadLines($pathToRefdataProperties)) {
        $sb.AppendLine($line)
        if($line.Equals($searchParameter)) {
            $sb.AppendLine($tarif)
        }
        if($line.Equals($searchParameterVk)) {
            $sb.AppendLine($tarifVk)
        }
    }
    Set-Content -Path $pathToRefdataProperties -Value $sb.ToString()
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------
Update-DbRefdataDefaultProperties -Path $path -Year 2020