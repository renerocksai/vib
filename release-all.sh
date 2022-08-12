#!/usr/bin/env bash
EXE=vib
RELEASE_DIR=${EXE}-releases
mkdir -p $RELEASE_DIR

function getversion {
    zig run getversion.zig
}

function build {
    target=$1
    mode="$2"

    if [ "$mode" = "" ] ; then
        mode="release-safe"
    fi
    echo "Building $target..."
    rm -f zig-out/bin/${EXE}
    rm -f zig-out/bin/${EXE}.exe
    zig build -Dtarget=$target -D$mode
    if [ -f zig-out/bin/${EXE} ] ; then
        filn=$RELEASE_DIR/${EXE}-$(getversion)--$target
        mv zig-out/bin/${EXE} $filn
        gzip -f $filn
    else
        filn=$RELEASE_DIR/${EXE}-$(getversion)--$target.exe
        mv zig-out/bin/${EXE}.exe $filn
        zip -9 $filn.zip $filn
        rm -f $filn
    fi
    echo ""
}

build x86_64-linux
build x86_64-macos
build aarch64-macos
build x86_64-windows
