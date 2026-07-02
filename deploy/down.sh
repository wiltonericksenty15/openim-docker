#!/usr/bin/env bash
# 在 deploy 目录下停止服务，自动加载 deploy/.env
# 用法: ./down.sh [服务名|分组|all]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

compose_down() {
  local service=$1
  echo ">>> Stopping ${service}..."
  docker compose --env-file "${ENV_FILE}" -f "${SCRIPT_DIR}/${service}/docker-compose.yaml" down
}

stop_infra() {
  compose_down minio
  compose_down kafka
  compose_down etcd
  compose_down redis
  compose_down mongo
}

stop_app() {
  compose_down openim-chat
  compose_down openim-server
}

stop_front() {
  compose_down openim-admin-front
  compose_down openim-web-front
}

stop_monitor() {
  compose_down node-exporter
  compose_down grafana
  compose_down alertmanager
  compose_down prometheus
}

stop_all() {
  stop_front
  stop_app
  stop_infra
  compose_down network
}

usage() {
  cat <<'EOF'
用法: ./down.sh [目标]

服务:
  network  mongo  redis  etcd  kafka  minio
  openim-server  openim-chat
  openim-web-front  openim-admin-front
  prometheus  alertmanager  grafana  node-exporter

分组:
  infra  app  front  monitor  all (默认)

示例:
  ./down.sh redis
  ./down.sh all
EOF
}

TARGET="${1:-all}"

case "${TARGET}" in
  network|mongo|redis|etcd|kafka|minio|openim-server|openim-chat|openim-web-front|openim-admin-front|prometheus|alertmanager|grafana|node-exporter)
    compose_down "${TARGET}"
    ;;
  infra) stop_infra ;;
  app) stop_app ;;
  front) stop_front ;;
  monitor) stop_monitor ;;
  all) stop_all ;;
  -h|--help|help) usage ;;
  *)
    echo "未知目标: ${TARGET}" >&2
    usage >&2
    exit 1
    ;;
esac

echo ">>> Done."
