#!/bin/bash
set -e
export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
cd /home/mattsoh/pub/aha || exit 1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Checking for updates..."

# Fetch remote changesqw
git fetch origin main

LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse origin/main)

if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] New commit detected. Rebuilding and restarting Docker container..."

  git reset --hard origin/main

  CONTAINER_IDS=$(docker ps -q --filter "publish=3836")

  if [ -n "$CONTAINER_IDS" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stopping and removing container(s) using port 3836: $CONTAINER_IDS"
    docker stop $CONTAINER_IDS
    docker rm $CONTAINER_IDS
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] No container found using port 3836"
  fi
  # PID=$(lsof -ti TCP:3836)
  # if [ -n "$PID" ]; then
  #   echo "[$(date '+%Y-%m-%d %H:%M:%S')] Killing process $PID occupying port 3836"
  #   kill -9 $PID || true
  # fi

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleanup done, proceeding to build and run Docker container..."

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_PASSWORD set: ${DB_PASSWORD:+yes}"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] RAILS_MASTER_KEY set: ${RAILS_MASTER_KEY:+yes}"

  docker build -t aha .

  docker run --name aha -d \
    -p 3836:3000 \
    -v /var/run/postgres:/var/run/postgres \
    -e PGDATABASE=mattsoh_aha_production \
    -e PGPASSWORD=$DB_PASSWORD \
    -e RAILS_MASTER_KEY=$RAILS_MASTER_KEY \
    aha

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Deploy complete."
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] No new updates."
fi