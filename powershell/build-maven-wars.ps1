Param([String]$WorkingDirectory="C:\SomeMavenProject", [String]$gitRepoRoot = "https://github.com/reifnir")

function Get-Prerequisites() {
    Write-Host "Ensuring that all artifacts outside of this script are found exist."
    Get-Prerequisite mvn "Maven must be installed and be found in PATH. Try installing via Chocolatey: choco install mvn -y"
    Get-Prerequisite git "Git must be installed and be found in PATH. Try installing via Chocolatey: choco install git -y"

    Write-Host "Checking that required Maven repository passwords files exist"
    $settingsSecurity = "~/.m2/settings-security.xml"
    if (!$(Test-Path "$settingsSecurity")) {
        throw "Unable to find file $settingsSecurity"
    }
    $settings = "~/.m2/settings.xml"
    if (!$(Test-Path $settings)) {
        throw "Unable to find file $settings"
    }
    Write-Host "Checking that $settings file for required servers"
    $serverIds = Select-Xml "~/.m2/settings.xml" -XPath "//id" `
        | Select-Object -ExpandProperty node `
        | Select-Object -ExpandProperty innerxml
    if ($serverIds -NotContains "some-specific-repo") {
        throw "$settings file is missing server with id = some-specific-repo"
    }
    if ($serverIds -NotContains "some-other-specific-repo") {
        throw "$settings file is missing server with id = some-other-specific-repo"
    }
}

function Get-Prerequisite([String]$command, [String]$onFail) {
    $path = $(where.exe $command)
    if ($path -eq $null) {
        throw $onFail
    }
    else {
        "Found $command at path(s): $path"
    }
}

function Initialize-WorkingDirectory($workingDir) {
    Write-Host "Initializing working directory: $workingDir"
    if (!$(Test-Path $workingDir)) {
        Write-Host "$workingDir not found. Creating..."
        New-Item -Path $workingDir -ItemType Directory | Out-Null
    }
    else {
        Write-Host "$workingDir found"
    }
}

function Get-GitRepositories($workingDir) {
    Get-GitRepository "$gitRepoRoot/some_repo_1" "$(Join-Path $workingDir "some_repo_1")"
    Get-GitRepository "$gitRepoRoot/some_repo_2" "$(Join-Path $workingDir "some_repo_2")"
}
function Get-GitRepository($repoPath, $dir) {
    if (Test-Path $(Join-Path $dir ".git")) {
        Write-Host "A Git repository already exists in path $dir. Not cloning repository"
    }
    else {
        Write-Host "Cloning repository $repoPath to $dir"
        git clone "$repoPath" "$dir"
    }
    
}
function Start-Compiling($workingDir) {
    Write-Host "Building first war..."
    mvn clean compile install -f "$(Join-Path $workingDir "some_repo_1\src\pom.xml")"

    Write-Host "Building second war..."
    mvn clean compile install -f "$(Join-Path $workingDir "some_repo_2\src\pom.xml")" -D maven.test.skip=true
}

$ErrorActionPreference = 'Stop'
Get-Prerequisites
Initialize-WorkingDirectory $WorkingDirectory
Get-GitRepositories $WorkingDirectory
Start-Compiling $WorkingDirectory
