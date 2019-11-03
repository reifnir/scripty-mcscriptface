function Safe-ConvertFromBase64([string]$encoded) {
    # base64 will only ever have 0, 1 or 2 characters of padding
    # there are better ways, but no need to optimize a function that's called a few times ever (yet)
    # only needed because there was an external API that was returning base64 strings without the necessary padding
    try { return [Convert]::FromBase64String($encoded) }
    catch
    {
        try { return [Convert]::FromBase64String("$encoded=") }
        catch
        {
            return [Convert]::FromBase64String("$encoded==")
        }
    }
}

function Test-Safe-ConvertFromBase64([string]$value, [int]$expectedPadding) {
    $encoding = [System.Text.Encoding]::Unicode

    if ($value -eq $null) {
        Write-Host '$value is null'        
        #return null or empty string or throw exception...
        return $null
    }

    Write-Host "Testing Safe-ConvertFromBase64..."
    $encoded = [Convert]::ToBase64String($encoding.GetBytes($value))
    Write-Host "   Base64 encoded value with padding: $encoded"

    $missingPadding = $encoded.TrimEnd('=')
    Write-Host "   Base64 encoded value without padding: $missingPadding"

    if ($encoded.Length - $missingPadding.Length -ne $expectedPadding)
    {
        #throw, log error, however you test..
        Write-Host "ERROR: Expected $expectedPadding '=' characters at the end of base64 encoding, but there were actually $($encoded.Length - $missingPadding.Length)"
    }

    $decodedBytes = Safe-ConvertFromBase64 $missingPadding
    $decodedValue = $encoding.GetString($decodedBytes)
    Write-Host "   Original string: $value"
    Write-Host "   Decoded string: $decodedValue"

    if ($value -ne $decodedValue) {
        #throw, log error, however you test..
        Write-Host "ERROR: Final string did not match the same as the original one"
    }
    else {
        Write-Host "   PASS: strings match"
    }
}

Test-Safe-ConvertFromBase64 "what-padding" 0
Test-Safe-ConvertFromBase64 "something-with-only-one-padding" 1
Test-Safe-ConvertFromBase64 "something-with-two-padding" 2
