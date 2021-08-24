<#
        .SYNOPSIS
        Restricts Staff/Student access to Google accounts when AD account is expired by randomizing the account password in Google using GAM.

        .DESCRIPTION
        Iterates through Active Directory for Staff and Student OU's to locate accounts with expired passwords then calls your installation of GAM (https://github.com/jay0lee/GAM) to set a randomized password on the matching Google account.
        Accounts with mangled passwords are tracked in AD using extensionAttribute2 by adding or removing the text "GSUITE_DISABLE;".

        .INPUTS
        None. You cannot pipe objects to Mangle_GooglePW_ForADExpired.

        .OUTPUTS
        Outputs to $LogFile (adjust this variable in code)
        Outputs staff/students adjusted to screen

        .LINK
        Online version: https://github.com/blowrancebenton/Mangle_GooglePW_ForADExpired

        .LICENSE
        License: http://www.apache.org/licenses/LICENSE-2.0
        Unless required by applicable law or agreed to in writing,
        software distributed under the License is distributed on an
        "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
        KIND, either express or implied.  See the License for the
        specific language governing permissions and limitations
        under the License.

        .NOTES
        Author: Brian S. Lowrance
        Contributors: 
        Version: 2.0
        Latest Change Date: 8/24/2021
        Latest Change By: Brian Lowrance
        Purpose/Change: Generalize for release
#>

$ScriptVersion = "2.0"

#################################################################
### CONFIGURATION BEGIN
$LogFile = "C:\Scripts\Mangle_GooglePW_ForADExpired.log" #Path to where you want the log file saved, including filename
$GAMEXE = "C:\Gam\Gam.exe" #Path to your GAM executable (GAM must be configured and working)
$StaffOURoot = "OU=Staff,dc=School,dc=Local"  #LDAP OU Path to the base of your staff accounts
$StaffEmailDomain = "@staff.mydomain.org"  #Email domain for your staff accounts
$StudentOURoot = "OU=Students,dc=School,dc=Local" #LDAP OU Path to the base of your student accounts
$StudentEmailDomain = "@students.mydomain.org" #Email domain for your student accounts
$PasswordLength = 8 #Length of the randomized password to set on the Google account. Note, the password is not recorded.
### CONFIGURATION END
#################################################################

#################################################################
### Mode Switches END
$ProcessStaffExp = $True  #Process Staff Expirations
$ProcessStaffRep = $True  #Process Staff Repairs
$ProcessStudentExp = $True  #Process Student Expirations
$ProcessStudentRep = $True  #Process Student Repairs
### Mode Switches END
#################################################################

filter timestamp {"$(Get-Date -Format G),$_"}
$OutputLog = $LogFile

#################################################################
#  FUNCTION JUNCTION BEGIN
#################################################################
Function random-password ($length = $PasswordLength)
{
        $punc = 46..46
        $digits = 48..57
        $lcaseletters = 97..122
        $ucaseletters = 65..90
 
        # Thanks to
        # https://blogs.technet.com/b/heyscriptingguy/archive/2012/01/07/use-pow
		##-input ($punc + $digits + $letters) |
        $password = get-random -count $length `
				-input ($digits + $lcaseletters + $ucaseletters) | 
                        % -begin { $aa = $null } `
                        -process {$aa += [char]$_} `
                        -end {$aa}
 
        return $password
}

Function Write-Log ($logdata){
    Write-Output "$($ScriptVersion),$($logdata)" | timestamp | out-file $outputlog -append -encoding ascii
}

#################################################################
#  FUNCTION JUNCTION END
#################################################################



#################################################################
#  Process Staff Accounts
#################################################################
if ($ProcessStaffExp) {
    $ExpiredStaffUsers = Get-ADUser -SearchBase $StaffOURoot -filter * -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, mail, extensionAttribute2, samAccountName | where {$_.Enabled -eq "True" -and $_.mail -like "*$($StaffEmailDomain)" -and $_.PasswordNeverExpires -eq $False -and $_.passwordexpired -eq $True -and $_.extensionAttribute2 -notlike "*GSUITE_DISABLE*"}
    $StaffUserList = @()
    ForEach($StaffUser in $ExpiredStaffUsers){
        $StaffUserList += $StaffUser #Not currently used
        Try {
            & "$GamEXE" update user $($StaffUser.Mail) password $(random-password)
            Set-ADUser $StaffUser -Add @{extensionAttribute2="$($StaffUser.extensionAttribute2)GSUITE_DISABLE;"}
            Write-Host "Processed STAFF: $($StaffUser.Name)"
            Write-Log "SUCCESS,STAFF,MANGLE,$($StaffUser.Name),$($StaffUser.samAccountName)"
        } Catch {
            Write-Host "An error occurred processing password mangle for $($StaffUser.Name)" -ForegroundColor Red
            Write-Log "FAIL,STAFF,MANGLE,$($StaffUser.Name),$($StaffUser.samAccountName)"
        }
    }
}

if ($ProcessStaffRep) {
    $RepairedStaffUsers = Get-ADUser -SearchBase $StaffOURoot -filter * -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, mail, extensionAttribute2,samAccountName | where {$_.Enabled -eq "True" -and $_.mail -like "*$($StaffEmailDomain)" -and $_.PasswordNeverExpires -eq $False -and $_.passwordexpired -eq $False -and $_.extensionAttribute2 -like "*GSUITE_DISABLE*"}
    $RepairedStaffList = @()
    ForEach($StaffUser in $RepairedStaffUsers){
        $RepairedStaffUserList += $StaffUser #Not currently used
        $ExtAttribute2 = ""
        $ExtAttribute2 = $StaffUser.extensionAttribute2
        $ExtAttribute2 = $ExtAttribute2.Replace("GSUITE_DISABLE;", "")
        if ($ExtAttribute2.length -gt 0) {
            Set-ADUser $StaffUser -Replace @{extensionAttribute2=$ExtAttribute2}
        } else {
            Set-ADUser $StaffUser -Clear extensionAttribute2 -ErrorAction SilentlyContinue
        }
        Set-ADUser $StaffUser -Replace @{extensionAttribute2=$ExtAttribute2}
        Write-Host "Repair STAFF: $($StaffUser.Name)"
        Write-Log "SUCCESS,STAFF,REPAIR,$($StaffUser.Name),$($StaffUser.samAccountName)"
    }
}

#################################################################
#  Process Student Accounts
#################################################################
if ($ProcessStudentExp) {
    $ExpiredStudentUsers = Get-ADUser -SearchBase $StudentOURoot -filter * -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, mail, extensionAttribute2, samAccountName | where {$_.Enabled -eq "True" -and $_.mail -like "*$($StudentEmailDomain)" -and $_.PasswordNeverExpires -eq $False -and $_.passwordexpired -eq $True -and $_.extensionAttribute2 -notlike "*GSUITE_DISABLE*"}
    $StudentUserList = @()
    ForEach($StudentUser in $ExpiredStudentUsers){
        $StudentUserList += $StudentUser #Not currently used
        Try {
            & "$GamEXE" update user $($StudentUser.Mail) password $(random-password)
            Set-ADUser $StudentUser -Add @{extensionAttribute2="$($StudentUser.extensionAttribute2)GSUITE_DISABLE;"}
            Write-Host "Processed STUDENT: $($StudentUser.Name)"
            Write-Log "SUCCESS,STUDENT,MANGLE,$($StudentUser.Name),$($StudentUser.samAccountName)"
        } Catch {
            Write-Host "An error occurred processing password mangle for STUDENT: $($StudentUser.Name)" -ForegroundColor Red
            Write-Log "FAIL,STUDENT,MANGLE,$($StudentUser.Name),$($StudentUser.samAccountName)"
        }
    }
}

if ($ProcessStudentRep) {
    $RepairedStudentUsers = Get-ADUser -SearchBase $StudentOURoot -filter * -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, mail, extensionAttribute2,samAccountName | where {$_.Enabled -eq "True" -and $_.mail -like "*$($StudentEmailDomain)" -and $_.PasswordNeverExpires -eq $False -and $_.passwordexpired -eq $False -and $_.extensionAttribute2 -like "*GSUITE_DISABLE*"}
    $RepairedStudentList = @()
    ForEach($StudentUser in $RepairedStudentUsers){
        $RepairedStudentUserList += $StudentUser #Not currently used
        $ExtAttribute2 = ""
        $ExtAttribute2 = $StudentUser.extensionAttribute2
        $ExtAttribute2 = $ExtAttribute2.Replace("GSUITE_DISABLE;", "")
        if ($ExtAttribute2.length -gt 0) {
            Set-ADUser $StudentUser -Replace @{extensionAttribute2=$ExtAttribute2}
        } else {
            Set-ADUser $StudentUser -Clear extensionAttribute2 -ErrorAction SilentlyContinue
        }
        Write-Host "Repair STUDENT: $($StudentUser.Name)"
        Write-Log "SUCCESS,STUDENT,REPAIR,$($StudentUser.Name),$($StudentUser.samAccountName)"
    }
}
