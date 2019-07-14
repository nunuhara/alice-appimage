#!/bin/bash

usage() {
    echo "Usage: $0 <game>"
    exit 1
}

if [ -z "$1" ]; then
    echo "ERROR: Missing required argument: <game>"
    usage
fi

REPO_ROOT="$(readlink -f $(dirname $0))"
OLD_CWD="$(readlink -f .)"
GAME="$1"
GAMEDIR="${REPO_ROOT}/games/${GAME}"

# ensure directory exists for game
if [ ! -d "${GAMEDIR}" ]; then
    echo "ERROR: No directory for game: ${GAME}"
    usage
fi

# download xsystem35 from internet, if needed
if [ ! -e xsystem35-sdl2 ]; then
    echo "Downloading xsystem35-sdl2 source code..."
    git clone https://github.com/kichikuou/xsystem35-sdl2.git "${REPO_ROOT}/xsystem35-sdl2"
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to clone xsystem35-sdl2 repo"
        exit 1
    fi
fi

# download game data from internet, if needed
if [ ${GAME} != "xsystem35-sdl2" -a ! -d "${GAMEDIR}/gamedata" ]; then
    echo "Game data for ${GAME} not found; downloading from internet..."
    mkdir "${GAMEDIR}/gamedata"
    curl -s "http://www.haniwa.website/games/${GAME}.tar.gz" | tar -C "${GAMEDIR}/gamedata" -xzf -
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to download game data for ${GAME}"
        exit 1
    fi
fi

# Finished initial checks/setup; now start the build process...
set -x
set -e

# build in temporary directory to keep system clean
# use RAM disk if possible (as in: not building on CI system like Travis, and RAM disk is available)
if [ "${CI}" == "" ] && [ -d /dev/shm ]; then
    TEMP_BASE=/dev/shm
else
    TEMP_BASE=/tmp
fi

BUILD_DIR=$(mktemp -d -p "${TEMP_BASE}" AppImageLauncher-build-XXXXXX)

# make sure to clean up build dir, even if errors occur
cleanup () {
    if [ -d "${BUILD_DIR}" ]; then
        rm -rf "${BUILD_DIR}"
    fi
}
trap cleanup EXIT

# switch to build dir
pushd "${BUILD_DIR}"

# configure build files with Autotools
"${REPO_ROOT}/xsystem35-sdl2/configure" --enable-cdrom=mp3 --enable-midi=sdl --enable-pkg-config --enable-debug --enable-sdl --disable-shared --with-ft-exec-prefix="${REPO_ROOT}/ft-config"

# build xsystem35 and install files into AppDir
make -j$(nproc)
make install DESTDIR="$(pwd)/AppDir" prefix=/usr

# install game files
if [ "${GAME}" != "xsystem35-sdl2" ]; then
    mkdir AppDir/usr/share/games
    cp -r ${GAMEDIR}/gamedata AppDir/usr/share/games/${GAME}
fi

# install additional licenses
mkdir -p AppDir/usr/share/doc/alicesoft
cp ${REPO_ROOT}/licenses/alicesoft.txt AppDir/usr/share/doc/alicesoft/copyright
mkdir -p AppDir/usr/share/doc/xsystem35-sdl2
cp ${REPO_ROOT}/xsystem35-sdl2/COPYING AppDir/usr/share/doc/xsystem35-sdl2/copyright

if [ "${GAME}" != xsystem35-sdl2 ]; then
    APPRUN="--custom-apprun=${GAMEDIR}/AppRun"
fi

# finally, build AppImage using linuxdeploy
wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
chmod +x linuxdeploy-x86_64.AppImage
env ARCH=x86_64 OUTPUT="${GAME}.AppImage" ./linuxdeploy-x86_64.AppImage --appdir AppDir -d "${GAMEDIR}/${GAME}.desktop" -i "${GAMEDIR}/${GAME}.png" ${APPRUN} --output appimage

mv "${GAME}.AppImage" "${OLD_CWD}"
