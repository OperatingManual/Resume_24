<#
.SYNOPSIS
Adds users to different sets of groups based on their user role.

.DESCRIPTION
This function adds users to different sets of groups based on whether they are staff,
full-time faculty, or adjunct. It validates the provided user role, username, and 
log file path. It then adds the user to the appropriate groups and logs actions 
and results to the specified log file.

.PARAMETER UserRole
Specifies the user role. Allowed values are "Staff", "Full-Time Faculty", or "Adjunct".

.PARAMETER UserName
Specifies the username (SamAccountName) of the user to add to the groups.

.PARAMETER LogFilePath
Specifies the path to the log file. Default is "c:\temp\log.txt".

.EXAMPLE
Add-SSDOUsersToGroupsByRole -UserRole "Staff" -UserName "john.doe" -LogFilePath "C:\temp\log.txt"

This example adds the user "john.doe" to the specified groups for the staff user role
and logs the actions to the provided log file.
#>
function Add-SSDOUsersToGroupsByRole {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("Staff", "Full-Time Faculty", "Adjunct")]
        [string]$UserRole,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$UserName,

        [Parameter(Position = 3)]
        [string]$LogFilePath = "c:\temp\log.txt"
    )

    Begin {
        # Import the Active Directory module
        Import-Module ActiveDirectory

        # Define group names
        $staffGroups = @("Group Name", "Group Name", "Group Name", "Group Name", "Group Name", "Group Name")
        $facultyGroups = @("Group Name", "Group Name", "Group Name", "Group Name", "Group Name", "Group Name")
        $adjunctGroups = @("Group Name", "Group Name", "Group Name", "Group Name", "Group Name", "Group Name")

        # Initialize the log content
        $logContent = @()

        # Get the user object
        $userObject = Get-ADUser -Filter {SamAccountName -eq $UserName}
    }

    Process {
        if ($userObject) {
            switch ($UserRole) {
                "Staff" {
                    $targetGroups = $staffGroups
                }
                "Full-Time Faculty" {
                    $targetGroups = $facultyGroups
                }
                "Adjunct" {
                    $targetGroups = $adjunctGroups
                }
            }

            $userGroups = Get-ADPrincipalGroupMembership -Identity $userObject | Select-Object -ExpandProperty Name
            $groupsToAdd = $targetGroups | Where-Object { $_ -notin $userGroups }
            
            if ($groupsToAdd.Count -gt 0) {
                foreach ($group in $groupsToAdd) {
                    Add-ADGroupMember -Identity $group -Members $userObject
                    $logEntry = "$(Get-Date) - Added $($userObject.SamAccountName) to $group"
                    $logContent += $logEntry
                    Write-Host $logEntry
                }
            } else {
                $logEntry = "$(Get-Date) - $($userObject.SamAccountName) is already a member of all relevant groups."
                $logContent += $logEntry
                Write-Host $logEntry
            }
        } else {
            $logEntry = "$(Get-Date) - User $UserName not found."
            $logContent += $logEntry
            Write-Host $logEntry
        }
    }

    End {
        # Write the log content to the log file
        $logContent | Out-File -FilePath $LogFilePath -Append
    }
}