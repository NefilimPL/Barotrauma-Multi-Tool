# Close processes holding the checkout before running this helper.
[CmdletBinding(SupportsShouldProcess = $true)]
param()

$ErrorActionPreference = 'Stop'
$aegisRepository = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$aegisParent = [System.IO.Path]::GetDirectoryName($aegisRepository)
$aegisDestination = [System.IO.Path]::GetFullPath((Join-Path $aegisParent 'System-Aegis'))

if ($aegisRepository -eq $aegisDestination) {
    Write-Output "Repository already named System-Aegis: $aegisRepository"
    return
}
if (-not (Test-Path -LiteralPath (Join-Path $aegisRepository '.git')) -or
    -not (Test-Path -LiteralPath (Join-Path $aegisRepository 'System-Aegis/filelist.xml'))) {
    throw 'Expected System Aegis repository and package were not found. Nothing moved.'
}
if ([System.IO.Path]::GetDirectoryName($aegisDestination) -ne $aegisParent -or
    (Test-Path -LiteralPath $aegisDestination)) {
    throw "Destination is not available: $aegisDestination. Nothing moved."
}

if ($PSCmdlet.ShouldProcess($aegisRepository, "Rename repository directory to $aegisDestination")) {
    # Release this PowerShell process's own current-directory handle first.
    Set-Location -LiteralPath $aegisParent
    try {
        Rename-Item -LiteralPath $aegisRepository -NewName 'System-Aegis' -ErrorAction Stop
    } catch {
        throw ('Close processes using this checkout, then run the script again. ' + $_.Exception.Message)
    }
    Write-Output "Repository renamed: $aegisDestination"
}