#---------------------------------------------------------[Script Parameters]------------------------------------------------------
[CmdletBinding()]
param (
    $pathToBzCore = $(Read-Host 'Pflicht: Pfad von bz-core'),
    $year = $(Read-Host 'Optional: Jahr fuer Tarife angeben, oder leer lassen fuer aktuelles Jahr'),
    $errorCount = 0,
    $successCount = 0
)

#-----------------------------------------------------------[Functions]------------------------------------------------------------
function Create-Tarife {
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        [ValidateNotNullorEmpty()]
        [string]
        $Path,
        [ValidateRange(2015, 9998)]
        [int]$Year = (Get-Date).year
    )
    $pathToTarife = Join-Path -Path $Path -ChildPath '\nil-core\nil-refdata\src\main\data'
    $mandanten = Get-ChildItem -Path $pathToTarife | Where-Object { $_.Psiscontainer } | Select-Object FullName
    $tarif = 'tarif_' + $Year + '.xml'
    $tarifVk = 'tarifVk_' + $Year + '.xml'
    $tarife = $tarif, $tarifVk
    $exclusions = 'backup', 'common', 'common-igs', 'common-nil', 'initdata'
    
    foreach ($mandant in $mandanten) {
        $mandantFolder = $mandant.FullName | Split-Path -Leaf
        if(-not $exclusions.Contains($mandantFolder)) {
            foreach ($tarif in $tarife) {
                Write-Tarif -Name $tarif -Path $mandant.FullName
            }
        }
    }
    Write-Log
}

function Write-Tarif {
    [CmdletBinding()]
    param (
        $Name,
        $Path
    )
    $fullPath = Join-Path -Path $Path -ChildPath $Name
    $initialValue = Get-InitialValue
    try {
        New-Item -Path $Path -Name $Name -ItemType 'file' -Value $initialValue -ErrorAction Stop | Out-Null
        Write-Success -Name $fullPath
    }
    catch {
        Write-Error -Name $fullPath
    }
}

function Get-InitialValue {
    return '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE dataset SYSTEM "../refdata.dtd">
<dataset>
</dataset>'    
}

function Write-Error {
    [CmdletBinding()]
    param (
        $Name
    )
    Write-Host "[ERROR] File $Name already exists" -ForegroundColor Red
    $Global:errorCount++
}

function Write-Success {
    [CmdletBinding()]
    param (
        $Name
    )
    Write-Host "[SUCCESS] File $Name created" -ForegroundColor Green
    $Global:successCount++
}

function Write-Log {
    if($Global:successCount -lt 1) {
        $Global:successCount = "0"
    }
    if($Global:errorCount -lt 1) {
        $Global:errorCount = "0"
    }
    Write-Host "---[LOG]---"
    Write-Host "Success: " $Global:successCount -ForegroundColor Green
    Write-Host "Error:  " $Global:errorCount -ForegroundColor Red
    
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Clear-Variable -Name successCount -Scope Global
Clear-Variable -Name errorCount -Scope Global

if (!$year) {
    Create-Tarife -Path $pathToBzCore
}
else {
    Create-Tarife -Path $pathToBzCore -Year $year
}