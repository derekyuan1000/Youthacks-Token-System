#!/bin/bash
set -eo pipefail
ERROR_LOG="/tmp/deploy_error_$$.log"
trap 'if [ $? -ne 0 ]; then echo "Deployment failed, sending error email..."; tail -n 100 "$ERROR_LOG" | mail -s "Deployment Failed on $(hostname)" matthew@youthacks.org; fi' EXIT
export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
cd /home/mattsoh/pub/aha || exit 1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Checking for updates..."

# Fetch remote changesqw
git fetch origin main

LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse origin/main)

if [ "$LOCAL_HASH" != "$REMOTE_HASH" ] || ! docker ps -q -f name=mattsoh_aha | grep -q .; then
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] New commit detected. Rebuilding and restarting Docker container..."
	docker container prune -f 2>>"$ERROR_LOG"
	git reset --hard origin/main


	TIMESTAMP=$(date +%s)
	BACKUP_NAME="mattsoh_aha_backup_$TIMESTAMP"

	EXISTING_CONTAINER=$(docker ps -a -q -f "name=^mattsoh_aha$")

	if [ -n "$EXISTING_CONTAINER" ]; then
		echo "Renaming existing container mattsoh_aha to $BACKUP_NAME"
		docker rename mattsoh_aha "$BACKUP_NAME" 2>>"$ERROR_LOG"
	fi
	# PID=$(lsof -ti TCP:3836)
	# if [ -n "$PID" ]; then
	#   echo "[$(date '+%Y-%m-%d %H:%M:%S')] Killing process $PID occupying port 3836"
	#   kill -9 $PID || true
	# fi

	echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleanup done, proceeding to build and run Docker container..."

	echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_PASSWORD set: ${DB_PASSWORD:+yes}"
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] RAILS_MASTER_KEY set: ${RAILS_MASTER_KEY:+yes}"

	echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running: docker build -t aha ."
	docker build -t aha . 2>&1 | tee -a "$ERROR_LOG"

	if [ -n "$EXISTING_CONTAINER" ]; then
		echo "Stopping "$BACKUP_NAME" container..."
		docker stop "$BACKUP_NAME" 2>>"$ERROR_LOG"
	fi
	# Stop any containers using port 3836
	CONTAINERS_ON_3836=$(docker ps --format '{{.ID}}' --filter "publish=3836")
	if [ -n "$CONTAINERS_ON_3836" ]; then
		echo "Stopping containers using port 3836: $CONTAINERS_ON_3836"
		docker stop $CONTAINERS_ON_3836 2>>"$ERROR_LOG" || true
	fi

	echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running: docker run --name mattsoh_aha ..."
	docker run --name mattsoh_aha -d \
		-p 3836:3000 \
		-v /var/run/postgres:/var/run/postgres \
		-e PGDATABASE=mattsoh_aha_production \
		-e PGPASSWORD=$DB_PASSWORD \
		-e RAILS_MASTER_KEY=$RAILS_MASTER_KEY \
		-e SECRET_KEY_BASE=$SECRET_KEY_BASE \
		aha 2>&1 | tee -a "$ERROR_LOG"

  # Check if new container is running, restore backup if not
	if ! docker ps -q -f name=mattsoh_aha | grep -q .; then
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] New container failed to start. Restoring previous container..."
		if [ -n "$EXISTING_CONTAINER" ]; then
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] Renaming backup container $BACKUP_NAME to mattsoh_aha and restarting"
			docker rename "$BACKUP_NAME" mattsoh_aha 2>>"$ERROR_LOG"
			docker start mattsoh_aha 2>>"$ERROR_LOG"
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] Previous container restored."

		else
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] No previous container found, cannot restore."
		fi
	else
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] New container running successfully. Removing backup..."
		docker rm -f "$BACKUP_NAME" || true
    
	fi

	echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleaning up stopped containers..."
	docker container prune -f 2>>"$ERROR_LOG"

	echo "[$(date '+%Y-%m-%d %H:%M:%S')] Deploy complete."
	systemctl --user reload caddy
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] No new updates."
fi