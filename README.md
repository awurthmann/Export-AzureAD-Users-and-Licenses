# Export-AzureAD-Users-and-Licenses
Exports all Azure AD users and their assigned licenses to a CSV file.
Privileged access is NOT needed to run this script.

## Legal:
You the executor, runner, user accept all liability.
This code comes with ABSOLUTELY NO WARRANTY.
You may redistribute copies of the code under the terms of the GPL v3.

## Warning:
This script pulls nearly the entirety of your organizations user accounts into memory.
I recommend rebooting or at the very least quitting PowerShell afterward.

## Instructions:
Running from a PowerShell prompt: 
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\Export-AzureAD-Users-and-Licenses.ps1
```
OR
Running from a Run or cmd.exe prompt: 
```powershell
powershell -ExecutionPolicy Bypass -File ".\Export-AzureAD-Users-and-Licenses.ps1"
```
