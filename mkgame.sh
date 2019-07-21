#!/bin/bash

# mkgame.sh <dirname> <gamename> <ald-location>

usage() {
    echo "Usage: mkgame.sh <dir-name> <game-name> <ald-loc>"
    echo "       <dir-name>  - the name of the directory to create in games/"
    echo "       <game-name> - the friendly name of the game"
    echo "       <ald-loc>   - the location of the game's .ALD files"
}

# check arguments
if [ -z "$1" -o -z "$2" -o -z "$3" -o -n "$4" ]; then
    echo "ERROR: Wrong number of arguments."
    usage
    exit 1
fi

REPO_ROOT="$(readlink -f $(dirname $0))"
DIRNAME="$1"
GAMENAME="$2"
ALDLOC="$3"

if [ -e "${REPO_ROOT}/games/${DIRNAME}" ]; then
    echo "ERROR: ${REPO_ROOT}/games/${DIRNAME} already exists."
    usage
    exit 1
fi

if [ ! -d "${ALDLOC}" ]; then
    echo "ERROR: $ALDLOC is not a directory."
    usage
    exit 1
fi

# FIXME: don't run find twice
if [ `find "${ALDLOC}" -iname "*.ald" -type f -printf '.' | wc -c` == "0" ]; then
    echo "ERROR: No .ALD files found in ${ALDLOC}"
    usage
    exit 1
fi

TEMPLATES="${REPO_ROOT}/templates"
GAMEDIR="${REPO_ROOT}/games/${DIRNAME}"

set -x
set -e

mkdir "${GAMEDIR}"

# check if midi support is required
if [ `find "${GAMEDIR}/gamedata" -iname "*ma.ald" -type f -printf '.' | wc -c` == "0" ]; then
    MIDI=".midi"
fi

# cp with text substitution
template_cp () {
    sed -e "s/%DIRNAME%/${DIRNAME}/g" -e "s/%GAMENAME%/${GAMENAME}/g" "$1" > "$2"
}

template_cp "${TEMPLATES}/AppRun${MIDI}" "${GAMEDIR}/AppRun"
chmod +x    "${GAMEDIR}/AppRun"
template_cp "${TEMPLATES}/game.desktop"  "${GAMEDIR}/${DIRNAME}.desktop"
cp          "${TEMPLATES}/game.png"      "${GAMEDIR}/${DIRNAME}.png"
cp -r       "${TEMPLATES}/gamedata"      "${GAMEDIR}/gamedata"

if [ -n "${MIDI}" ]; then
    cp "${TEMPLATES}/TimGM6mb.sf2" "${GAMEDIR}/gamedata/"
fi

# copy .ALD files
find "${ALDLOC}" -iname "*ald" -type f -exec cp '{}' "${GAMEDIR}/gamedata/" ";"

# generate one line of a gameresource file
grline () {
    find "${GAMEDIR}/gamedata" -iname "*$2" -printf "$1 %f\n"
}

# Write gameresource file
for c in {A..J}; do
    grline "Scenario${c}" "S${c}.ALD" >> "${GAMEDIR}/gamedata/xsystem35.gr"
done
for c in {A..J}; do
    grline "Graphics${c}" "G${c}.ALD" >> "${GAMEDIR}/gamedata/xsystem35.gr"
done
for c in {A..J}; do
    grline "Midi${c}" "M${c}.ALD" >> "${GAMEDIR}/gamedata/xsystem35.gr"
done
for c in {A..J}; do
    grline "Wave${c}" "W${c}.ALD" >> "${GAMEDIR}/gamedata/xsystem35.gr"
done
for c in {A..J}; do
    grline "Data${c}" "D${c}.ALD" >> "${GAMEDIR}/gamedata/xsystem35.gr"
done
for c in {A..J}; do
    echo "Save${c} ~/.xsys35/saves/${GAMENAME}/${GAMENAME}${c}.ASD" >> "${GAMEDIR}/gamedata/xsystem35.gr"
done

