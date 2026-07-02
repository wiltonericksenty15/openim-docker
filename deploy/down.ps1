# 在 deploy 目录下停止服务，自动加载 deploy/.env
# 用法: .\down.ps1 [服务名|分组|all]

param(
    [Parameter(Position = 0)]
    [string]$Target = "all"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvFile = Join-Path $ScriptDir ".env"

function Remove-Network {
    docker network inspect openim 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host ">>> Removing network openim..."
        docker network rm openim
    }
}

function Invoke-ComposeDown {
    param([string]$Service)
    if ($Service -eq "network") {
        Remove-Network
        return
    }
    Write-Host ">>> Stopping $Service..."
    docker compose --env-file $EnvFile -f (Join-Path $ScriptDir "$Service/docker-compose.yaml") down
}

function Stop-Infra {
    Invoke-ComposeDown "minio"
    Invoke-ComposeDown "kafka"
    Invoke-ComposeDown "etcd"
    Invoke-ComposeDown "redis"
    Invoke-ComposeDown "mongo"
}

function Stop-App {
    Invoke-ComposeDown "openim-chat"
    Invoke-ComposeDown "openim-server"
}

function Stop-Front {
    Invoke-ComposeDown "openim-admin-front"
    Invoke-ComposeDown "openim-web-front"
}

function Stop-Monitor {
    Invoke-ComposeDown "node-exporter"
    Invoke-ComposeDown "grafana"
    Invoke-ComposeDown "alertmanager"
    Invoke-ComposeDown "prometheus"
}

function Stop-All {
    Stop-Front
    Stop-App
    Stop-Infra
    Invoke-ComposeDown "network"
}

function Show-Usage {
    @"
用法: .\down.ps1 [目标]

服务:
  network  mongo  redis  etcd  kafka  minio
  openim-server  openim-chat
  openim-web-front  openim-admin-front
  prometheus  alertmanager  grafana  node-exporter

分组:
  infra  app  front  monitor  all (默认)

示例:
  .\down.ps1 redis
  .\down.ps1 all
"@
}

$services = @(
    "network", "mongo", "redis", "etcd", "kafka", "minio",
    "openim-server", "openim-chat",
    "openim-web-front", "openim-admin-front",
    "prometheus", "alertmanager", "grafana", "node-exporter"
)

switch ($Target) {
    { $_ -in $services } { Invoke-ComposeDown $Target }
    "infra"   { Stop-Infra }
    "app"     { Stop-App }
    "front"   { Stop-Front }
    "monitor" { Stop-Monitor }
    "all"     { Stop-All }
    { $_ -in @("-h", "--help", "help") } { Show-Usage; exit 0 }
    default {
        Write-Error "未知目标: $Target"
        Show-Usage
        exit 1
    }
}

Write-Host ">>> Done."
