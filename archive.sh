#!/bin/bash

# cd games/$GAME/gamedata
# tar -czvf ../../../$GAME.tar.gz *

usage() {
    echo "Usage: $0 <game>"
    exit 1
}

if [ -z "$1" ]; then
    echo "ERROR: Missing required argument: <game>"
    usage
fi

REPO_ROOT="$(readlink -f $(dirname $0))"
GAME="$1"
GAMEDIR="${REPO_ROOT}/games/${GAME}"

if [ ! -d "${GAMEDIR}" ]; then
    echo "ERROR: No directory for game: ${GAME}"
    usage
fi

if [ ! -d "${GAMEDIR}/gamedata" ]; then
    echo "ERROR: No data to archive for game: ${GAME}"
    usage
fi

cd "${GAMEDIR}/gamedata"
tar -czvf "${REPO_ROOT}/${GAME}.tar.gz" * .xsys35rc
