#---------------------------------------------------------[Script Parameters]------------------------------------------------------
[CmdletBinding()]
param (
    $pathToBzCore = $(Read-Host 'Pflicht: Pfad von bz-core'),
    $fromYear = $(Read-Host 'Pflicht: Von Jahr'),
    $toYear = $(Read-Host 'Pflicht: Bis Jahr'),
    $errorCount = 0,
    $successCount = 0
)

#-----------------------------------------------------------[Functions: New-Tarife-Files]------------------------------------------
function New-Tarife-Files {
    param (
        [parameter(Mandatory)] $Path,
        [parameter(Mandatory)] $FromYear,
        [parameter(Mandatory)] $ToYear
    )
    $years = $FromYear..$ToYear
    foreach($year in $years) {
        New-Tarife -Path $Path -Year $year
        Update-DbRefdata -Path $Path -Year $year
        Update-DbRefdataDefaultProperties -Path $Path -Year $year
    }   
}

#-----------------------------------------------------------[Functions: New-Tarife]------------------------------------------------
function New-Tarife {
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        [ValidateNotNullorEmpty()]
        [string]
        $Path,
        [ValidateRange(2015, 9998)]
        [int]$Year
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

#-----------------------------------------------------------[Functions: Update-DbRefdata]------------------------------------------
function Update-DbRefdata {
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        [ValidateNotNullorEmpty()]
        [string]
        $Path,
        [ValidateRange(2015, 9998)]
        [int]$Year
    )
    $pathToRefdata = Join-Path -Path $Path -ChildPath '\nil-core\nil-refdata\src\main\scripts\'
    $pathToRefdataXml = Join-Path -Path $pathToRefdata -ChildPath 'dbRefdata.xml'
    [xml]$dbRefdata = Get-Content -Path $pathToRefdataXml
    #import tarif
    $searchParameter = '${import.custom.dir}/${refdata.tarif_9999.file}'
    $searchParameterSql = '${export.dir}/${refdata.tarif_9999.file}'
    $tarifNodes = $dbRefdata.SelectNodes("project/target/ldbunit/transaction/operation[@src='$searchParameter']")
    $tarifNodeSql = $dbRefdata.SelectSingleNode("project/target/ldbunit/transaction/export[@dest='$searchParameterSql']")
    foreach($node in $tarifNodes) {
        $newNode = $node.Clone()
        $newNode.src = '${import.custom.dir}/${refdata.tarif_' + $Year + '.file}'
        $node.ParentNode.InsertBefore($newNode, $node)
    }
    #import tarifVk
    $searchParameterVk = '${import.custom.dir}/${refdata.tarifvk_9999.file}'
    $searchParameterVkSql = '${export.dir}/${refdata.tarifvk_9999.file}'
    $tarifVkNodes = $dbRefdata.SelectNodes("project/target/ldbunit/transaction/operation[@src='$searchParameterVk']")
    $tarifVkNodeSql = $dbRefdata.SelectSingleNode("project/target/ldbunit/transaction/export[@dest='$searchParameterVkSql']")
    foreach($node in $tarifVkNodes) {
        $newNode = $node.Clone()
        $newNode.src = '${import.custom.dir}/${refdata.tarifvk_' + $Year + '.file}'
        $node.ParentNode.InsertBefore($newNode, $node)
    }
    #SQL tarif
    $newNodeSql = $tarifNodeSql.Clone()
    $newNodeSql.dest = '${export.dir}/${refdata.tarif_' + $Year + '.file}'
    $newNodeSql.FirstChild.sql = "select * from `${source.schema}.tarif where GUELTIGBIS between to_date('01.01." + $Year + "','dd.mm.yyyy') and to_date('31.12." + $Year + "','dd.mm.yyyy') and regid = 0 order by SUBTYPID,CDREGARTID,KONTOOID,GUELTIGAB,GUELTIGBIS,MASSGBETRAGAB,BETRAG,BETRAGINPROZENT,OID"
    $tarifNodeSql.ParentNode.InsertBefore($newNodeSql, $tarifNodeSql)
    $tarifNodeSql.FirstChild.sql = "select * from `${source.schema}.tarif where GUELTIGBIS between to_date('01.01." + $Year + "','dd.mm.yyyy') and to_date('31.12.9999','dd.mm.yyyy') and regid = 0 order by SUBTYPID,CDREGARTID,KONTOOID,GUELTIGAB,GUELTIGBIS,MASSGBETRAGAB,BETRAG,BETRAGINPROZENT,OID"
    #SQL tarifVk
    $newNodeVkSql = $tarifVkNodeSql.Clone()
    $newNodeVkSql.dest = '${export.dir}/${refdata.tarifvk_' + $Year + '.file}'
    $newNodeVkSql.FirstChild.sql = "select * from `${source.schema}.tarifvk where GUELTIGBIS between to_date('01.01." + $Year + "','dd.mm.yyyy') and to_date('31.12." + $Year + "','dd.mm.yyyy') order by CDREGARTID,KONTOOID,GUELTIGAB,GUELTIGBIS,OID"
    $tarifVkNodeSql.ParentNode.InsertBefore($newNodeVkSql, $tarifVkNodeSql)
    $tarifVkNodeSql.FirstChild.sql = "select * from `${source.schema}.tarifvk where GUELTIGBIS between to_date('01.01." + $Year + "','dd.mm.yyyy') and to_date('31.12.9999','dd.mm.yyyy') order by CDREGARTID,KONTOOID,GUELTIGAB,GUELTIGBIS,OID"
    
    $dbRefdata.Save($pathToRefdataXml)
}

#-----------------------------------------------------------[Functions: Update-DbRefdataDefaultProperties]-------------------------
function Update-DbRefdataDefaultProperties {
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        [ValidateNotNullorEmpty()]
        [string]
        $Path,
        [ValidateRange(2015, 9998)]
        [int]$Year
    )
    $pathToRefdata = Join-Path -Path $Path -ChildPath '\nil-core\nil-refdata\src\main\scripts\'
    $pathToRefdataProperties = Join-Path -Path $pathToRefdata -ChildPath 'dbRefdata_default.properties'
    $sb = [System.Text.StringBuilder]::new()
    $searchParameter = 'refdata.tarif_9999.file=tarif_9999.xml'
    $searchParameterVk = 'refdata.tarifvk_9999.file=tarifvk_9999.xml'
    $tarif = 'refdata.tarif_' + $Year + '.file=tarif_' + $Year + '.xml'
    $tarifVk = 'refdata.tarifvk_' + $Year + '.file=tarifvk_' + $Year + '.xml'
    foreach($line in [System.IO.File]::ReadLines($pathToRefdataProperties)) {
        if($line.Equals($searchParameter)) {
            $sb.AppendLine($tarif)
        }
        if($line.Equals($searchParameterVk)) {
            $sb.AppendLine($tarifVk)
        }
        $sb.AppendLine($line)
    }
    Set-Content -Path $pathToRefdataProperties -Value $sb.ToString()
}
#-----------------------------------------------------------[Execution]------------------------------------------------------------

Clear-Variable -Name successCount -Scope Global
Clear-Variable -Name errorCount -Scope Global

New-Tarife-Files -Path $pathToBzCore -FromYear $fromYear -ToYear $toYear