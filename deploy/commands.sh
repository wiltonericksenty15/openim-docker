#!/usr/bin/env bash
# 各服务独立启动命令，在 deploy 目录下执行

ENV_FILE=".env"

docker network create openim 2>/dev/null || true

docker compose --env-file ${ENV_FILE} -f mongo/docker-compose.yaml up -d
docker compose --env-file ${ENV_FILE} -f redis/docker-compose.yaml up -d
docker compose --env-file ${ENV_FILE} -f etcd/docker-compose.yaml up -d
docker compose --env-file ${ENV_FILE} -f kafka/docker-compose.yaml up -d
docker compose --env-file ${ENV_FILE} -f minio/docker-compose.yaml up -d
docker compose --env-file ${ENV_FILE} -f openim-server/docker-compose.yaml up -d
docker compose --env-file ${ENV_FILE} -f openim-chat/docker-compose.yaml up -d
docker compose --env-file ${ENV_FILE} -f openim-web-front/docker-compose.yaml up -d
docker compose --env-file ${ENV_FILE} -f openim-admin-front/docker-compose.yaml up -d

# 监控（可选）
# docker compose --env-file ${ENV_FILE} -f prometheus/docker-compose.yaml up -d
# docker compose --env-file ${ENV_FILE} -f alertmanager/docker-compose.yaml up -d
# docker compose --env-file ${ENV_FILE} -f grafana/docker-compose.yaml up -d
# docker compose --env-file ${ENV_FILE} -f node-exporter/docker-compose.yaml up -d
