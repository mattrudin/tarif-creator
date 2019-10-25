function writeError {
    param (
        $name
    )
    Write-Host "[ERROR] File $name already exists" -ForegroundColor Red
    }

function writeInfo {
    param (
        $name
    )
    Write-Host "[SUCCESS] File $name processed" -ForegroundColor Green
}
    
function writeTarif {
    param (
        $name,
        $path
    )
    $fullPath = Join-Path -Path $path -ChildPath $name
    try {
        New-Item -Path $path -Name $name -ItemType 'file' -Value $initialValue -ErrorAction Stop | Out-Null
        writeInfo -name $fullPath
    }
    catch {
        writeError -name $fullPath
    }
}

$path = 'C:\test'
$year = '2019'
$initialValue = '<Product>
                    <Name>Widget</Name>
                    <Details>
                        <Description>
                            This Widget is the highest quality widget. 
                        </Description>
                        <Price>5.50</Price>
                    </Details>
                </Product>'

$folders = Get-ChildItem -Path $path | Where-Object {$_.Psiscontainer} | Select-Object FullName
$tarif = 'tarif_' + $year + '.xml'
$tarifVk = 'tarifVk_' + $year + '.xml'

foreach($folder in $folders) {
    writeTarif -name $tarif -path $folder.FullName
    writeTarif -name $tarifVk -path $folder.FullName
}
