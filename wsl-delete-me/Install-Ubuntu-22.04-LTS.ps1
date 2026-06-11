$ErrorActionPreference = "Stop"

# Look here later to find newer versions:
# https://docs.microsoft.com/en-us/windows/wsl/install-manual#downloading-distributions
$DistroUri = "https://aka.ms/wslubuntu2204"
$DistroName = "Ubuntu-22.04"
$DistroExe = "ubuntu2204.exe"

function Test-WslInstalled() {
    Write-Host "Check-WslInstalled..."
    $wslFound = $(where.exe /q wsl; $?)
    if ($wslFound) {
        Write-Host "Check-WslInstalled: WSL found at path: $(where.exe wsl)"
    }
    else {
        # These notes are only valid for Windows 10
        Write-Error -Message "Check-WslInstalled: WSL is not enabled. You must first run the following command in an Administrator PowerShell session (then reboot): 'Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux'"
    }
}

function Ensure-DistroInstalled() {
    Write-Host "Ensure-DistroInstalled..."
    $distroInstalled = "$(where.exe /q $DistroExe; $?)"
    
    if ($distroInstalled -eq $true) {
        Write-Host "Ensure-DistroInstalled: distro already found at path $(where.exe $DistroExe)"
    }
    else {
        Write-Host "Ensure-DistroInstalled: Downloading distro package. This may take several minutes (5-10)..."

        # Changing '$ProgressPreference' will drasticly increase the file download speed.
        $DefaultPref = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'

        $DistroPath = (Join-Path -Path $env:TEMP -ChildPath "$DistroName.appx")
        [System.Net.WebClient]::new().DownloadFile($DistroUri, $DistroPath)
        $ProgressPreference = $DefaultPref

        # FYI: this only installs Ubuntu on your user
        Add-AppxPackage -Path $DistroPath

        # # Can't call wsl until you initialize the distro setup and define username and password
        &$DistroExe run pwd
    }
}

$Start = Get-Date
Test-WslInstalled
Ensure-DistroInstalled

Write-Host "Making this distro default... (this fails if still on WSL1)"
wsl --set-default $DistroName
wsl --set-default-version 2

$End = Get-Date
Write-Host "Total time: $(($End-$Start).TotalMinutes) minutes"
