$ErrorActionPreference = "Stop"
$DistroName = "Ubuntu-20.04"
$DistroExe = "Ubuntu2004.exe"
$MinWindows10BuildWithWsl2 = 19041
$DistroUri = "https://aka.ms/wslubuntu2004"

function Initialize-WslDistrobution() {
    Check-WindowsVersion
    Check-WslInstalled
    Ensure-DistroInstalled

    Write-Host "Making this distro default"
    wsl --set-default $DistroName
    wsl --set-default-version 2

    Write-Host "WSL username: $(&$DistroExe run 'echo $USER')"
}
function Invoke-WslSetup() {
    Write-Host "Setting the working directory to the location of this script..."
    Push-Location -Path $PSScriptRoot

    $linuxScriptPath = "./setup-ubuntu-wsl2.sh"
    Write-Host "Executing script: $linuxScriptPath"
    &$DistroExe run "$linuxScriptPath '$env:username'"    
    
    Write-Host "Going back to whatever working directory we had been in..."
    Pop-Location
}

function Check-WindowsVersion() {
    $windowsVersion = [System.Environment]::OSVersion.Version
    if (($windowsVersion.Major -ne 10) -or ($windowsVersion.Build -lt $MinWindows10BuildWithWsl2)) {
        throw "This script requires Windows 10 update 2004 (build 19041) or later"
    }
}
function Check-WslInstalled() {
    $wslInstalled=$(where.exe wsl)
    if (!$wslInstalled) {
        Write-Error -Message "WSL is not enabled. You must first run the following command in an Administrator PowerShell session (then reboot): 'Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux'"
    }
}

function Ensure-DistroInstalled() {
    $distroInstalled=$(where.exe $DistroExe)
    if (!$distroInstalled) {

        Write-Host "Downloading distro package. This may take a few minutes..."

        # Changing '$ProgressPreference' will drasticly increase the file download speed.
        $DefaultPref = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'

        $DistroPath = (Join-Path -Path $env:TEMP -ChildPath "$DistroName.appx")
        [System.Net.WebClient]::new().DownloadFile($DistroUri, $DistroPath)
        $ProgressPreference = $DefaultPref

        # FYI: this only installs Ubuntu on your user
        Add-AppxPackage -Path $DistroPath

        # Can't call wsl until you initialize the distro setup and define username and password
        &$DistroExe run pwd
    }
}

#Get WSL subsystem ready to be run
$Start=Get-Date
Initialize-WslDistrobution
Invoke-WslSetup
$End=Get-Date
Write-Host "Total time: $(($End-$Start).TotalMinutes) minutes"