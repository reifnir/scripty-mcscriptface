$ErrorActionPreference = "Stop"
$DistroName = "Ubuntu"
$DistroExe = "Ubuntu.exe"
$MinWindows10BuildWithWsl2 = 19041

# =====================================================================================================
# Acquired via this method: https://github.com/MicrosoftDocs/WSL/issues/645#issuecomment-629928951
# =====================================================================================================
# Inspect Get button in this page.
# https://www.microsoft.com/en-us/p/ubuntu/9nblggh4msv6
# Focus on data-m attribute and copy pid.
# {"cN":"AppIdentityBuyButton","pid":"9NBLGGH4MSV6","id":"nn2m22r1a2","sN":2,"aN":"m22r1a2","bhvr":80,"tags":{"buttonType":"Buy","sku":"0010","availabilityId":"B4HL953543QH","buttonCommandType":"LaunchUri"}}
# The pid is 9NBLGGH4MSV6 and this is the product id we are going to get link for this store app from.
# Go to https://store.rg-adguard.net, choose ProductId in dropdown list, enter the pid(9NBLGGH4MSV6) next to it and hit on tick button.
# After it, you can download appxbundle for Ubuntu 20.04
# It is the store app bundle file. We can get the link to any store app this way.
# Rename it to zip, extract it and you can see a list of appx files.
# You can go forward with Ubuntu_2004.2020.416.0_x64.appx or Ubuntu_2004.2020.418.0_ARM64.appx according to your choice.
# =====================================================================================================
$AppxUri="http://tlu.dl.delivery.mp.microsoft.com/filestreamingservice/files/39d871ba-2d91-4a27-a78e-4c45a7b249e8?P1=1591226963&P2=402&P3=2&P4=h9aAwEchYPNaxryYTh8IVXfbX777C7CyugJm%2bcCwdV1foZEjVdB2O2a%2fSH1syE1JZWiSULRVrHiyvkndUHsCLg%3d%3d"
$AppxFileName="Ubuntu_2004.2020.424.0_x64.appx"

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

        $UbuntuPath = (Join-Path -Path $env:TEMP -ChildPath $AppxFileName)
        [System.Net.WebClient]::new().DownloadFile($AppxUri, $UbuntuPath)
        $ProgressPreference = $DefaultPref

        # FYI: this only installs Ubuntu on your user
        Add-AppxPackage -Path $UbuntuPath

        # Can't call wsl until you initialize the distro setup and define username and password
        &$DistroExe run pwd
    
        # We're going to download the image outside of the MS store because it's blocked in some places
        # ============================================================================================================================
        # When trying to download rootfs: https://github.com/MicrosoftDocs/WSL/issues/645#issuecomment-622363571
        # $DistroId = "Ubuntu-20.04"
        # $DistroInstallLocation = "Ubuntu_2004"
        # $DistroUrl = "https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64-wsl.rootfs.tar.gz"
        # Invoke-WebRequest -Uri $DistroUrl -OutFile $distroFile -UseBasicParsing
        # Write-Host "Importing WSL distro: $DistroId..."
        # wsl --import $DistroId $DistroInstallLocation $localDistroFile
        # wsl --set-default $DistroId
        # wsl --set-default-version 2
        # ============================================================================================================================
    }
}

#Get WSL subsystem ready to be run
$Start=Get-Date
Initialize-WslDistrobution
Invoke-WslSetup
$End=Get-Date
Write-Host "Total time: $(($End-$Start).TotalMinutes) minutes"