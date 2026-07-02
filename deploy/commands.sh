#!/usr/bin/env bash
# 各服务独立启动命令（含 --env-file），在 deploy 目录下执行
# 也可直接复制单条命令使用

ENV_FILE=".env"

# 网络
docker compose --env-file ${ENV_FILE} -f network/docker-compose.yaml up -d

# 基础组件
docker compose --env-file ${ENV_FILE} -f mongo/docker-compose.yaml up -d
docker compose --env-file ${ENV_FILE} -f redis/docker-compose.yaml up -d
docker compose --env-file ${ENV_FILE} -f etcd/docker-compose.yaml up -d
docker compose --env-file ${ENV_FILE} -f kafka/docker-compose.yaml up -d
docker compose --env-file ${ENV_FILE} -f minio/docker-compose.yaml up -d

# 应用服务
docker compose --env-file ${ENV_FILE} -f openim-server/docker-compose.yaml up -d
docker compose --env-file ${ENV_FILE} -f openim-chat/docker-compose.yaml up -d

# 前端
docker compose --env-file ${ENV_FILE} -f openim-web-front/docker-compose.yaml up -d
docker compose --env-file ${ENV_FILE} -f openim-admin-front/docker-compose.yaml up -d

# 监控（可选）
# docker compose --env-file ${ENV_FILE} -f prometheus/docker-compose.yaml up -d
# docker compose --env-file ${ENV_FILE} -f alertmanager/docker-compose.yaml up -d
# docker compose --env-file ${ENV_FILE} -f grafana/docker-compose.yaml up -d
# docker compose --env-file ${ENV_FILE} -f node-exporter/docker-compose.yaml up -d
