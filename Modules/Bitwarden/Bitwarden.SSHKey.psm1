function Import-BitwardenSSHKey
{
    Param(
        $Profile
    )

    if([String]::IsNullOrWhitespace( (Get-BitwardenSession)))
    {
        Start-BitwardenSession
    }
   
    $workDir = Join-Path $([System.IO.Path]::GetTempPath() ) $([System.Guid]::NewGuid() )
    [void](New-Item -Type Directory -Path $workDir -Force)

    $profileContent = Get-Content $Profile | ConvertFrom-Json



    $session = Get-BitwardenSession

    
    $profileContent.Formats | Foreach-Object {
        $attachmentName = $_.Attachment
        $attchmentDownloadPath = ($workDir | Join-Path -ChildPath $attachmentName)
        Get-BitwardenAttachment -ItemId $profileContent.ItemId -Attachment $attachmentName -Destination $attchmentDownloadPath -Session $session

        if ($IsLinux -and ($_.Format -eq 'openssh')) {
            Import-SSHAgentLinuxKey -KeyPath $attchmentDownloadPath
        }
        if ($IsWindows) {
            Switch ($_.Format) {
                openssh {
                    Import-SSHAgentWindowsKey -KeyPath $attchmentDownloadPath
                }
                putty {
                    Import-PageantKey -KeyPath $attchmentDownloadPath
                }
            }
        }
        
    }
    Remove-Item $workDir -Force -Recurse
}







