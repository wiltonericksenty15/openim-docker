#!/usr/bin/env bash
# 在 deploy 目录下启动服务，自动加载 deploy/.env
# 用法: ./up.sh [服务名|分组]
#   服务名: network mongo redis etcd kafka minio openim-server openim-chat
#           openim-web-front openim-admin-front prometheus alertmanager grafana node-exporter
#   分组:   infra | app | front | monitor | all (默认)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

compose_up() {
  local service=$1
  echo ">>> Starting ${service}..."
  docker compose --env-file "${ENV_FILE}" -f "${SCRIPT_DIR}/${service}/docker-compose.yaml" up -d
}

start_infra() {
  compose_up mongo
  compose_up redis
  compose_up etcd
  compose_up kafka
  compose_up minio
}

start_app() {
  compose_up openim-server
  compose_up openim-chat
}

start_front() {
  compose_up openim-web-front
  compose_up openim-admin-front
}

start_monitor() {
  compose_up prometheus
  compose_up alertmanager
  compose_up grafana
  compose_up node-exporter
}

start_all() {
  compose_up network
  start_infra
  start_app
  start_front
}

usage() {
  cat <<'EOF'
用法: ./up.sh [目标]

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
  ./up.sh redis
  ./up.sh infra
  ./up.sh all
EOF
}

TARGET="${1:-all}"

case "${TARGET}" in
  network|mongo|redis|etcd|kafka|minio|openim-server|openim-chat|openim-web-front|openim-admin-front|prometheus|alertmanager|grafana|node-exporter)
    compose_up "${TARGET}"
    ;;
  infra) start_infra ;;
  app) start_app ;;
  front) start_front ;;
  monitor) start_monitor ;;
  all) start_all ;;
  -h|--help|help) usage ;;
  *)
    echo "未知目标: ${TARGET}" >&2
    usage >&2
    exit 1
    ;;
esac

echo ">>> Done."
