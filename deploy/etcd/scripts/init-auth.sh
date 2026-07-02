#!/bin/sh
set -e

export ETCDCTL_API=3

echo "Waiting for etcd to become healthy..."
until etcdctl --endpoints=http://127.0.0.1:2379 endpoint health >/dev/null 2>&1; do
  echo "Waiting for ETCD to start..."
  sleep 1
done

echo "etcd is healthy."

if [ -n "${ETCD_ROOT_USER}" ] && [ -n "${ETCD_ROOT_PASSWORD}" ] && [ -n "${ETCD_USERNAME}" ] && [ -n "${ETCD_PASSWORD}" ]; then
  echo "Authentication credentials provided. Setting up authentication..."

  echo "Checking authentication status..."
  if ! etcdctl --endpoints=http://127.0.0.1:2379 auth status | grep -q "Authentication Status: true"; then
    echo "Authentication is disabled. Creating users and enabling..."

    etcdctl --endpoints=http://127.0.0.1:2379 user add "${ETCD_ROOT_USER}" --new-user-password="${ETCD_ROOT_PASSWORD}" || true
    etcdctl --endpoints=http://127.0.0.1:2379 user add "${ETCD_USERNAME}" --new-user-password="${ETCD_PASSWORD}" || true

    etcdctl --endpoints=http://127.0.0.1:2379 role add openim-role || true
    etcdctl --endpoints=http://127.0.0.1:2379 role grant-permission openim-role --prefix=true readwrite / || true
    etcdctl --endpoints=http://127.0.0.1:2379 role grant-permission openim-role --prefix=true readwrite "" || true
    etcdctl --endpoints=http://127.0.0.1:2379 user grant-role "${ETCD_USERNAME}" openim-role || true
    etcdctl --endpoints=http://127.0.0.1:2379 user grant-role "${ETCD_ROOT_USER}" "${ETCD_USERNAME}" root || true

    echo "Enabling authentication..."
    etcdctl --endpoints=http://127.0.0.1:2379 auth enable
    echo "Authentication enabled successfully"
  else
    echo "Authentication is already enabled. Checking OpenIM user..."

    if ! etcdctl --endpoints=http://127.0.0.1:2379 --user="${ETCD_USERNAME}:${ETCD_PASSWORD}" put /test/auth "auth-check" >/dev/null 2>&1; then
      echo "OpenIM user test failed. Recreating user with root credentials..."

      etcdctl --endpoints=http://127.0.0.1:2379 --user="${ETCD_ROOT_USER}:${ETCD_ROOT_PASSWORD}" user add "${ETCD_USERNAME}" --new-user-password="${ETCD_PASSWORD}" --no-password-file || true
      etcdctl --endpoints=http://127.0.0.1:2379 --user="${ETCD_ROOT_USER}:${ETCD_ROOT_PASSWORD}" role add openim-role || true
      etcdctl --endpoints=http://127.0.0.1:2379 --user="${ETCD_ROOT_USER}:${ETCD_ROOT_PASSWORD}" role grant-permission openim-role --prefix=true readwrite / || true
      etcdctl --endpoints=http://127.0.0.1:2379 --user="${ETCD_ROOT_USER}:${ETCD_ROOT_PASSWORD}" role grant-permission openim-role --prefix=true readwrite "" || true
      etcdctl --endpoints=http://127.0.0.1:2379 --user="${ETCD_ROOT_USER}:${ETCD_ROOT_PASSWORD}" user grant-role "${ETCD_USERNAME}" openim-role || true
      etcdctl --endpoints=http://127.0.0.1:2379 user grant-role "${ETCD_ROOT_USER}" "${ETCD_USERNAME}" root || true

      echo "OpenIM user recreated with required permissions"
    else
      echo "OpenIM user exists and has correct permissions"
      etcdctl --endpoints=http://127.0.0.1:2379 --user="${ETCD_USERNAME}:${ETCD_PASSWORD}" del /test/auth >/dev/null 2>&1
    fi
  fi

  echo "Testing authentication with OpenIM user..."
  if etcdctl --endpoints=http://127.0.0.1:2379 --user="${ETCD_USERNAME}:${ETCD_PASSWORD}" put /test/auth "auth-works"; then
    echo "Authentication working properly"
    etcdctl --endpoints=http://127.0.0.1:2379 --user="${ETCD_USERNAME}:${ETCD_PASSWORD}" del /test/auth
  else
    echo "WARNING: Authentication test failed"
  fi
else
  echo "No authentication credentials provided. Running in no-auth mode."
  echo "To enable authentication, set ETCD_ROOT_USER, ETCD_ROOT_PASSWORD, ETCD_USERNAME, and ETCD_PASSWORD in deploy/.env"
fi
