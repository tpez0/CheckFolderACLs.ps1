 #-------------------------------------------------------------------------------------
 # Script: CheckFolderACLs.ps1
 # Author: tpez0
 # Notes : No warranty expressed or implied.
 #         Use at your own risk.
 #         Download Remote Server Administration Tools for Win10 https://www.microsoft.com/en-us/download/details.aspx?id=45520
 # Function: This tool list all permissions for a user or group on a given folder structure   
 #           Only directories are analyzed, not individual files. 
 #--------------------------------------------------------------------------------------
import-module ActiveDirectory

cls
Write-Host " "
Write-Host "*************************************************************************" -ForegroundColor Yellow
Write-Host "* Script: CheckFolderACLs.ps1                                           *" -ForegroundColor Yellow
Write-Host "* Author: tpez0                                                         *" -ForegroundColor Yellow
Write-Host "* List all permissions for a user or group on a given folder structure  *" -ForegroundColor Yellow
Write-Host "* Only directories are analyzed, not individual files.                  *" -ForegroundColor Yellow
Write-Host "*                                                                       *" -ForegroundColor Yellow
Write-Host "*************************************************************************" -ForegroundColor Yellow
Write-Host " "

$Folder = Read-Host -Prompt "Enter the path" 
$src = Read-Host -Prompt "Enter a username or group"
$c_depth = Read-Host -Prompt "Do you want to search in the subfolders? [y/N] "
if ($c_depth -eq "y"){
    Write-Host "Warning: a high number cause a long output" -ForegroundColor Red
    $depth = Read-Host -Prompt "How many levels do you want to scan? [0-100] "
} else {
    $depth = 0;
}
    
cls


# if $srcUser is a AD User (if user exists)
if (Get-ADUser -Filter "sAMAccountName -eq '$src'") {
    $srcUser = $src

    Write-Host " "
    Write-Host "*************************************************************************" -ForegroundColor Yellow
    Write-Host "* Script: CheckFolderACLs.ps1                                           *" -ForegroundColor Yellow
    Write-Host "* Author: tpez0                                                         *" -ForegroundColor Yellow
    Write-Host "* List all permissions for a user or group on a given folder structure  *" -ForegroundColor Yellow
    Write-Host "* Only directories are analyzed, not individual files.                  *" -ForegroundColor Yellow
    Write-Host "*                                                                       *" -ForegroundColor Yellow
    Write-Host "* Path: $Folder" -ForegroundColor Yellow
    Write-host "* AD User: $srcUser" -ForegroundColor Yellow
    Write-host "* Subfolder depth: $depth" -ForegroundColor Yellow
    Write-Host "*                                                                       *" -ForegroundColor Yellow
    Write-Host "*************************************************************************" -ForegroundColor Yellow
    Write-Host " "
    $Username = $env:userdomain + '\' + $srcUser
    if ($Username -match '.v[1-8]') { 
    $Username = $Username -replace '.{3}$' 
    }
    $FoldersArray = Get-ChildItem $Folder -Directory -Depth $depth
    $Path = $Folder
    #$Path

    for ($i = 0; $i -lt $FoldersArray.length; $i++){
        $Path = $FoldersArray.GetValue($i).FullName
        $ACLsArray = Get-ACL $Path | Select -ExpandProperty Access
        for($j = 0; $j -lt $ACLsArray.length; $j++){
            if($ACLsArray.GetValue($j).IdentityReference -contains $Username) {
                $Path
            }

            $groupextended = $ACLsArray.GetValue($j).IdentityReference.Value.split('\')[1]
            $groups = $ACLsArray.GetValue($j).IdentityReference.Value.split('\')[1]
            foreach ($group in $groups) {

                # if $group is a AD User (if user exists)
                if (Get-ADUser -Filter "sAMAccountName -eq '$group'") {
                    if($ACLsArray.GetValue($j).IdentityReference -contains $groupextended) {
                        $Path
                    }
                } else {
                    $members = Get-ADGroupMember -Identity $group -Recursive | Select -ExpandProperty SamAccountName
                    If ($members -contains $srcUser) {
                        $Path
                    }         
                }
            }
        } 
    }
    Write-Host " "
} else {
    # if $srcUser is a AD Group (if group exists)
    if (Get-ADGroup -Filter "sAMAccountName -eq '$src'") {
        $srcGroup = $env:userdomain + '\' + $src

        Write-Host " "
        Write-Host "*************************************************************************" -ForegroundColor Yellow
        Write-Host "* Script: CheckFolderACLs.ps1                                           *" -ForegroundColor Yellow
        Write-Host "* Author: tpez0                                                         *" -ForegroundColor Yellow
        Write-Host "* List all permissions for a user or group on a given folder structure  *" -ForegroundColor Yellow
        Write-Host "* Only directories are analyzed, not individual files.                  *" -ForegroundColor Yellow
        Write-Host "*                                                                       *" -ForegroundColor Yellow
        Write-Host "* Path: $Folder" -ForegroundColor Yellow
        Write-host "* AD Group: $srcGroup" -ForegroundColor Yellow
        Write-host "* Subfolder depth: $depth" -ForegroundColor Yellow
        Write-Host "*                                                                       *"
        Write-Host "*************************************************************************" -ForegroundColor Yellow
        Write-Host " "

        $FoldersArray = Get-ChildItem $Folder -Directory -Depth $depth
        $Path = $Folder
    
        for ($i = 0; $i -lt $FoldersArray.length; $i++){
            $Path = $FoldersArray.GetValue($i).FullName
            $ACLsArray = Get-ACL $Path | Select -ExpandProperty Access
            for($j = 0; $j -lt $ACLsArray.length; $j++){
                if($ACLsArray.GetValue($j).IdentityReference -contains $srcGroup) {
                    $Path
                }
            } 
    
        }
        Write-Host " "
    } else {
        Write-host "`n$src was not found in your AD, sorry" -ForegroundColor Red
        Write-Host " "
    } 



}
