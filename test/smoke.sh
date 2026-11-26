#!/usr/bin/env bash
# Smoke test: aws-cli and the postgres client tools run, and psql can query a
# real Postgres.
# Usage: test/smoke.sh <image>
set -euo pipefail
IMAGE="${1:?usage: $0 <image>}"
NET="psqls3-smoke-$$"; DB="psqls3-smoke-db-$$"
trap 'docker rm -f "$DB" >/dev/null 2>&1; docker network rm "$NET" >/dev/null 2>&1' EXIT

docker run --rm "$IMAGE" aws --version
for t in psql pg_dump pg_restore pg_isready; do
  docker run --rm "$IMAGE" "$t" --version >/dev/null || { echo "FAIL: $t missing" >&2; exit 1; }
done
echo "ok: aws, psql, pg_dump, pg_restore, pg_isready run"

docker network create "$NET" >/dev/null
docker run -d --name "$DB" --network "$NET" -e POSTGRES_PASSWORD=smoke postgres:16-alpine >/dev/null
for _ in $(seq 1 60); do
  docker run --rm --network "$NET" "$IMAGE" pg_isready -h "$DB" >/dev/null 2>&1 && ready=1 && break
  sleep 1
done
[ "${ready:-0}" = "1" ] || { echo "FAIL: postgres never ready" >&2; exit 1; }
[ "$(docker run --rm --network "$NET" -e PGPASSWORD=smoke "$IMAGE" psql -h "$DB" -U postgres -tA -c 'select 1')" = "1" ] \
  || { echo "FAIL: psql query failed" >&2; exit 1; }
echo "ok: psql select 1"
echo "smoke test passed"
