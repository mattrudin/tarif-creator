#---------------------------------------------------------[Script Parameters]------------------------------------------------------
[CmdletBinding()]
param (
    $path = $(Read-Host 'Pflicht: Pfad von bz-core'),
    $year = $(Read-Host 'Optional: Jahr fuer Tarife angeben, oder leer lassen fuer aktuelles Jahr')
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
    $folders = Get-ChildItem -Path $Path | Where-Object { $_.Psiscontainer } | Select-Object FullName
    $tarif = 'tarif_' + $Year + '.xml'
    $tarifVk = 'tarifVk_' + $Year + '.xml'
    $tarife = $tarif, $tarifVk
    
    foreach ($folder in $folders) {
        foreach ($tarif in $tarife) {
            Write-Tarif -Name $tarif -Path $folder.FullName
        }
    }
}

function Write-Tarif {
    [CmdletBinding()]
    param (
        $Name,
        $Path
    )
    $fullPath = Join-Path -Path $Path -ChildPath $Name
    $initialValue = '<Product>
                    <Name>Widget</Name>
                    <Details>
                        <Description>
                            This Widget is the highest quality widget. 
                        </Description>
                        <Price>5.50</Price>
                    </Details>
                </Product>'
    try {
        New-Item -Path $Path -Name $Name -ItemType 'file' -Value $initialValue -ErrorAction Stop | Out-Null
        Write-Success -Name $fullPath
    }
    catch {
        Write-Error -Name $fullPath
    }
}

function Write-Error {
    [CmdletBinding()]
    param (
        $Name
    )
    Write-Host "[ERROR] File $Name already exists" -ForegroundColor Red
}

function Write-Success {
    [CmdletBinding()]
    param (
        $Name
    )
    Write-Host "[SUCCESS] File $Name created" -ForegroundColor Green
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------
if (!$year) {
    Create-Tarife -Path $path
}
else {
    Create-Tarife -Path $path -Year $year
}