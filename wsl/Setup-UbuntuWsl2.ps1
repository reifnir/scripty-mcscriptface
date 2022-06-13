$ErrorActionPreference = "Stop"
$DistroName = "Ubuntu"
$DistroExe = "ubuntu.exe"
$DistroUri = "https://aka.ms/wslubuntu2004"

function Initialize-WslDistrobution() {
    Check-WslInstalled
    Ensure-DistroInstalled

    Write-Host "Making this distro default"
    wsl --set-default $DistroName
    wsl --set-default-version 2

    Write-Host "WSL username: $(&$DistroExe run 'echo $USER')"
}
function Invoke-WslSetup() {
    Write-Host "Invoke-WslSetup: Starting..."
    Write-Host "Setting the working directory to the location of this script..."
    Push-Location -Path $PSScriptRoot
    $linuxCommand = "./setup-ubuntu-wsl2.sh '$env:username'"
    Write-Host "Executing script: $linuxCommand"
    &$DistroExe run "$linuxCommand"
    
    Write-Host "Going back to whatever working directory we had been in..."
    Pop-Location
}

function Check-WslInstalled() {
    $wslInstalled=$(where.exe wsl)
    if (!$wslInstalled) {
        Write-Error -Message "WSL is not enabled. You must first run the following command in an Administrator PowerShell session (then reboot): 'Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux'"
    }
    else {

        Write-Host "WSL is installed at $wslInstalled"
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

# #Get WSL subsystem ready to be run
$Start=Get-Date
Initialize-WslDistrobution
Invoke-WslSetup
$End=Get-Date
Write-Host "Total time: $(($End-$Start).TotalMinutes) minutes"