﻿$ErrorActionPreference = 'Stop'; # stop on all errors
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

# polyfill
if (! (Get-Command -Name New-TemporaryFile -ErrorAction SilentlyContinue))
{
    function New-TemporaryFile
    {
        foreach ($i in 1..10)
        {
            $name = [Guid]::NewGuid()
            $tempPath = Join-Path -Path $env:TEMP -ChildPath $name
            if (! (Test-Path -Path $tempPath -ErrorAction SilentlyContinue))
            {
                return $tempPath
            }
        }
        throw 'cannot create temporary path'
    }
}

# check Java 64-bit
$tempFile = New-TemporaryFile
cmd /c "java -version 2> $tempFile"
if (! (Select-String -Path $tempFile -Pattern 64-Bit))
{
    Remove-Item -Path $tempFile
    throw 'require 64-bit Java'
}
Remove-Item -Path $tempFile

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url           = "https://github.com/skylot/jadx/releases/download/v$env:ChocolateyPackageVersion/jadx-$env:ChocolateyPackageVersion.zip"
  checksum      = '1f0431273ad9e56a40fb31ad6c355ccb1da5be74887d8d9fb17995bd7cb06285'
  checksumType  = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs

$binPath = Join-Path -Path $toolsDir -ChildPath bin
$jadx = Join-Path -Path $binPath -ChildPath jadx.bat
$jadxGui = Join-Path -Path $binPath -ChildPath jadx-gui.bat
Install-BinFile -Name jadx -Path $jadx
Install-BinFile -Name jadx-gui -Path $jadxGui

if (Test-ProcessAdminRights)
{
    $specialFolder = [Environment+SpecialFolder]::CommonPrograms
}
else
{
    $specialFolder = [Environment+SpecialFolder]::Programs
}
$linkPath = [Environment]::GetFolderPath($specialFolder) | Join-Path -ChildPath 'JADX GUI.lnk'
Install-ChocolateyShortcut -ShortcutFilePath $linkPath -TargetPath $jadxGui
