# We're going to downloda the image outside of the MS store because it's blocked in some places
$DISTRO_LOCATION="https://aka.ms/wsl-debian-gnulinux"

Invoke-WebRequest -Uri $DISTRO_LOCATION -OutFile .\distro.appx -UseBasicParsing

Add-AppxPackage .\distro.appx

# Can't call wsl until you kick off the distro setup
debian