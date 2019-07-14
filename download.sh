#!/bin/bash

usage() {
    echo "Usage: ${0} <game>"
    exit 1
}

if [ -z "${1}" ]; then
    echo "ERROR: Missing required argument: <game>"
    usage
fi

REPO_ROOT=$(readlink -f $(dirname $0))
GAME=${1}
GAMEDATA="${REPO_ROOT}/games/${GAME}/gamedata"

if [ ! -d "${REPO_ROOT}/games/${GAME}" ]; then
    echo "ERROR: No directory for game: ${GAME}"
    usage
fi

mkdir "${GAMEDATA}"
curl -s "http://www.haniwa.website/games/${GAME}.tar.gz" | tar -C "${GAMEDATA}" -xzf -
