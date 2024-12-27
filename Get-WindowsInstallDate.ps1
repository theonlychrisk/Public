<#
.SYNOPSIS
    Gets Windows installation date using multiple methods.

.DESCRIPTION
    This script attempts to retrieve the Windows installation date using three different methods:
    1. Registry query
    2. CIM/WMI query
    3. Systeminfo command
    Methods are tried in sequence until one succeeds.

.EXAMPLE
    .\Get-WindowsInstallDate.ps1
    Returns Windows installation date in YYYY-MM-DD format.

.OUTPUTS
    System.DateTime

.NOTES
    Author:     Christian Kumpfmueller
    Date:       05.12.2024
    Changelog:  v1.0 - Initial version
#>

function Get-WindowsInstallDate {
    # Method 1: Try to get date from registry
    try {
        $regPath = 'HKLM:\System\Setup\Source*'
        if (Test-Path $regPath) {
            $regDate = Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\Setup\Source* |
                Select-Object -ExpandProperty InstallDate |
                Sort-Object -Descending |
                Select-Object -First 1
            
            return ([datetime]'1970-01-01').AddSeconds($regDate)  # Convert from Unix timestamp
        }
    }
    catch {
        Write-Debug "Registry method failed: $_"
    }

    # Method 2: Use CIM/WMI query
    try {
        $cimDate = (Get-CimInstance Win32_OperatingSystem).InstallDate
        if ($cimDate) { return $cimDate }
    }
    catch {
        Write-Debug "CIM method failed: $_"
    }

    # Method 3: Parse systeminfo command output
    try {
        $sysInfo = systeminfo | Select-String "Original Install Date"
        if ($sysInfo -match '\d{2}/\d{2}/\d{4}') {
            return [datetime]$matches[0]
        }
    }
    catch {
        throw "Failed to retrieve Windows install date using all available methods"
    }
}

# Main execution block
try {
    $installDate = Get-WindowsInstallDate
    Write-Host "Windows Installation Date: $($installDate.ToString('yyyy-MM-dd'))" -ForegroundColor Green
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}