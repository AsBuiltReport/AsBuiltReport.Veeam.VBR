# Get public and private function definition files and dot source them
$Public = @(Get-ChildItem -Path $PSScriptRoot\Src\Public\*.ps1 -ErrorAction SilentlyContinue)
$Diagram = @(Get-ChildItem -Path $PSScriptRoot\Src\Private\Diagram\*.ps1 -ErrorAction SilentlyContinue)
$Report = @(Get-ChildItem -Path $PSScriptRoot\Src\Private\Report\*.ps1 -ErrorAction SilentlyContinue)

$ModuleFolders = @($Public + $Diagram + $Report)

if ($PSVersionTable.PSEdition -eq 'Core') {
    $GUI = @(Get-ChildItem -Path $PSScriptRoot\Src\Private\Gui\*.ps1 -ErrorAction SilentlyContinue)
    $ModuleFolders += $GUI
}


foreach ($Module in $ModuleFolders) {
    try {
        . $Module.FullName
    } catch {
        Write-Error -Message "Failed to import function $($Module.FullName): $_"
    }
}

Export-ModuleMember -Function $Public.BaseName
Export-ModuleMember -Function $Diagram.BaseName
Export-ModuleMember -Function $Report.BaseName
if ($PSVersionTable.PSEdition -eq 'Core') {
    Export-ModuleMember -Function $GUI.BaseName
}