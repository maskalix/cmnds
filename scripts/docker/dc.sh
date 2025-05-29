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
    echo "Usage: $0 <command> [args...]"
    echo "Docker Compose Shortcuts:"
    echo "  dc u       - Run 'docker compose up'"
    echo "  dc ud      - Run 'docker compose up -d'"
    echo "  dc udb     - Run 'docker compose up -d --build'"
    echo "  dc d       - Run 'docker compose down'"
    echo "  dc p       - Run 'docker compose pull'"
    echo "  dc ps      - Run 'docker compose ps'"
    echo "  dc b       - Run 'docker compose build'"
    echo "  dc l       - Run 'docker compose logs'"
    echo "  dc rs      - Run 'docker compose restart'"
    echo "  dc e       - Edit docker-compose.yml with nano"
    echo "  dc rec     - Recreate docker-compose.yml with nano"
    echo "  dc sh svc  - Exec into service shell (e.g., 'dc sh web')"
    echo "  dc c       - Validate configuration"
    echo "  dc r       - Recompose: pull → down → up -d"
    echo
    exit 1
    ;;
esac
