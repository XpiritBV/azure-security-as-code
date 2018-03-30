#Import Helpers
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here/SecurityAsCode-Helpers.ps1"


function Store-Asac-LoginConfig{
    param
    (
        [string] $principalId,
        [string] $password,
        [string] $tenantId,
        [string] $subscription,
        [string] $key,
        [string] $outputPath
    )

    $configDict = [ordered]@{
        principalId = $principalId
        password = $password
        tenantId = $tenantId
        subscription = $subscription
    }

    $loggedIn = _Login -config $configDict
    if($loggedIn -eq $true){
        Write-Host "Logged In" -ForegroundColor Green
    }else
    {
        Write-Host "NOT Logged In" -ForegroundColor Red
        return
    }

    $outputPath = _Get-Asac-OutputPath -outputPath $outputPath 
    $encryptionKey = Set-Key $key
    $pw = Set-EncryptedData -key $encryptionKey -plainText $password
    $configDict["password"] = $pw.ToString()

    $file = Join-Path $outputPath -ChildPath "asac-account.yml"
    ConvertTo-YAML $configDict > $file
}

function Get-Asac-Config{
    param
    (
        [string] $basePath,
        [string] $key
    )

    $basePath = _Get-Asac-OutputPath -outputPath $basePath

    $file = Join-Path $basePath -ChildPath "asac-account.yml"
    $yamlContent = Get-Content -Path $file -Raw
    $config = ConvertFrom-Yaml $yamlContent

    $encryptionKey = Set-Key $key
    $config.password = Get-EncryptedData -data $config.password -key $encryptionKey

    return $config
}

function _Set-Key {
    param([string]$string)
    $length = $string.length
    $pad = 32-$length
    if (($length -lt 16) -or ($length -gt 32)) {Throw "String must be between 16 and 32 characters"}
    $encoding = New-Object System.Text.ASCIIEncoding
    $bytes = $encoding.GetBytes($string + "0" * $pad)
    return $bytes
}

function _Set-EncryptedData {
    param($key,[string]$plainText)
    $securestring = new-object System.Security.SecureString
    $chars = $plainText.toCharArray()
    foreach ($char in $chars) {$secureString.AppendChar($char)}
    $encryptedData = ConvertFrom-SecureString -SecureString $secureString -Key $key
    return $encryptedData
}

function _Get-EncryptedData {
    param($key,$data)
    $data | ConvertTo-SecureString -key $key |
    ForEach-Object {[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($_))}
}