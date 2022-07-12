function Get-BitwardenAttachment() {
    [Alias("bwa")]
    Param(
        $ItemId,
        $Attachment,
        $Destination,
        $Session
    )
    & bw get attachment $Attachment --itemid $ItemId --output "$Destination" --session $Session
}