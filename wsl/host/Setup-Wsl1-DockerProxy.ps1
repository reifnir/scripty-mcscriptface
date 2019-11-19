$dockerProxyName = "wsl-docker-proxy"
$existingContainer=$(docker ps --filter name=$dockerProxyName -q)
if ($existingContainer) {
    Write-Host "Persistent Docker container for WSL1 passthrough already running..."
} else {
    Write-Host "Starting a persistent Docker container to act as a passthrough for WSL1 to be able to reach..."
    docker run --name $dockerProxyName -d --restart=always -p 127.0.0.1:23750:2375 -v /var/run/docker.sock:/var/run/docker.sock  alpine/socat  tcp-listen:2375,fork,reuseaddr unix-connect:/var/run/docker.sock
}
