<#
.SYNOPSIS
    Shows all Intune assignments for an Entra ID group.

.NOTES
    Author:     Christian Kumpfmueller, special credits to https://timmyit.com/2023/10/09/get-all-assigned-intune-policies-and-apps-from-a-microsoft-entra-group/
    Date:       2024-04-16
    Changelog:  v1.0 - Initial version, will ask for Group Name with Read-Host
                v1.1 - Updated to new Microsoft.Graph cmdlets
                v1.2 - Optimized formatting, comments and output
#>

# Please specify the name of the group for which we want to check its assignments
$GroupName = Read-Host "Please enter Group Name"

# Define required modules
$RequiredModules = @(
  "Microsoft.Graph.DeviceManagement",
  "Microsoft.Graph.Groups"
)

# Install required modules
foreach ($Module in $RequiredModules) {
  if (!(Get-Module -ListAvailable -Name $Module)) {
    Write-Host "[INFO] Installing required module: $Module"
    Install-Module -Name $Module -Force -AllowClobber
    Import-Module -Name $Module -Force
    Write-Host "[INFO] Installed required module: $Module"
  }
  else {
    Import-Module -Name $Module -Force
    Write-Host "[INFO] Required module already installed: $Module"
  }
}

# Connect to Graph
Write-Host "[INFO] Connecting to Microsoft Graph: Please check authentication window" -ForegroundColor Yellow
Connect-MgGraph -Scopes Group.Read.All, DeviceManagementManagedDevices.Read.All, DeviceManagementServiceConfig.Read.All, DeviceManagementApps.Read.All, DeviceManagementConfiguration.Read.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementApps.ReadWrite.All -NoWelcome
$Group = Get-MgGroup -Filter "DisplayName eq '$GroupName'"

### Device Compliance Policy
$Resource = "deviceManagement/deviceCompliancePolicies"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$AllDCPId = (Invoke-MgGraphRequest -Method GET -Uri $uri).Value | Where-Object { $_.assignments.target.groupId -match $Group.id }

Write-Host "Following Device Compliance Policies has been assigned to: $($Group.DisplayName)" -ForegroundColor Cyan
foreach ($DCPId in $AllDCPId) {
  Write-Host "$($DCPId.DisplayName)" -ForegroundColor Yellow
}

# Applications 
$Resource = "deviceAppManagement/mobileApps"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$Apps = (Invoke-MgGraphRequest -Method GET -Uri $uri).Value | Where-Object { $_.assignments.target.groupId -match $Group.id }

Write-Host "Following Apps has been assigned to: $($Group.DisplayName)" -ForegroundColor Cyan
foreach ($App in $Apps) {
  Write-Host "$($App.DisplayName)" -ForegroundColor Yellow
}

# Application Configurations (App Configs)
$Resource = "deviceAppManagement/targetedManagedAppConfigurations"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$AppConfigs = (Invoke-MgGraphRequest -Method GET -Uri $uri).Value | Where-Object { $_.assignments.target.groupId -match $Group.id }

Write-Host "Following App Configuration has been assigned to: $($Group.DisplayName)" -ForegroundColor Cyan
foreach ($AppConfig in $AppConfigs) {
  Write-Host "$($AppConfig.DisplayName)" -ForegroundColor Yellow
}

## App protection policies
$AppProtURIs = @{
  iosManagedAppProtections                = "https://graph.microsoft.com/beta/deviceAppManagement/iosManagedAppProtections?`$expand=Assignments"
  androidManagedAppProtections            = "https://graph.microsoft.com/beta/deviceAppManagement/androidManagedAppProtections?`$expand=Assignments"
  windowsManagedAppProtections            = "https://graph.microsoft.com/beta/deviceAppManagement/windowsManagedAppProtections?`$expand=Assignments"
  mdmWindowsInformationProtectionPolicies = "https://graph.microsoft.com/beta/deviceAppManagement/mdmWindowsInformationProtectionPolicies?`$expand=Assignments"
}

$graphApiVersion = "Beta"

$AllAppProt = $null
foreach ($url in $AppProtURIs.GetEnumerator()) {
  $AllAppProt = (Invoke-MgGraphRequest -Method GET -Uri $url.value).Value | Where-Object { $_.assignments.target.groupId -match $Group.id } -ErrorAction SilentlyContinue
  Write-Host "Following App Protection / "$($url.name)" has been assigned to: $($Group.DisplayName)" -ForegroundColor Cyan
  
  foreach ($AppProt in $AllAppProt) {
    Write-Host "$($AppProt.DisplayName)" -ForegroundColor Yellow
  }
} 

# Device Configuration
$DCURIs = @{
  ConfigurationPolicies     = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$expand=Assignments"
  DeviceConfigurations      = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$expand=Assignments"
  GroupPolicyConfigurations = "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations?`$expand=Assignments"
  mobileAppConfigurations   = "https://graph.microsoft.com/beta/deviceAppManagement/mobileAppConfigurations?`$expand=Assignments"
}
  
$AllDC = $null
foreach ($url in $DCURIs.GetEnumerator()) {
  $AllDC = (Invoke-MgGraphRequest -Method GET -Uri $url.value).Value | Where-Object { $_.assignments.target.groupId -match $Group.id } -ErrorAction SilentlyContinue
  Write-Host "Following Device Configuration / "$($url.name)" has been assigned to: $($Group.DisplayName)" -ForegroundColor Cyan
    
  foreach ($DCs in $AllDC) {
    #If statement because ConfigurationPolicies does not contain DisplayName. 
    if ($($null -ne $DCs.displayName)) { 
      Write-Host "$($DCs.DisplayName)" -ForegroundColor Yellow
    } 
    else {
      Write-Host "$($DCs.Name)" -ForegroundColor Yellow
    } 
  }
} 

### Remediation scripts 
$uri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"
$REMSC = Invoke-MgGraphRequest -Method GET -Uri $uri
$AllREMSC = $REMSC.value 
Write-Host "Following Remediation Script has been assigned to: $($Group.DisplayName)" -ForegroundColor Cyan
 
foreach ($Script in $AllREMSC) {
  $SCRIPTAS = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$($Script.Id)/assignments").value 

  if ($SCRIPTAS.target.groupId -match $Group.Id) {
    Write-Host "$($Script.DisplayName)" -ForegroundColor Yellow
  }
}

### Platform Scrips / Device Management 
$Resource = "deviceManagement/deviceManagementScripts"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts"
$PSSC = Invoke-MgGraphRequest -Method GET -Uri $uri
$AllPSSC = $PSSC.value
Write-Host "Following Platform Scripts / Device Management scripts has been assigned to: $($Group.DisplayName)" -ForegroundColor Cyan

foreach ($Script in $AllPSSC) {
  $SCRIPTAS = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$($Script.Id)/assignments").value 

  if ($SCRIPTAS.target.groupId -match $Group.Id) {
    Write-Host "$($Script.DisplayName)" -ForegroundColor Yellow
  }
}

### Windows Autopilot profiles
$Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$Response = Invoke-MgGraphRequest -Method GET -Uri $uri
$AllObjects = $Response.value
Write-Host "Following Autopilot Profiles has been assigned to: $($Group.DisplayName)" -ForegroundColor Cyan

foreach ($Script in $AllObjects) {
  $APProfile = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles/$($Script.Id)/assignments").value 

  if ($APProfile.target.groupId -match $Group.Id) {
    Write-Host "$($Script.DisplayName)" -ForegroundColor Yellow
  }
}

# Close Graph connection
Disconnect-Graph | Out-Null