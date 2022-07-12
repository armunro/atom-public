function Import-SSHAgentWindowsKey($KeyPath)
{
    Set-KeyFileWindowsSafeACLs -KeyPath $KeyPath | Out-Null
    $agentService = Get-Service ssh-agent
    if ($agentService.Status -ne "Running") {
        $agentService | Set-Service -StartupType Manual
        $agentService | Start-Service
    }
    ssh-add.exe $KeyPath
}

function Set-KeyFileWindowsSafeACLs($KeyPath)
{
    Icacls $KeyPath /c /t /Inheritance:d | Out-Null
    Icacls $KeyPath /c /t /Grant ${env:UserName}:F  | Out-Null
    TakeOwn /F $KeyPath  | Out-Null
    Icacls $KeyPath /c /t /Grant:r ${env:UserName}:F  | Out-Null
    Icacls $KeyPath /c /t /Remove:g Administrator "Authenticated Users" BUILTIN\Administrators BUILTIN Everyone System Users  | Out-Null
    Icacls $KeyPath  | Out-Null
}


function Import-PageantKey($KeyPath)
{
    Set-KeyFileWindowsSafeACLs -KeyPath $KeyPath
    pageant.exe $KeyPath
    Start-Sleep -Seconds 1
}
