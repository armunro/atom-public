function Import-BitwardenSSHKey
{
    Param(
        $Profile
    )
    Write-Host (Get-BitwardenSession) -ForegroundColor Cyan

    if(-not(Get-BitwardenSession))
    {
        Start-BitwardenSession
        Write-Host (Get-BitwardenSession) -ForegroundColor Cyan
    }
   
    $workDir = Join-Path $([System.IO.Path]::GetTempPath() ) $([System.Guid]::NewGuid() )
    [void](New-Item -Type Directory -Path $workDir -Force)

    $profileContent = Get-Content $Profile | ConvertFrom-Json
    $profileContent.Formats | Foreach-Object {
        $attachmentName = $_.Attachment
        $attchmentDownloadPath = ($workDir | Join-Path -ChildPath $attachmentName)
        Get-BitwardenAttachment -ItemId $profileContent.ItemId -Attachment $attachmentName -Destination $attchmentDownloadPath

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







