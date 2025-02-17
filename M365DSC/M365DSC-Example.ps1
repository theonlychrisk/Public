<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'

.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.

.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'

.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.

.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>

# Check if module is installed
$ModuleName = "Microsoft365DSC"
$IsModuleInstalled = Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue | Out-Null
if (!($IsModuleInstalled)) {
    Write-Host "[INFO] $ModuleName not found - starting installation..."
    Install-Module -Name $ModuleName -Force -Scope CurrentUser -Verbose
}
else {
    Write-Host "[INFO] $ModuleName already installed - starting updates..."
    Update-M365DSCModule -Scope CurrentUser
    Update-M365DSCDependencies
    Uninstall-M365DSCOutdatedDependencies
}
