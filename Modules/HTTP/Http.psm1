function ConvertTo-BasicAuth  {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $Credential
    )
    $pair = "$($Credential.UserName):$(ConvertFrom-SecureString -SecureString $Credential.Password -AsPlainText)"
    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
    return $encodedCreds
}