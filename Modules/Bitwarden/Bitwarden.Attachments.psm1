function Get-BitwardenAttachment() {
    [Alias("bwa")]
    Param(
        $ItemId,
        $Attachment,
        $Destination
    )
    & bw get attachment $Attachment --itemid $ItemId --output "$Destination"
}