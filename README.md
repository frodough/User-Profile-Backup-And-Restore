# User Profile Backup And Restore
Powershell script to backup and restore a user profile to and from a specified location. Script uses a dynamically generated menu to choose the profile and specified drive to backup/restore.

#### What does the script backup and restore:

1. All user data as long as the folder is not empty (Desktop, Documents, Downloads, Favorites, Pictures)
2. Browser data from Google Chrome, Edge, and Firefox

Code snippet:

```PowerShell
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
```

#### Why did I create this?:

Backing up my data manually was starting to be a pain, so why not just have the computer do it all for me?

#### How to use:

Simply follow the menu choices to choose a user profile and drive to save to. If using this in a domain environment and want to save to a non mapped drive share, simply select the drive not listed option and enter the full path. When prompted for a destination folder just enter the folder you want to save the backup to. If the folder does not exist, the script will ask if you would like to create it.
