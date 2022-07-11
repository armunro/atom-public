<#
.SYNOPSIS
Retrives the persisted command history saved by PSReadline

.DESCRIPTION
PowerShell can provide a history of commands that were executed in *the current session.*
One drawback is that, unlike most Unix shells, the history is lost when the session is closed.
This function onnly works if the `PSReadLine` module is installed and imported.
PSReadline keeps peristent a history that is equatable to aformentioned Unix shells

.PARAMETER Last
[Int]       Limits the number of results as logs can get large

.OUTPUTS
[String[]]  Array of executed commands as strings
#>
function Get-PSReadlineHistory
{
    [Alias("rlhistory")]
    Param(
        [int]
        $Last = 20
    )
    (Get-Content (Get-PSReadlineOption).HistorySavePath) | Select-Object -Last $Last
}