#!/bin/bash
set -eu

BUILD="Release"
CLEAN=0

MONO_ARGS=("--aot" "--llvm" "--server" "-O=all")
XBUILD_ARGS=("/nologo")
BINARIES=("ArchiSteamFarm/bin/Release/ArchiSteamFarm.exe")
SOLUTION="ArchiSteamFarm.sln"

PRINT_USAGE() {
	echo "Usage: $0 [--clean] [debug/release]"
	exit 1
}

for ARG in "$@"; do
	case "$ARG" in
		release|Release) BUILD="Release" ;;
		debug|Debug) BUILD="Debug" ;;
		--clean) CLEAN=1 ;;
		*) PRINT_USAGE
	esac
done

XBUILD_ARGS+=("/p:Configuration=$BUILD")

cd "$(dirname "$(readlink -f "$0")")"

if [[ -d ".git" ]]; then
	git pull
fi

if [[ ! -f "$SOLUTION" ]]; then
	echo "ERROR: $SOLUTION could not be found!"
	exit 1
fi

if [[ "$CLEAN" -eq 1 ]]; then
	rm -rf out
	xbuild "${XBUILD_ARGS[@]}" "/t:Clean" "$SOLUTION"
fi

xbuild "${XBUILD_ARGS[@]}" "$SOLUTION"

if [[ ! -f "${BINARIES[0]}" ]]; then
	echo "ERROR: ${BINARIES[0]} binary could not be found!"
fi

# If it's release build, use Mono AOT for output binaries
if [[ "$BUILD" = "Release" ]]; then
	for BINARY in "${BINARIES[@]}"; do
		if [[ ! -f "$BINARY" ]]; then
			continue
		fi

		mono "${MONO_ARGS[@]}" "$BINARY"
	done
fi

echo
echo "Compilation finished successfully! :)"
