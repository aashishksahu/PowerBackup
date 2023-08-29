#-----------------------------------------------------------------------#
#                       P O W E R  B A C K U P                          #
#-----------------------------------------------------------------------#
# Simple shell script to backup the contents of a directory. Simply     #
# drop your files in the "[backup name]_IN" folder, run the script      #
# and get your gpg encrypted files in the "[backup name]_OUT" folder    #
#                                                                       #
# Note: File name encryption is not yet supported                       #
#-----------------------------------------------------------------------#
#                                                                       #
# Power Backup                                                          #
# Copyright (C) 2023  Aashish K Sahu                                    #
#                                                                       #
# This program is free software: you can redistribute it and/or modify  #
# it under the terms of the GNU General Public License as published by  #
# the Free Software Foundation, either version 3 of the License, or     #
# (at your option) any later version.                                   #
#                                                                       #
# This program is distributed in the hope that it will be useful,       #
# but WITHOUT ANY WARRANTY; without even the implied warranty of        #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
# GNU General Public License for more details.                          #
#                                                                       #
# You should have received a copy of the GNU General Public License     #
# along with this program.  If not, see <http://www.gnu.org/licenses/>. #
#                                                                       #
#-----------------------------------------------------------------------#

# check if input file exists
$mode    = $args[0]
$backupName = $args[1]

if([string]::IsNullOrEmpty($mode) -bor $mode -notin "E","D" ){
  throw "Please specify whether to encrypt (eg.: PowerBackup.ps1 E) or to decrypt (eg.: PowerBackup.ps1 D)"
}

if([string]::IsNullOrEmpty($backupName)){
  throw "Please specify a backup name (eg.: PowerBackup.ps1 [E|D] photosBackup)"
}

$currentLocation = Get-Location

$inDirPattern = -join($backupName, "_IN")
$outDirPattern = -join($backupName, "_OUT")

$inDir  = -join($currentLocation, "\" , $backupName, "\", $inDirPattern)
$outDir = -join($currentLocation, "\" , $backupName, "\", $outDirPattern)

# check if in and out location exist, otherwise, create them
if(!(Test-Path $inDir)){
  Write-Host "The 'in' folder does not exist, creating one. Place the files you wish to encrypt in this folder..."
  $null = New-Item -ItemType Directory -Path $inDir
}

if(!(Test-Path $outDir)){
  Write-Host "The 'out' folder does not exist, creating one. Encrypted files will show up here..."
  $null = New-Item -ItemType Directory -Path $outDir
}

$password = Read-Host "Enter Password" -AsSecureString

if($mode -EQ "E"){
  
  # fetch absolute paths of all the files
  $filesList = Get-ChildItem -Path $inDir -Recurse | %{$_.FullName}
  $filesListLen = $filesList.Length

  # loop at all the files and create foders if not exists
  For ($i=0; $i -lt $filesList.Length; $i++) {

    $outFile = $filesList[$i].replace($inDirPattern, $outDirPattern)

    if((Get-Item $filesList[$i]) -is [System.IO.DirectoryInfo]){
    
      if(!(Test-Path $outFile)){
        $null = New-Item -ItemType Directory -Path $outFile
      }

    }else{

      $outFile = -join($outFile, ".gpg")

      # Start encryption of $filesList[$i]
      gpg --no-symkey-cache --passphrase $password --output $outFile --symmetric --batch --cipher-algo AES256 $filesList[$i]    
    }

    Write-Progress -Activity "Files Encrypted" -Status "$i of $filesListLen Complete:" -PercentComplete ( ( $i / $filesListLen ) * 100 )

  }
  
}elseif ($mode -EQ "D") {
  
  # fetch absolute paths of all the files
  $filesList = Get-ChildItem -Path $outDir -Recurse | %{$_.FullName}
  $filesListLen = $filesList.Length

  # loop at all the files and create foders if not exists
  For ($i=0; $i -lt $filesList.Length; $i++){
    
    $inFile = $filesList[$i].replace($outDirPattern, $inDirPattern)
    
    if((Get-Item $filesList[$i]) -is [System.IO.DirectoryInfo]){
      
      if(!(Test-Path $inFile)){
        $null = New-Item -ItemType Directory -Path $inFile
      }
      
    }else{
      
      $inFile = $inFile.replace(".gpg", "")
      
      # Start decryption of $filesList[$i]
      gpg --no-symkey-cache --passphrase $password --output $inFile --decrypt --batch $filesList[$i]
    }
    
    Write-Progress -Activity "Files Decrypted" -Status "$i of $filesListLen Complete:" -PercentComplete ( ( $i / $filesListLen ) * 100 )

  }
  
}