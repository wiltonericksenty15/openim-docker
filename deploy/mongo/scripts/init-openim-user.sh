#!/bin/bash
set -e

mongosh <<EOF
db = db.getSiblingDB('${MONGO_INITDB_DATABASE}');
if (!db.getUser('${MONGO_OPENIM_USERNAME}')) {
  db.createUser({
    user: '${MONGO_OPENIM_USERNAME}',
    pwd: '${MONGO_OPENIM_PASSWORD}',
    roles: [{ role: 'readWrite', db: '${MONGO_INITDB_DATABASE}' }]
  });
  print('OpenIM user created: ${MONGO_OPENIM_USERNAME}@${MONGO_INITDB_DATABASE}');
} else {
  print('OpenIM user already exists: ${MONGO_OPENIM_USERNAME}@${MONGO_INITDB_DATABASE}');
}
EOF
