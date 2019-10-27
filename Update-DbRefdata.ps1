#---------------------------------------------------------[Script Parameters]------------------------------------------------------
[CmdletBinding()]
param(
    $path = 'C:\bz-core\'
)

#-----------------------------------------------------------[Functions]------------------------------------------------------------
function Update-DbRefdata {
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
    $pathToRefdataXml = Join-Path -Path $pathToRefdata -ChildPath 'dbRefdata.xml'
    $pathToRefdataXmlCopy = Join-Path -Path $pathToRefdata -ChildPath 'dbRefdata_copy.xml'
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
    $newNodeSql.FirstChild.sql = "select * from `${source.schema}.tarif where GUELTIGBIS between to_date('01.01." + $Year + ",'dd.mm.yyyy') and to_date('31.12." + $Year + "','dd.mm.yyyy') order by CDREGARTID,KONTOOID,GUELTIGAB,GUELTIGBIS,OID"
    $tarifNodeSql.ParentNode.InsertBefore($newNodeSql, $tarifNodeSql)
    $tarifNodeSql.FirstChild.sql = "select * from `${source.schema}.tarif where GUELTIGBIS between to_date('01.01." + $Year + ",'dd.mm.yyyy') and to_date('31.12.9999','dd.mm.yyyy') order by CDREGARTID,KONTOOID,GUELTIGAB,GUELTIGBIS,OID"
    #SQL tarifVk
    $newNodeVkSql = $tarifVkNodeSql.Clone()
    $newNodeVkSql.dest = '${export.dir}/${refdata.tarifvk_' + $Year + '.file}'
    $newNodeVkSql.FirstChild.sql = "select * from `${source.schema}.tarifvk where GUELTIGBIS between to_date('01.01." + $Year + ",'dd.mm.yyyy') and to_date('31.12." + $Year + "','dd.mm.yyyy') order by CDREGARTID,KONTOOID,GUELTIGAB,GUELTIGBIS,OID"
    $tarifVkNodeSql.ParentNode.InsertBefore($newNodeVkSql, $tarifVkNodeSql)
    $tarifVkNodeSql.FirstChild.sql = "select * from `${source.schema}.tarifvk where GUELTIGBIS between to_date('01.01." + $Year + ",'dd.mm.yyyy') and to_date('31.12.9999','dd.mm.yyyy') order by CDREGARTID,KONTOOID,GUELTIGAB,GUELTIGBIS,OID"
    
    $dbRefdata.Save($pathToRefdataXmlCopy)
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------
Update-DbRefdata -Path $path -Year 2020