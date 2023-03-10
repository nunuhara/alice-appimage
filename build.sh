#!/bin/bash

usage() {
    echo "Usage: $0 <game>"
    exit 1
}

while getopts ":e:ho:" opt; do
    case "${opt}" in
        e ) ENGINE="${OPTARG}"
            ;;
        h ) usage 0
            ;;
        o ) OUTPUT_NAME="${OPTARG}"
            ;;
        \? ) usage
            ;;
    esac
done
shift $((OPTIND -1))

if [ -z "$1" ]; then
    echo "ERROR: Missing required argument: <game>"
    usage
fi

if [ -n "$2" ]; then
    echo "ERROR: Too many arguments"
    usage
fi

REPO_ROOT="$(readlink -f $(dirname $0))"
OLD_CWD="$(readlink -f .)"
GAME="$1"
GAMEDIR="${REPO_ROOT}/games/${GAME}"

# provide defaults if not passed as arguments
OUTPUT_NAME="${OUTPUT_NAME:-${GAME}.AppImage}"
case "${GAME}" in
    # we need a bit of special logic later if we're building a bare engine
    xsystem35-sdl2 | xsystem35-sdl2-texthook | system3-sdl2 )
        ENGINE="${GAME}"
        BUILDING_ENGINE=yes
        ;;
    * ) ENGINE="${ENGINE:-xsystem35-sdl2}"
        ;;
esac

# ensure directory exists for game
if [ ! -d "${GAMEDIR}" ]; then
    echo "ERROR: No directory for game: ${GAME}"
    usage
fi

# download xsystem35 from internet, if needed
if [ ! -e "${ENGINE}" ]; then
    echo "Downloading ${ENGINE} source code..."
    case "${ENGINE}" in
        xsystem35-sdl2 )
            git clone https://github.com/kichikuou/xsystem35-sdl2.git \
                "${REPO_ROOT}/${ENGINE}"
            ;;
	xsystem35-sdl2-texthook )
            git clone https://github.com/kichikuou/xsystem35-sdl2.git \
                "${REPO_ROOT}/${ENGINE}"
	    sed -i '1s;^;#define TEXTHOOK_PRINT\n;' "${REPO_ROOT}/${ENGINE}/src/texthook.c"
            ;;
        * ) echo "ERROR: Unknown engine: ${ENGINE}"
            usage
            ;;
    esac
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to clone repository for ${ENGINE}"
        exit 1
    fi
fi

# download game data from internet, if needed
if [ -z "${BUILDING_ENGINE}" -a ! -d "${GAMEDIR}/gamedata" ]; then
    echo "Game data for ${GAME} not found; downloading from internet..."
    mkdir "${GAMEDIR}/gamedata"
    curl -s "https://haniwa.website/games/${GAME}.tar.gz" | tar -C "${GAMEDIR}/gamedata" -xzf -
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

cp -r "${REPO_ROOT}/fsroot" AppDir

# build game engine
case "${ENGINE}" in
    xsystem35-sdl2 | xsystem35-sdl2-texthook )
        # configure build files with CMAKE
        mkdir build
        cd build
        cmake -DCMAKE_BUILD_TYPE=Debug -DENABLE_X11=NO -DCMAKE_INSTALL_PREFIX=/usr \
            "${REPO_ROOT}/${ENGINE}/"
        # build xsystem35 and install files into AppDir
        make -j$(nproc)
        make DESTDIR="$(pwd)/AppDir" install
        ;;
    * ) echo "ERROR: Something happened :("
        exit 1
        ;;
esac

# additional script for xsystem35-sdl2-texthook
if [ "${ENGINE}" == xsystem35-sdl2-texthook ]; then
    cp "${GAMEDIR}/texthooker.sh" "AppDir/usr/bin/texthooker.sh"
fi

# install game files
if [ -z "${BUILDING_ENGINE}" ]; then
    mkdir -p AppDir/usr/share/games
    cp -r ${GAMEDIR}/gamedata AppDir/usr/share/games/${GAME}
fi

if [ -e "${GAMEDIR}/AppRun" ]; then
    APPRUN="--custom-apprun=${GAMEDIR}/AppRun"
fi

# finally, build AppImage using linuxdeploy
wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
chmod +x linuxdeploy-x86_64.AppImage
env ARCH=x86_64 OUTPUT="${OUTPUT_NAME}" ./linuxdeploy-x86_64.AppImage --appdir AppDir \
    -d "${GAMEDIR}/${GAME}.desktop" -i "${GAMEDIR}/${GAME}.png" ${APPRUN} --output appimage

mv "${OUTPUT_NAME}" "${OLD_CWD}"
