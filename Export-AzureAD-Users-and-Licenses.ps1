#powershell.exe


# Written by: Aaron Wurthmann
#
# You the executor, runner, user accept all liability.
# This code comes with ABSOLUTELY NO WARRANTY.
# You may redistribute copies of the code under the terms of the GPL v3.
#
# --------------------------------------------------------------------------------------------
# Name: Export-AzureAD-Users-and-Licenses.ps1
# Version: 2022.07.22.1600
# Description: Exports all Azure AD users and their assigned licenses to a CSV file.
#				Privileged access is NOT needed to run this script.
# 
# Instructions:
#	Running from a PowerShell prompt: Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
# 		.\Export-AzureAD-Users-and-Licenses.ps1
#	OR
#	Running from a Run or cmd.exe prompt: 
#		powershell -ExecutionPolicy Bypass -File ".\Export-AzureAD-Users-and-Licenses.ps1"
#	
# Tested with: Microsoft Windows [Version 10.0.22000.0], PowerShell [5.1.22000.653]
#	"Microsoft Windows [Version $([System.Environment]::OSVersion.Version)], PowerShell [$($PSVersionTable.PSVersion.ToString())]"
#
# Arguments:
#	-ExportPath 			Optional string value for path to export CSV file, default uses local directory
#	-InfoLog				True/False, Write to information log, default is true
#	-Disconnect				True/False, disconnect from Azure Cloud at completion of script, default is true
#	
# Example:
#	.\Export-AzureAD-Users-and-Licenses.ps1
#
# Output: 
#	CSV file, summary count to standard out, error and info files
#
# WARNING:
#	This script pulls nearly the entirety of your organization's user accounts into memory
#	 I recommend rebooting or at the very least quitting PowerShell afterward
#
# Notes:
#
# 
# -------------------------------------------------------------------------------------------- 

Param (
	[string]$ExportPath,
	[bool]$InfoLog=$True,
	[bool]$Disconnect=$True
)

###Functions
##Windows Check Function##
function isWindows {
	return $Env:OS -like "Windows*"
} 
##End Windows Check Function##

##Check if Admin Function##
function isAdmin {
#	Checks if the current user has "Administrator" privileges, returns True or False 
	If(isWindows) {
		$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
		return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
	}
	ElseIf ($IsMacOS) {
		If (groups $(users) -contains "admin") {
			return $True
		}
		Else {
			return $False
		}
	}
}
##End Check if Admin Function##

##Write-Log Function
function Write-Log {
	#Missing a file like method, may be prone to I/O errors during heavy writes.
	Param ([string]$LogPath,[string]$LogMessage)

	[string]$LineValue = "PS (C) ["+(Get-Date -Format HH:mm:ss:fff)+"]: $LogMessage"
	#Add-Content -Path $LogPath -Value $LineValue
	$LineValue >> $LogPath
}
##End Write-Log Function

##Write Color Function
function Write-Color {
<#
 
.SYNOPSIS
Reformats Write-Host output, allowing multiple colors on the same line.
 
.DESCRIPTION
Usually to output information in PowerShell we use Write-Host. By using parameter -ForegroundColor you can define nice looking output text. Write-Color takes things a step further, allowing for multiple colors on the same command.


.PARAMETER Text
Text to be used. Encolse with double quotes " " and seperate with comma ,

.PARAMETER Color
Color to use. Seperate with comma ,

.PARAMETER StartTab
Indent text wih a number of tabs.

.PARAMETER LinesBefore
Blank lines to insert before text.

.PARAMETER LinesAfter
Blank lines to insert after text.

.EXAMPLE
Write-Color -Text "Red ", "Green ", "Yellow " -Color Red,Green,Yellow

.EXAMPLE
Write-Color -Text "This is text in Green ",
	"followed by red ",
	"and then we have Magenta... ",
	"isn't it fun? ",
	"Here goes DarkCyan" -Color Green,Red,Magenta,White,DarkCyan

.NOTES
Orginal Author:  Przemys??aw K??ys
 Version 0.2
  - Added Logging to file
 Version 0.1
  - First Draft

Edited by: Aaron Wurthmann
 Versoin 0.2A
  - Removed logging to file ability. Conflicts with our preferred method.
  - Added If statment to encapsulate main body.
  - Removed initialization of StartTab, LinesBefore, LinesAfter and adjusted If statments to reflect change.
    + That's meerly a coding prefference, nothing wrong with Przemys??aw's way.
Edited and tested on PowerShell [Version 5.1.16299.251], Windows [Version 10.0.16299.309]

You can find the colors you can use by using simple code:
	[enum]::GetValues([System.ConsoleColor]) | Foreach-Object {Write-Host $_ -ForegroundColor $_ }

.LINK
Orginal Author's Site -  https://evotec.xyz/powershell-how-to-format-powershell-write-host-with-multiple-colors
#>

Param ([String[]]$Text, [ConsoleColor[]]$Color = "White", [int]$StartTab, [int]$LinesBefore, [int]$LinesAfter=1)

If ($Text) {
		$DefaultColor = $Color[0]
		if ($LinesBefore) {  for ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline } } # Add empty line before
		if ($StartTab) {  for ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewLine } }  # Add TABS before text
		if ($Color.Count -ge $Text.Count) {
			for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine } 
		} else {
			for ($i = 0; $i -lt $Color.Length ; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine }
			for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $DefaultColor -NoNewLine }
		}
		#Write-Host
		if ($LinesAfter) {  for ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" } }  # Add empty line after
	}
}
##End Write Color Function

##Install Modules
$Modules=Get-Module -ListAvailable
$RequiredModules=@("AzureAD")
$InstallModules=@()

ForEach ($RequiredModule in $RequiredModules){
	If ($Modules.Name -notcontains $RequiredModule) {
		$InstallModules += $RequiredModule
	}
}
If (($InstallModules).Count -gt 0) {
	$Expression="Install-Module " + $($InstallModules -join ',')
	
	If (isAdmin) {
		Invoke-Expression $Expression
	}
	Else {
		If (isWindows) {
			Start-Process powershell -Verb runAs -ArgumentList $Expression
		}
		ElseIf ($IsMacOS) {
			Invoke-Expression $Expression
		}
	}
}
Clear-Variable Modules,RequiredModules,InstallModules
##End Install Modules

###Environment Setup
##Script Name and Path
$ScriptPath=Split-Path $($MyInvocation.MyCommand.Path) -Parent
$ScriptName=$MyInvocation.MyCommand.Name
##End Script Name and Path

##Export File Settings
If(!($ExportPath)){
	$ExportPath=".\$($(Get-Date).ToUniversalTime().ToString("yyyyMMddHHmm"))_$($ScriptName)" -replace "ps1","csv"
}
#Clear-Variable ScriptPath,ScriptName
##End Export File Settings

##Log File Settings
$ErrorLogFile = '{0}.log' -f $ExportPath -replace "csv","error"
$InfoLogFile = '{0}.log' -f $ExportPath -replace "csv","info"
##End Log File Settings

##Use Pop-Up Browser for Azure AD
If (!($AzAdConnection)){
	$global:AzAdConnection=Connect-AzureAD
}
##End Use Pop-Up Browser for Azure AD

##Operating System Check
If ($IsMacOS) {
	Write-Host
	Write-Warning "This version of $ScriptName has not been fully tested on macOS `n         For best results use Windows 10 or higher"
	Write-Host
}
##End Operating System Check
###End Environment Setup

##Main
If (!($AzAdConnection)){
	$ErrorText="ERROR: Unable to connect to AzureCloud"
	If ($InfoLog) {Write-Log $InfoLogFile $ErrorText}
	Write-Log $ErrorLogFile $ErrorText
	Write-Error -Message "`n$ErrorText" -Category ConnectionError
	exit
}

$Started=Get-Date

If ($InfoLog) {
	Write-Log $InfoLogFile "Connect to $($AzAdConnection.Environment.Name)"
	Write-Log $InfoLogFile "TenantId: $($AzAdConnection.Tenant.Id.Guid)"
	Write-Log $InfoLogFile "TenantDomain: $($AzAdConnection.Tenant.Domain)"
	Write-Log $InfoLogFile "Account: $($AzAdConnection.Account.Id)"
	Write-Log $InfoLogFile "AccountType: $($AzAdConnection.Account.Type)"
	Write-Log $InfoLogFile "Retrieving Tenant SKUs: Get-AzureADSubscribedSku"
}

$OurSKU=Get-AzureADSubscribedSku

If (!($OurSKU)){
	$ErrorText="ERROR: Unable to retrieve to tenant SKUs"
	If ($InfoLog) {Write-Log $InfoLogFile $ErrorText}
	Write-Log $ErrorLogFile $ErrorText
	Write-Error -Message "`n$ErrorText" -Category InvalidResult
	exit
}

Write-Progress -Activity "Retrieving Enabled Accounts in AzureAD" -status "Running: Get-AzureADUser -All $True -Filter AccountEnabled eq true"

If ($InfoLog) {Write-Log $InfoLogFile "Running: Get-AzureADUser -All $True -Filter AccountEnabled eq true"}

$EnabledUsers=Get-AzureADUser -All $True -Filter "AccountEnabled eq true" | Select-Object -Property DisplayName,GivenName,Surname,
 UserPrincipalName,MailNickName,Mail,CompanyName,JobTitle,Department,
 @{label="AssignedLicenses";expression={ForEach ($i in $_.AssignedLicenses.SkuId){($OurSKU | Where {$i -eq $_.SkuId}).SkuPartNumber}}},
 @{label="AssignedPlans";expression={$_.AssignedPlans.Service}},
 @{label="ProvisionedPlans";expression={$_.ProvisionedPlans.Service}},
 @{label="ManagerUPN";expression={(Get-AzureADUserManager -ObjectId $_.ObjectID).UserPrincipalName}},
 @{label="employeeId";expression={$_.ExtensionProperty.employeeId}}
#

 
If (!($EnabledUsers)){
	$ErrorText="ERROR: No enabled users accounts were found"
	If ($InfoLog) {Write-Log $InfoLogFile $ErrorText}
	Write-Log $ErrorLogFile $ErrorText
	Write-Error -Message "`n$ErrorText" -Category InvalidResult
	exit
}

$Finished=Get-Date
$EnabledUsers | Export-CSV -NoTypeInformation -Force $ExportPath
$TotalEnabledCount=$($EnabledUsers.Count)
$AssignedLicenses=$(($EnabledUsers | Where {$_.AssignedLicenses}).Count)
$NotAssignedLicenses=$(($EnabledUsers | Where {! $_.AssignedLicenses}).Count)
$TimeElapsed=$(($Finished-$Started).ToString())

 
If ($InfoLog) {
	Write-Log $InfoLogFile "Total number of enabled accounts: $TotalEnabledCount"
	Write-Log $InfoLogFile "Number of accounts with assigned licenses: $AssignedLicenses"
	Write-Log $InfoLogFile "Number of accounts without assigned licenses: $NotAssignedLicenses"
	Write-Log $InfoLogFile "Time Elapsed: $TimeElapsed"
	Write-Log $InfoLogFile "Exported to $ExportPath"
}

Write-Host ""
Write-Color "Total number of enabled accounts: ", "$TotalEnabledCount" -Color White,Cyan
Write-Color "Number of accounts with assigned licenses: ", "$AssignedLicenses" -Color White,Green
Write-Color "Number of accounts without assigned licenses: ", "$NotAssignedLicenses" -Color White,Red
Write-Color "Time Elapsed: ", "$TimeElapsed" -Color White,Blue
Write-Color "Exported to ", "$ExportPath" -Color White,Magenta

If ($Disconnect){
	Disconnect-AzureAD
	Remove-Variable -Name "AzAdConnection" -Force -Scope "global"
}





