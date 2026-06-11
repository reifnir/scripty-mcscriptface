$session = New-ApprendaSession
$token = $session.token
"Token=$token"

#url decode, base64 decode, then get UTF8 string from bytes
$sessionDecoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String([System.Web.HttpUtility]::UrlDecode($token)));

$active_session_token = $sessionDecoded.Split('|')[0]

"active_session_token=$active_session_token"

Invoke-RestGet -resource "/account/api/v1/platform/upgradestatus"