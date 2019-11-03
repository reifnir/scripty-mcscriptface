$username="jim.andreasen@reifnir.com"
$password=Read-Host -Prompt "Password" -AsSecureString
$creds = New-Object System.Management.Automation.PSCredential ($username, $password)
Login-AzureRmAccount -Credential $creds
