#executes AZ command and returns an PSObject
function Execute-AzCommandLine
{
    param
    (
        [string] $azCommandLine
    )

    $resultJson  = "$(Invoke-Expression $azCommandLine)"
    $result = ConvertFrom-Json $resultJson 
    
    return $result
}

