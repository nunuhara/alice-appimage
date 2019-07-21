GAMES=gakuen kichikuou kichikuou_en rance1 rance1_en rance2 rance3 rance3_en rance4 rance4_en toushin1 toushin1_en toushin2 toushin2_en
APPS=${GAMES} xsystem35-sdl2
APPIMAGES=$(addsuffix .AppImage,${APPS})
ARCHIVES=$(addsuffix .tar.gz,${GAMES})

all:
	@echo "ERROR: No target specified."

build-all: ${APPIMAGES}

archive-all: ${ARCHIVES}

# TODO: use a macro to generate rules with dependency on $(shell -find game/${APP} -type f)
${APPIMAGES}: FORCE

# TODO: use a macro to generate rules with dependency on $(shell -find game/${APP}/gamedata -type f)
${ARCHIVES}: FORCE

FORCE:

%.AppImage:
	./build.sh $(basename $@)

%.tar.gz:
	./archive.sh $(basename $(basename $@))
