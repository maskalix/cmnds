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
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color

    echo -e "${YELLOW}Usage:${NC} $0 <command> [args...]"
    echo
    echo -e "${YELLOW}Available Commands:${NC}"
    echo -e "${GREEN}dc u        ${NC}| up"
    echo -e "${GREEN}dc ud       ${NC}| up -d"
    echo -e "${GREEN}dc udb      ${NC}| up -d --build"
    echo -e "${GREEN}dc d        ${NC}| down"
    echo -e "${GREEN}dc p        ${NC}| pull"
    echo -e "${GREEN}dc ps       ${NC}| ps"
    echo -e "${GREEN}dc b        ${NC}| build"
    echo -e "${GREEN}dc l        ${NC}| logs"
    echo -e "${GREEN}dc rs       ${NC}| restart"
    echo -e "${GREEN}dc e        ${NC}| edit docker-compose.yml"
    echo -e "${GREEN}dc rec      ${NC}| recreate docker-compose.yml"
    echo -e "${GREEN}dc sh <svc> ${NC}| exec into service shell"
    echo -e "${GREEN}dc c        ${NC}| config (validate)"
    echo -e "${GREEN}dc r        ${NC}| pull → down → up -d"
    echo
    exit 1
    ;;
esac
