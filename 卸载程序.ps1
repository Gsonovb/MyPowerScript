$keyword="azure"

$list= Get-WmiObject -Class Win32_Product
$apps =$list| Where-Object { $_.Name -match $keyword}


foreach ($app in $apps)
{
    write-host uninstall... $app.name
    $app.Uninstall()
}

