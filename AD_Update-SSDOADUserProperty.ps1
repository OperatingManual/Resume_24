<#
.SYNOPSIS
Updates the properties of an Active Directory user account with a new SAM account name, moves the user to a new OU based on their role, and logs the changes to a log file.

.DESCRIPTION
This function updates the SAM account name, display name, given name, surname, user principal name (UPN), and OU of an Active Directory user account. The user is moved to a different OU based on their role (staff, full-time faculty, or adjunct), and the changes are logged to a specified log file.

.PARAMETER NewSamAccountName
Specifies the new SAM account name for the user.

.PARAMETER OldSamAccountName
Specifies the old SAM account name of the user. If the old sAMAccountName is unknown, use the new sAMAccountName for this parameter.

.PARAMETER FirstName
Specifies the first name of the user.

.PARAMETER LastName
Specifies the last name of the user.

.PARAMETER UPNSuffix
Specifies the UPN suffix to be added to the SAM account name.

.PARAMETER UserRole
Specifies the role of the user. Allowed values are "Student", "Staff", "Full-Time Faculty", or "Adjunct".

.PARAMETER LogFilePath
Specifies the path to the log file. Default is "c:\temp\user_update_log.txt".

.EXAMPLE
Update-SSDOADUserProperty -NewSamAccountName "newusername" -OldSamAccountName "oldusername" -FirstName "John" -LastName "Doe" -UPNSuffix "@domain.com" -UserRole "Staff" -TargetOU "OU=NewStaffOU,DC=example,DC=com"

This example updates the SAM account name, display name, given name, surname, UPN, and OU of the "oldusername" user account to "newusername", moves the user to the specified OU based on the "Staff" role, and logs the changes to a log file.

.NOTES
Author: Tyler Tourot
Date: 05/10/2023
#>
function Update-SSDODUserProperty {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$NewSamAccountName,

        [Parameter(Mandatory = $true)]
        [string]$OldSamAccountName,

        [Parameter(Mandatory = $true)]
        [string]$FirstName,

        [Parameter(Mandatory = $true)]
        [string]$LastName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("@DOMAIN.edu", "@student.DOMAIN.edu")]
        [string]$UPNSuffix,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Staff", "Full-Time Faculty", "Adjunct")]
        [string]$UserRole,

        [Parameter()]
        [string]$LogFilePath = "c:\temp\log.txt"
    )

    $NewUPN = $NewSamAccountName + $UPNSuffix
    $DisplayName = $FirstName + " " + $LastName

    $logContent = @()

    try {
        # Update the user properties
        $UserProperties = @{
            EmailAddress = $NewUPN
            UserPrincipalName = $NewUPN
            Surname = $LastName
            DisplayName = $DisplayName
            GivenName = $FirstName
            Verbose = $true
        }

        $userObject = Get-ADUser -Identity $NewSamAccountName
        Set-ADUser -Identity $NewSamAccountName @UserProperties

        # Log the old and new UPNs
        $LogEntry = "$(Get-Date -Format 'yyyy/MM/dd HH:mm:ss') - Updated $OldSamAccountName with new properties $($UserProperties | Out-String)"
        $logContent += $LogEntry

        # Move the user to the target OU based on their role
        if ($userObject) {
            switch ($UserRole) {
                "Student" {
                    Move-ADObject -Identity $userObject.DistinguishedName -TargetPath "OU=UNDEFINED,DC=UNDEFINED,DC=UNDEFINED,DC=UNDEFINED"
                    Get-ADUser -Identity $NewSamAccountName
                    $LogEntry = "$(Get-Date -Format 'yyyy/MM/dd HH:mm:ss') - Moving $NewSamAccountName to OU=UNDEFINED,DC=UNDEFINED,DC=UNDEFINED,DC=UNDEFINED"
                    $logContent += $LogEntry
                }
                "Staff" {
                    Move-ADObject -Identity $userObject.DistinguishedName -TargetPath "OU=UNDEFINED,DC=UNDEFINED,DC=UNDEFINED,DC=UNDEFINED"
                    Get-ADUser -Identity $NewSamAccountName
                    $LogEntry = "$(Get-Date -Format 'yyyy/MM/dd HH:mm:ss') - Moving $NewSamAccountName to OU=UNDEFINED,DC=UNDEFINED,DC=UNDEFINED,DC=UNDEFINED"
                    $logContent += $LogEntry
                }
                "Full-Time Faculty" {
                    Move-ADObject -Identity $userObject.DistinguishedName -TargetPath "OU=UNDEFINED,DC=UNDEFINED,DC=UNDEFINED,DC=UNDEFINED"
                    Get-ADUser -Identity $NewSamAccountName                    
                    $LogEntry = "$(Get-Date -Format 'yyyy/MM/dd HH:mm:ss') - Moving $NewSamAccountName to OU=UNDEFINED,DC=UNDEFINED,DC=UNDEFINED,DC=UNDEFINED"
                    $logContent += $LogEntry
                }
                "Adjunct" {
                    Move-ADObject -Identity $userObject.DistinguishedName -TargetPath "OU=UNDEFINED,DC=UNDEFINED,DC=UNDEFINED,DC=UNDEFINED"
                    Get-ADUser -Identity $NewSamAccountName
                    $LogEntry = "$(Get-Date -Format 'yyyy/MM/dd HH:mm:ss') - Moving $NewSamAccountName to OU=UNDEFINED,DC=UNDEFINED,DC=UNDEFINED,DC=UNDEFINED"
                    $logContent += $LogEntry
                }
            }
        } else {
            $LogEntry = "$(Get-Date -Format 'yyyy/MM/dd HH:mm:ss') - User $NewSamAccountName not found."
            $logContent += $LogEntry
        }
    }
    catch {
        $LogEntry = "$(Get-Date -Format 'yyyy/MM/dd HH:mm:ss') - Error updating user properties: $_"
        $logContent += $LogEntry
        throw
    }
    finally {
        # Write log content to the log file
        $logContent | Out-File -FilePath $LogFilePath -Append
    }
}
