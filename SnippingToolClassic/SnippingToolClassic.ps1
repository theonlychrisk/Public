<#   
.SYNOPSIS
    Deploys the Classic Snipping Tool from Windows 10.

.NOTES
    Author:     Christian Kumpfmueller
    Date:       07.07.2023
    Changelog:  v1.0 Initial version
#>

# Defaults
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

# Copy EXE
$SourceEXE = ".\SnippingTool.exe"
$DestinationEXE = "C:\Windows\System32\SnippingTool.exe"
if (!(Test-Path $DestinationEXE)) {
    try {
        Copy-Item $SourceEXE $DestinationEXE -Force
        Write-Host "[SUCCESS] Copied $Source.EXE to $DestinationEXE"
    }
    catch {
        Write-Warning "[ERROR] $($_.Exception.Message)"
    }
}

# Set ACL for MUI
$path = "C:\Windows\System32\de-DE"
$permission = "NT-AUTORITÄT\System","FullControl","Allow"
$acl = (Get-Acl $path)
$acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule $permission)) 
$acl | Set-Acl $path

# Copy MUI
$SourceMUI = ".\SnippingTool.exe.mui"
$DestinationMUI = "C:\Windows\System32\de-DE\SnippingTool.exe.mui"
if (!(Test-Path $DestinationMUI)) {
    try {
        Copy-Item $SourceMUI $DestinationMUI -Force
        Write-Host "[SUCCESS] Copied $Source.MUI to $DestinationMUI"
    }
    catch {
        Write-Warning "[ERROR] $($_.Exception.Message)"
    }
}

# Create Shortcut on Public Desktop
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\SnippingToolClassic.lnk")
$Shortcut.TargetPath = "$DestinationEXE"
$Shortcut.Save()

# Exit handling
exit 0