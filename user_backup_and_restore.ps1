    ## Define function to show menu
    function Menu {
        cls
        
        $script:title = "User Profile Backup/Restore"

        write-host "================ $title ================`n" -fore cyan
        write-host "Make a selection:"
        write-host "1: Backup user profile"
        write-host "2: Restore user profile"

        [int]$MSelection = read-host "`nMake a selection"

        ## Loop through selection and validate choice
        while ($MSelection -gt 2 -or $MSelection -lt 1 -or $MSelection -notmatch '^\d+$') {
            write-host "Please enter a valid selction"
            [int]$MSelection = read-host "`nMake a selection"
        }

        switch ($MSelection) {
            1 { $script:Backup = $true; ProfileBackup }
            2 { $script:Backup = $false; ProfileRestore }
        }
    }

    ## Define function to grab all profiles in profile directory
    function GetUser {
        cls
        
        ## Grab all profiles in profile directory
        $Users = (gci "$env:homedrive\Users") | ? {$_.Name -ne "Public"}
        $Users = @($Users.name)

        write-host "================ $title ================`n" -fore cyan
        if ($Backup -eq $true) {
            write-host "Select a user to backup:"
        } else {
            write-host "Select a user to restore:"
        }
        
        ## Build dynamic menu and populate it with profiles to select
        for ($i = 0; $i -lt $Users.Count; $i++) {
            Write-Host "$($i + 1): $($Users[$i])"
        }
        
        [int]$USel = read-host "`nMake a selection"
        
        ## Loop through selection and validate choice
        while ($USel -gt $Users.count -or $USel -lt 1 -or $USel -notmatch '^\d+$') {
            write-host "Please enter a valid selction"
            [int]$USel = read-host "`nMake a selection"
        }
        
        $PIndex = $USel - 1
        $script:UserBackup = $($Users[$PIndex])
    }

    ## Define funciton to get all listed drives
    function GetDrives {
        cls
        
        ## Grab all connected drives
        $Drives = @(Get-PSDrive | ? {$_.Provider -match "FileSystem"} | % {$_.Root})

        write-host "================ $title ================`n" -fore cyan
        if ($Backup -eq $true) {
            write-host "Select a destination drive:"
        } else {
            write-host "Select location of backup:"
        }
        
        ## Build dynamic menu and populate it with drives to select
        for ($i = 0; $i -lt $Drives.Count; $i++) {
            Write-Host "$($i + 1): $($Drives[$i])"
        }
        
        write-host "$($i + 1): Drive not listed"
        [int]$DriveSel = read-host "`nMake a selection"
        
        ## Loop through selection and validate choice
        while ($Drivesel -gt ($Drives.count + 1) -or $Drivesel -lt 1 -or $Drivesel -notmatch '^\d+$') {
            write-host "Please enter a valid selction"
            [int]$Drivesel = read-host "`nMake a selection"
        }
        
        ## Add option to menu to manually insert destination locaiton
        if ($Drivesel -eq ($Drives.count + 1)) {
            $script:Destination = read-host "Manually enter location"
        } else {
            $DIndex = $Drivesel - 1
            $script:DriveLetter = $($Drives[$DIndex])

            if ($Backup -eq $true){
                [string]$DesSel = read-host "`nEnter a destination folder"
            } else {
                [string]$DesSel = read-host "`nEnter the folder name where backup is saved"
            }

            $script:Destination = Join-Path -Path $DriveLetter -ChildPath $DesSel
        }
    }

    ## Copy files and show progress
    function CopyFile {
        param (
            [parameter(mandatory=$true)]
            [string]
            $Source,
            [parameter(mandatory=$true)]
            [string]
            $Destination
        )
        
        $FileList = gci "$Source" -Recurse
        $Total = $Filelist.count
        $Position = 1
        
        foreach ($file in $filelist) {
            $FileName = $file.fullname.replace($Source, '')
            $DestinationFile = ($Destination+$FileName)
            $Progress = [math]::Round(($Position/$Total)*100) 
            
            write-progress -activity "Copying file from $($Source) to $($Destination)" -status "Copying file $($FileName)" -percentcomplete $Progress
            copy-item -literalpath $File.fullname -Destination $DestinationFile -erroraction silentlycontinue
            $Position++	
        }
    }

    ## Define function for profile backup
    function ProfileBackup {
        
        ## Call functions to define variables
        GetUser
        GetDrives
        
        cls
        write-host "================ $title ================`n" -fore cyan

        ## Present final selection and make user confirm choices
        Sleep -seconds 1
        write-host "The user being backed up is $($UserBackup)"
        Sleep -seconds 1
        write-host "The drive selected is $($Destination)`n"
        
        ## Loop through selection and validate choice
        do {
            $Choice = read-host "Is this correct? [y/n]"
        }
        
        until ("y","n","yes","no" -contains $Choice)
        
        ## If selection is confirmed start backup
        if ("y","yes" -contains $Choice) {
            write-host "`nChecking for $($Destination)"
            $DesValidate = test-path $($Destination)
            
            ## If destination is not found confirm with user
            if (!($DesValidate)) {
                write-host "Destination folder $($Destination) cannot be found!"

                ## Loop through selection and validate choice
                do {
                    $MakeDest = read-host "Create destination $($Destination)? [y/n]"
                }
                
                until ("y","n","yes","no" -contains $MakeDest)
                
                ## Make directory if user confirms else exit
                if ("y","yes" -contains $MakeDest) {
                    write-host "Creating destination folder $($Destination)"
                    new-item -Path $($Destination) -ItemType Directory | Out-Null
                } else {
                    write-host "Exiting script"
                    exit
                }
            }

            write-host "`nProceeding with backup for user: $($UserBackup)"
            
            ## Define locations to be backed up
            $Folders = @("Desktop",
                        "Downloads",
                        "Documents",
                        "Favorites",
                        "Pictures",
                        "AppData\Local\Google\Chrome\User Data\Default",
                        "AppData\Local\Microsoft\Edge\User Data\Default"
                        "AppData\Local\Mozilla\Firefox\Profiles",
                        "AppData\Roaming\Mozilla\Firefox")
            
            ## Loop through folders and skip folders not validated
            foreach ($Folder in $Folders) {
                $Valid = test-path $("$env:homedrive\Users\$UserBackup\$Folder")

                if ($valid) {
                    write-host "`nFolder $($Folder) detected"
                    Sleep -seconds 1
                    
                    ## Get folder size
                    $Total = (gci -Recurse -Path $("$env:homedrive\Users\$UserBackup\$Folder") | 
                            Measure-Object -Property Length -Sum).Sum /1MB
                    $TotalSize = [math]::round($total)

                    write-host "Total size $TotalSize MB"
                    write-host "Backing up $("$env:homedrive\Users\$UserBackup\$Folder")"
                    
                    ## Try to copy files, if error occurs stop processing and display error
                    try {
                        CopyFile -Source $("$env:homedrive\Users\$UserBackup\$Folder") -Destination "$($Destination)\$($UserBackup)\$Folder"
                                    
                        write-host "Successfully backed up " -NoNewline -fore green
                        write-host $("$env:homedrive\Users\$UserBackup\$Folder") -fore green
                    }
                    catch {
                        write-host "Error backing up $($Folder)" -fore red
                        write-host $($_.Exception.Message) -fore red
                    }
                }
            }
            write-host "`nBackup complete"
        }
        
        ## If selections were not correct reloop through function to start again
        if ("n","no" -contains $Choice) {
            ProfileBackup
        }
    }

    function ProfileRestore {
        
        ## Call functions to define variables
        GetUser
        GetDrives
        
        cls
        write-host "================ $title ================`n" -fore cyan

        ## Present final selection and make user confirm choices
        Sleep -seconds 1
        write-host "The user being restored is $($UserBackup)"
        Sleep -seconds 1
        write-host "The restore location is $($Destination)`n"
        
        ## Loop through selection and validate choice
        do {
            $Choice = read-host "Is this correct? [y/n]"
        }
        
        until ("y","n","yes","no" -contains $Choice)
        
        ## If selection is confirmed start backup
        if ("y","yes" -contains $Choice) {
            write-host "`nChecking for $($Destination)"
            $DesValidate = test-path $($Destination)
            
            ## If destination is not found confirm with user
            if (!($DesValidate)) {
                write-host "Destination folder $($Destination) cannot be found!"

                ## Loop through selection and validate choice
                do {
                    $Dest = read-host "Enter a valid restore location"
                    $DesValidate = test-path $($Dest)
                }
                
                until ($DesValidate)
            } else {
                Sleep -Seconds 1
                write-host "Restore location found"
            }

            ## Check to see if backup exists
            $Backup = gci $Destination

            if (!($Backup -like "$UserBackup*")) {
                write-host "No backup found for profile $($UserBackup) exiting script"
                exit
            }

            ## Check to see if profile was already restored
            if ($Backup -like "$UserBackup.restored") {
                write-host "Profile $($UserBackup) has already been restored exiting script"
                exit
            }

            write-host "`nProceeding with restore for user: $($UserBackup)"
            
            ## Define locations to be restored
            $Folders = @("Desktop",
                        "Downloads",
                        "Documents",
                        "Favorites",
                        "Pictures",
                        "AppData\Local\Google\Chrome\User Data\Default",
                        "AppData\Local\Microsoft\Edge\User Data\Default"
                        "AppData\Local\Mozilla\Firefox\Profiles",
                        "AppData\Roaming\Mozilla\Firefox")
            
            ## Loop through folders and skip folders not validated
            foreach ($Folder in $Folders) {
                $Valid = test-path $("$Destination\$UserBackup\$Folder")

                if ($valid) {
                    write-host "`nFolder $($Folder) detected"
                    Sleep -seconds 1
                    
                    ## Get folder size
                    $Total = (gci -Recurse -Path $("$env:homedrive\Users\$UserBackup\$Folder") | 
                            Measure-Object -Property Length -Sum).Sum /1MB
                    $TotalSize = [math]::round($total)

                    write-host "Total size $TotalSize MB"
                    write-host "Restoring folder $("$env:homedrive\Users\$UserBackup\$Folder")"
                    
                    ## Try to copy files, if error occurs stop processing and display error
                    try {
                        CopyFile -Source "$($Destination)\$($UserBackup)\$Folder" -Destination $("$env:homedrive\Users\$UserBackup\$Folder") 
                                    
                        write-host "Successfully restored " -NoNewline -fore green
                        write-host $("$env:homedrive\Users\$UserBackup\$Folder") -fore green
                    }
                    catch {
                        write-host "Error restoring $($Folder)" -fore red
                        write-host $($_.Exception.Message) -fore red
                    }
                }
            }
            $Rename = read-host "`nRename backup folder to restored? [y/n]"

            if ("y","yes" -contains $Rename) {
                rename-item "$($Destination)\$($UserBackup)" "$($Destination)\$($UserBackup).restored" 
            }

            write-host "`nRestore complete"
        }
        
        ## If selections were not correct reloop through function to start again
        if ("n","no" -contains $Choice) {
            ProfileRestore
        }
    }

    ## Start function
    Menu
