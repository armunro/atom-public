$API_BASE_URI = 'https://api.airtable.com/v0'


function Find-AirtableRecord {
    [OutputType('pscustomobject')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $BaseId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $Table,

        [Parameter()]
        $FilterFormula,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        $View,
        $ApiKey
    )

    $ErrorActionPreference = 'Stop'

 

    $uri = Get-AirtableUriString -BaseId $BaseId -Table $Table
    $invParams = @{
        Uri    = $Uri
        ApiKey = $ApiKey
    }
    $httpBody = @{}
    if ($PSBoundParameters.ContainsKey('FilterFormula')) {
        $httpBody['filterByFormula'] = $FilterFormula
    }
    if ($PSBoundParameters.ContainsKey('View')) {
        $httpBody['view'] = $View
    }
    if ($httpBody.Keys -gt 0) {
        $invParams.HttpBody = $httpBody
    }
    Invoke-AirtableApiCall @invParams
    
}

function Update-AirtableRecord {

    [OutputType('void')]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Default')]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ByObject')]
        [ValidateNotNullOrEmpty()]
        [pscustomobject]$InputObject,

        [Parameter(Mandatory, ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^rec')]
        [string]$Id,

        [Parameter(Mandatory, ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [string]$BaseId,

        [Parameter(Mandatory, ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [string]$Table,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Fields,

        [Parameter(Mandatory)]
        [string] $ApiKey,
        [switch]$PassThru
    )

    begin {
        $ErrorActionPreference = 'Stop'
    }
    
    process {
        if ($PSCmdlet.ParameterSetName -eq 'ById') {
            $filterFormula = 'RECORD_ID()="{0}"' -f $Id
            $InputObject = Find-AirtableRecord -BaseId $BaseId -Table $Table -FilterFormula $filterFormula -ApiKey $ApiKey
        }
        else {

        }
        $uri = Get-AirtableUriString -BaseId $InputObject.'Base ID' -Table $InputObject.Table -RecordId $InputObject.'Record ID'

        $invParams = @{
            Uri      = $uri
            Method   = 'PATCH'
            HttpBody = @{ 'fields' = $Fields }
            ApiKey = $ApiKey
        }

        $targetMsg = "AirTable Record ID [$($InputObject.'Record ID')] in table [$($InputObject.Table)]"
        $actionMsg = "Update fields [$($Fields.Keys -join ',')] to [$($Fields.Values -join ',')]"
        if ($PSCmdlet.ShouldProcess($targetMsg, $actionMsg)) {
            if ($PassThru.IsPresent) {
                Invoke-AirtableApiCall @invParams
            }
            else {
                Invoke-AirtableApiCall @invParams | Out-Null
            }
        }
    }
}

function Remove-AirtableRecord {

    [OutputType('void')]
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ByObject')]
        [ValidateNotNullOrEmpty()]
        [pscustomobject]$InputObject
    )


    $ErrorActionPreference = 'Stop'

    $uri = Get-AirtableUriString -BaseId $InputObject.'Base ID' -Table $InputObject.Table -RecordId $InputObject.'Record ID'

    $invParams = @{
        Uri    = $uri
        Method = 'DELETE'
    }

    $targetMsg = "AirTable Record ID [$($InputObject.'Record ID')] in table [$($InputObject.Table)]"
    $actionMsg = 'Remove'
    if ($PSCmdlet.ShouldProcess($targetMsg, $actionMsg)) {
        Invoke-AirtableApiCall @invParams
    }
}

function New-AirtableRecord {

    [OutputType('void')]
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Table,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Fields,

        [switch]$PassThru
    )


    $ErrorActionPreference = 'Stop'

    $baseId = GetBaseId -Identity $BaseId

    $uri = Get-AirtableUriString -BaseId $baseId -Table $Table

    $invParams = @{
        Uri      = $uri
        Method   = 'POST'
        HttpBody = @{ 'fields' = $Fields }
    }

    $targetMsg = "New AirTable Record in table [$($Table)]"
    $actionMsg = "Fields [$($Fields.Keys -join ',')] to [$($Fields.Values -join ',')]"
    if ($PSCmdlet.ShouldProcess($targetMsg, $actionMsg)) {
        if ($PassThru.IsPresent) {
            Invoke-AirtableApiCall @invParams
        }
        else {
            Invoke-AirtableApiCall @invParams | Out-Null
        }
    }
}

function Invoke-AirtableApiCall {
    [OutputType('pscustomobject')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Uri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [hashtable]$HttpBody,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Method = 'GET',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ApiKey
    )
    #Write-Host "Airtable Endpoint: $Uri"
    $ErrorActionPreference = 'Stop'

    try {
        $headers = @{
            'Authorization' = "Bearer $ApiKey"
        }
        
        $invRestParams = @{
            Method  = $Method
            Headers = $headers
            Uri     = $Uri
        }

        switch ($Method) {
            'GET' {
                if ($PSBoundParameters.ContainsKey('HttpBody')) {
                    $invRestParams.Body = $HttpBody
                }
                break
            }
            { $_ -in 'PATCH', 'POST', 'DELETE' } {
                $invRestParams.ContentType = 'application/json'
                if ($PSBoundParameters.ContainsKey('HttpBody')) {
                    $invRestParams.Body = (ConvertTo-Json $HttpBody)
                }
                break
            }
            default {
                throw "Unrecognized input: [$_]"
            }
        }

        $response = Invoke-RestMethod @invRestParams
        
        if ('records' -in $response.PSObject.Properties.Name) {
            $baseId = $Uri.split('/')[4]
            $table = $Uri.split('/')[5]
            $response.records.foreach({
                    $output = $_.fields
                    $output | Add-Member -MemberType NoteProperty -Name 'Record ID' -Value $_.id
                    $output | Add-Member -MemberType NoteProperty -Name 'Base ID' -Value $baseId
                    $output | Add-Member -MemberType NoteProperty -Name 'Table' -Value $table -PassThru
                })
            
            while ('offset' -in $response.PSObject.Properties.Name) {
                $invParams = [hashtable]$PSBoundParameters
                if ($invParams['HttpBody'] -and $invParams['HttpBody'].ContainsKey('offset')) {
                    $invParams['HttpBody'].offset = $response.offset
                }
                else {
                    $invParams['HttpBody'] = $HttpBody + @{ offset = $response.offset }
                }
                
                Invoke-AirtableApiCall @invParams | Tee-Object -Variable response
            }
        }
        elseif ('fields' -in $response.PSObject.Properties.Name) {
            $baseId = $Uri.split('/')[4]
            $table = $Uri.split('/')[5]
            $output = $response.fields
            $output | Add-Member -MemberType NoteProperty -Name 'Record ID' -Value $response.id
            $output | Add-Member -MemberType NoteProperty -Name 'Base ID' -Value $baseId
            $output | Add-Member -MemberType NoteProperty -Name 'Table' -Value $table -PassThru
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

function Get-AirtableUriString {

    [OutputType('string')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Table,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$RecordId
    )

    $ErrorActionPreference = 'Stop'

    $uriParts = @($API_BASE_URI, $BaseId, $Table)
    if ($PSBoundParameters.ContainsKey('RecordId')) {
        $uriParts += $RecordId
    }
    $uriParts -join '/'
}
