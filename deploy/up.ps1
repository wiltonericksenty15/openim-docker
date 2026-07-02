# 在 deploy 目录下启动服务，自动加载 deploy/.env
# 用法: .\up.ps1 [服务名|分组]
#   服务名: network mongo redis etcd kafka minio openim-server openim-chat
#           openim-web-front openim-admin-front prometheus alertmanager grafana node-exporter
#   分组:   infra | app | front | monitor | all (默认)

param(
    [Parameter(Position = 0)]
    [string]$Target = "all"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvFile = Join-Path $ScriptDir ".env"

function Ensure-Network {
    docker network inspect openim 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host ">>> Creating network openim..."
        docker network create openim
    }
}

function Invoke-ComposeUp {
    param([string]$Service)
    if ($Service -eq "network") {
        Ensure-Network
        return
    }
    Ensure-Network
    Write-Host ">>> Starting $Service..."
    docker compose --env-file $EnvFile -f (Join-Path $ScriptDir "$Service/docker-compose.yaml") up -d
}

function Start-Infra {
    Invoke-ComposeUp "mongo"
    Invoke-ComposeUp "redis"
    Invoke-ComposeUp "etcd"
    Invoke-ComposeUp "kafka"
    Invoke-ComposeUp "minio"
}

function Start-App {
    Invoke-ComposeUp "openim-server"
    Invoke-ComposeUp "openim-chat"
}

function Start-Front {
    Invoke-ComposeUp "openim-web-front"
    Invoke-ComposeUp "openim-admin-front"
}

function Start-Monitor {
    Invoke-ComposeUp "prometheus"
    Invoke-ComposeUp "alertmanager"
    Invoke-ComposeUp "grafana"
    Invoke-ComposeUp "node-exporter"
}

function Start-All {
    Invoke-ComposeUp "network"
    Start-Infra
    Start-App
    Start-Front
}

function Show-Usage {
    @"
用法: .\up.ps1 [目标]

服务:
  network  mongo  redis  etcd  kafka  minio
  openim-server  openim-chat
  openim-web-front  openim-admin-front
  prometheus  alertmanager  grafana  node-exporter

分组:
  infra    基础组件 (mongo redis etcd kafka minio)
  app      应用服务 (openim-server openim-chat)
  front    前端 (openim-web-front openim-admin-front)
  monitor  监控 (prometheus alertmanager grafana node-exporter)
  all      全部 (默认，不含 monitor)

示例:
  .\up.ps1 redis
  .\up.ps1 infra
  .\up.ps1 all
"@
}

$services = @(
    "network", "mongo", "redis", "etcd", "kafka", "minio",
    "openim-server", "openim-chat",
    "openim-web-front", "openim-admin-front",
    "prometheus", "alertmanager", "grafana", "node-exporter"
)

switch ($Target) {
    { $_ -in $services } { Invoke-ComposeUp $Target }
    "infra"   { Start-Infra }
    "app"     { Start-App }
    "front"   { Start-Front }
    "monitor" { Start-Monitor }
    "all"     { Start-All }
    { $_ -in @("-h", "--help", "help") } { Show-Usage; exit 0 }
    default {
        Write-Error "未知目标: $Target"
        Show-Usage
        exit 1
    }
}

Write-Host ">>> Done."
