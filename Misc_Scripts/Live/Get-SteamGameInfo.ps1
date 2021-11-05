<#
.SYNOPSIS
Function to output a list with Steam game info
.DESCRIPTION
This script gets a list of Steam Games and their files sizes
.EXAMPLE
Out-SteamGameList
.OUTPUTS
Outputs a CSV to current directory - .\SteamDataSheet.csv
#>

Remove-Item .\SteamDataSheet.csv -Force
Write-Host "What drive is Steam installed on? If default type C"
$letter = Read-Host Drive letter
$SteamLibpath = $letter + ":\Program Files (x86)\Steam\config\libraryfolders.vdf"

#Gets file line count with Game Library Directories
$count = (Get-Content $SteamLibpath | Measure-Object -Line).Lines 

#This do-while goes through everyline in the libraryfolders.vdf to find the paths
Set-Variable docount -Value $NULL #In case you run it multiple times manually 
do {
    $docount += 1
    #Gets file with Game Library Directories
    $1 = (Get-Content $SteamLibpath | Select-Object -Skip $docount -First 1) # This goes line by line adding 1 to docount until the count is eq to the line count
    if ($1 -like "*path*") {
        $clean = (($1).Replace('"path"', '')).Replace('\\', '\')
        $SteamLiblist += @($Clean.Trim())
    }
}while ($docount -lt $count) {
    
}




foreach ($SteamLib in $SteamLibList) {
    #This preps the paths
    $libout = $SteamLib.Replace('"', '')
    $prep = $SteamLib.TrimEnd('"') + '\steamapps\common\*'
    $path = $prep.TrimStart('"')
   
    $dirlist = Get-ChildItem $path | Sort-Object Fullname
    #This sets up the Array
    $PSOUT = @()

    if (test-path $dirlist) {
        foreach ($dir in $dirlist) {
            $PSOB = New-Object -TypeName PSObject
            #This goes through every folder and gets the byte size
            $folderinfo = get-childitem $dir.FullName -recurse | Measure-Object -Property Length -Sum
            $allfilesCount = $folderInfo.Count
            $folderSize = $folderInfo.Sum
            $folderSizeMB = [System.Math]::Round((($folderSize) / 1MB), 2) 
            $folderSizeGB = [System.Math]::Round((($folderSize) / 1GB), 2) 
            $foldername = $dir.Name
            $PSOB | Add-Member -MemberType NoteProperty -Name 'Game' -Value $foldername
            $PSOB | Add-Member -MemberType NoteProperty -Name 'Size(GB)' -Value $folderSizeGB
            $PSOB | Add-Member -MemberType NoteProperty -Name 'Size(MB)' -Value $folderSizeMB
            $PSOB | Add-Member -MemberType NoteProperty -Name 'File Count' -Value $allfilesCount
            $PSOB | Add-Member -MemberType NoteProperty -Name 'Steam Library' -Value $libout
            $PSOB
            $PSOUT = $PSOB
            #This Creates a CSV with all the information above
            $PSOUT | Export-Csv -path .\SteamDataSheet.csv -NoTypeInformation -Append   
        }
    }
}

