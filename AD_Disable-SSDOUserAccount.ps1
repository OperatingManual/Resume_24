<#
.SYNOPSIS
Disable User Account PowerShell Script

.DESCRIPTION
This script disables a user account, disables their ability to change their password, sets a random password, removes them from all groups except domain users, moves the user object to a target OU, and hides their email from GAL. It logs the changes to the Application event log.

.PARAMETER Username
Specifies the username of the user to disable.

.EXAMPLE
Disable-UserAccount -Username "user01"

This example demonstrates how to use the script to disable the user account "user01", set a random password with a length of 30 characters, and log the changes to the Application event log.

.NOTES
Author: Tyler Tourot
Date: 6/5/2023

#>

function Disable-SSDOUserAccount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Username
    )
    $logName = "Application"
    $logSourceName = "TBD" # Must be initialized and set once. Initialization should occur during server build.
    $groups = Get-ADPrincipalGroupMembership -Identity $Username | Where-Object {$_.Name -ne "Domain Users"}
    $user = Get-ADUser -Identity $username
    $newOU = "OU=TARGETOU,DC=X,DC=X,DC=X" #OU for disabled users.

    try {
        # Begin logging
        $logEntry = "$(Get-Date -Format 'yyyy/MM/dd HH:mm:ss') - Starting to disable user account '$Username'"
        Write-EventLog -LogName $logName -Source $logSourceName -EventId 3000 -EntryType Information -Message $logEntry

        # Generate a random password
        $length = 30
        $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{};':<>,.?/\|"
        $password = ""
        for ($i = 0; $i -lt $length; $i++) {
            $password += $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)]
        }
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force

        # Disable user account
        Disable-ADAccount -Identity $Username

        # Disable ability to change password
        Set-ADUser -Identity $Username -CannotChangePassword $true

        # Set the random password
        Set-ADAccountPassword -Identity $Username -NewPassword $securePassword

        # Remove the user from all groups except for Domain Users
        foreach ($group in $groups) {
            Remove-ADGroupMember -Identity $group -Members $user -Confirm:$false
        }

        # Move the user to the new OU
        Move-ADObject -Identity $user.DistinguishedName -TargetPath $newOU

        #Hide email address from GAL
        Set-ADUser -Identity $username -Replace @{msExchHideFromAddressLists=$true}

        $logEntry = "$(Get-Date -Format 'yyyy/MM/dd HH:mm:ss') - User account '$Username' has been disabled successfully."
        Write-EventLog -LogName $logName -Source $logSourceName -EventId 3000 -EntryType Information -Message $logEntry

    }
    catch {
        $logEntry = "$(Get-Date -Format 'yyyy/MM/dd HH:mm:ss') - An error occurred while disabling the user account: $_"
        Write-EventLog -LogName $logName -Source $logSourceName -EventId 1000 -EntryType Error -Message $logEntry

        Write-Output "An error occurred while disabling the user account: $_" -ForegroundColor Red
    }
}
