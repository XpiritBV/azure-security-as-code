#executes AZ command and returns an PSObject
function Invoke-Asac-AzCommandLine
{
    param
    (
        [string] $azCommandLine
    )

    $resultJson  = "$(Invoke-Expression $azCommandLine)"
    $result = ConvertFrom-Json $resultJson 
    
    return $result
}

function _Get-Asac-OutputPath
{
    param 
    (
        [string] $outputPath
    )
    
    if ($outputPath -eq "" -or $outputPath -eq $null)  
    {
        $outputPath = $PSScriptRoot
    }
    return $outputPath
}

