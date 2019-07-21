## AliceSoft Freeware AppImages

This repo contains scripts for building AppImages of some of AliceSoft's
freeware games. The games are bundled together with
[xsystem35-sdl2](https://github.com/kichikuou/xsystem35-sdl2) so that they can
be played on Linux.

Pre-built AppImages can be found [here](http://haniwa.website/games).

### Building

To build a particular game, run `./build.sh <game>`. Game data will be
downloaded from the internet, if possible (i.e. if the game is listed in the
section below) and a file `<game>.AppImage` should be created in the current
directory.

If you want to build an AppImage for a game not listed below, you can run
`./mkgame` <dirname> <gamename> <aldloc>`, where:

* `<dirname>` is the name of the directory to create in `games/`, and will be
the name passed to `build.sh`
* `<gamename>` is the friendly name of the game, e.g. "ランス 5D"
* `<aldloc>` is the location to search for the game's .ALD files

This will create a directory under `games/` in the proper format to create an
AppImage. Once this directory is created, you can run `./build.sh <dirname>` to
build the AppImage.

### Games

Games supported so far:

* Rance (EN+JP) (name: rance1_en/rance1)
* Rance II (JP) (name: rance2)
* Rance III (EN+JP) (name: rance3_en/rance3)
* Rance IV (EN+JP) (name: rance4_en/rance4)
* Kichikuou Rance (EN+JP) (name: kichikuou_en/kichikuou)
* Toushin Toshi (EN+JP) (name: toushin1_en/toushin1)
* Toushin Toshi II (EN+JP) (name: toushin2_en/toushin2)
