function Get-BitwardenIsLoggedIn() {
    bw login --check | Out-Null
    $isLoggedIn = $?
    return $isLoggedIn
}

function Get-BitwardenIsUnlocked() {
    bw unlock --check | Out-Null
    $isUnlocked = $?
    return $isUnlocked
}

function Get-BitwardenItem() {
    [Alias("bwitem")]
    Param(
        $ItemId
    )
    return (& bw get item $ItemId) | ConvertFrom-Json

}

function Search-BitwardenItem() {
    [Alias("bwsearch")]
    Param(
        $Search
    )
    return (& bw list items --search $Search) | ConvertFrom-Json

}
function Get-BitwardenSession() {
    return $env:BW_SESSION
}

function Start-BitwardenSession() {
    $session = ""
    if (-not (Get-BitwardenIsLoggedIn)) {
        $session = & bw login --raw
    }
    else {
        if (-not(Get-BitwardenIsUnlocked)) {
            $session = & bw unlock --raw
        }
    }
    $env:BW_SESSION = $session
}


function Copy-BitwardenItemFieldToClipboard {
    [Alias("bwicp")]
    Param(
        $ItemId,
        $Field
    )

    $bwItem = Get-BitwardenItem -ItemId $ItemId
    $itemValue = Invoke-Expression "`$bwItem.$Field"
    Set-Clipboard $itemValue
}

function Get-BitwardenAttachment() {
    [Alias("bwa")]
    Param(
        $ItemId,
        $Attachment,
        $Destination,
        $Session
    )

    & bw get attachment $Attachment --itemid $ItemId --output $Destination --session $Session --quiet
}