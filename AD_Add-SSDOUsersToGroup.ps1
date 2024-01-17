<#
.SYNOPSIS
Reads a CSV file containing a list of users' school emails, checks if they are already members of a specified group, and adds them if not.
Logs actions and results to a log file.

.DESCRIPTION
This script reads a CSV file containing a list of users' school emails, checks if they are already members of a specified group in Active Directory, and adds them to the group if they are not already members. Actions and results are logged to a log file.

.PARAMETER CsvPath
Specifies the path to the CSV file containing user data.

.PARAMETER CsvColumnTitle
Specifies which column in the CSV file to read.

.PARAMETER GroupName
Specifies the name of the group to which users should be added.

.PARAMETER LogFilePath
Specifies the path to the log file where actions and results will be logged.

.EXAMPLE
Add-SSDOUsersToGroup -CsvPath "C:\temp\23FA Registered Students.csv" -GroupName "Tyler_Test_Group" -LogFilePath "C:\temp\log.txt"

This example reads user emails from the CSV file and adds them to the specified group, while logging actions and results to the log file.

.NOTES
Author: Tyler Tourot
Date: 8/9/2023
#>

function Add-SSDOUsersToGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [string]$CsvPath,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$CsvColumnTitle,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$GroupName,

        [Parameter(Position = 3)]
        [string]$LogFilePath = "C:\temp\log.txt"
    )

    Begin {
        # Import the Active Directory module
        Import-Module ActiveDirectory

        # Initialize the log content
        $logContent = @()
    }

    Process {
        # Read the CSV file
        $csvData = Import-Csv -Path $CsvPath

        # Iterate through each row in the CSV and add users to the group
        foreach ($row in $csvData) {
            $username = $row.$CsvColumnTitle
            $userObject = Get-ADUser -Filter {UserPrincipalName -eq $username}
            
            if ($userObject) {
                $groupMembers = Get-ADGroupMember -Identity $GroupName | Select -ExpandProperty distinguishedName
                $userObjectDN = $userObject.distinguishedname
                if ($groupMembers -contains $userObjectDN) {
                    $logEntry = "$(Get-Date) - $username is already a member of $GroupName."
                    $logContent += $logEntry
                    Write-Host $logEntry
                } else {
                    Add-ADGroupMember -Identity $GroupName -Members $userObject
                    $logEntry = "$(Get-Date) - Added $username to $GroupName"
                    $logContent += $logEntry
                    Write-Host $logEntry
                }
            } else {
                $logEntry = "$(Get-Date) - User $username not found."
                $logContent += $logEntry
                Write-Host $logEntry
            }
        }
    }

    End {
        # Write the log content to the log file
        $logContent | Out-File -FilePath $LogFilePath -Append
    }
}