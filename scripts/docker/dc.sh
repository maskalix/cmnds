#!/bin/bash
# MULTI 'docker compose' SHORTCUTS TOOL
# in future, composed etc. will be deprecated

# Helper function
run_compose() {
  echo "+ docker compose $*"
  docker compose "$@"
}

CMD="$1"
shift

case "$CMD" in
  u)
    run_compose up "$@"
    ;;
  ud)
    run_compose up -d "$@"
    ;;
  udb)
    run_compose up -d --build "$@"
    ;;
  d)
    run_compose down "$@"
    ;;
  p)
    run_compose pull "$@"
    ;;
  ps)
    run_compose ps "$@"
    ;;
  b)
    run_compose build "$@"
    ;;
  l)
    run_compose logs "$@"
    ;;
  rs)
    run_compose restart "$@"
    ;;
  e)
    nano docker-compose.yml
    ;;
  rec)
    rm -f docker-compose.yml
    nano docker-compose.yml
    ;;
  sh)
    SERVICE="$1"
    shift
    run_compose exec "$SERVICE" sh "$@"
    ;;
  c)
    run_compose config "$@"
    ;;
  r)
    echo "Running recompose (pull -> down -> up -d)"
    run_compose pull
    run_compose down
    run_compose up -d "$@"
    ;;
  *)
    echo "Usage: $0 {u|ud|udb|d|p|ps|b|l|rs|e|rec|sh|c|r} [args...]"
    exit 1
    ;;
esac
