function Write-AtomHelloWorld{
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $Name
    )
    if($Name){
        Write-Host "Hello, $Name!"
    }
    else{
        Write-Host "Hello, World!"
    }
}
