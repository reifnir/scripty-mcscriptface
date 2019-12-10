$ErrorActionPreference = "Stop"
$DistroName = "Debian"
$DistroExe = "$DistroName.exe"
$DistroUrl = "https://aka.ms/wsl-$DistroName-gnulinux"

function Initialize-WslDistrobution() {
    $wslInstalled=$(where.exe wsl)
    $distroInstalled=$(where.exe $DistroExe)

    if (!$wslInstalled) {
        Write-Error -Message "WSL is not enabled. You must first run the following command in an Administrator PowerShell session (then reboot): 'Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux'"
    }
    
    if (!$distroInstalled) {
        # We're going to download the image outside of the MS store because it's blocked in some places

        Write-Host "Downloading distro package. This may take a few minutes..."
        Invoke-WebRequest -Uri $DistroUrl -OutFile $env:temp\distro.appx -UseBasicParsing

        Write-Host "Adding appx package for distro"
        Add-AppxPackage $env:temp\distro.appx

    }
    if (!$distroInitialized) {
        # Can't call wsl until you initialize the distro setup and define username and password
        &$DistroExe run pwd
    }

    #Write-Host "Making this distro default"
    #wsl --setdefault $DistroName

    Write-Host "WSL username: $(&$DistroExe run 'echo $USER')"
}
function Invoke-WslSetup() {
    &$DistroExe run "./setup-debian-wsl1.sh '$env:username'"    
}
function Install_AllTheThings() {
    $Started=Get-Date
    #Set the working directory to the location of this script
    Push-Location -Path $PSScriptRoot

    #Get WSL subsystem ready to be run
    Initialize-WslDistrobution
    Invoke-WslSetup
    #Go back to whatever working directory we had been in
    Pop-Location
    $Finished=Get-Date
    Write-Host $($Finished - $Started)
}

Install_AllTheThings