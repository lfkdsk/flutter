#!/usr/bin/env bash

set -e


function follow_links() {
  cd -P "${1%/*}"
  local file="$PWD/${1##*/}"
  while [[ -h "$file" ]]; do
    # On Mac OS, readlink -f doesn't work.
    cd -P "${file%/*}"
    file="$(readlink "$file")"
    cd -P "${file%/*}"
    file="$PWD/${file##*/}"
  done
  echo "$PWD/${file##*/}"
}

# Convert a filesystem path to a format usable by Dart's URI parser.
function path_uri() {
  # Reduce multiple leading slashes to a single slash.
  echo "$1" | sed -E -e "s,^/+,/,"
}

PROG_NAME="$(path_uri "$(follow_links "$BASH_SOURCE")")"
BIN_DIR="$(cd "${PROG_NAME%/*}" ; pwd -P)"

echo $PROG_NAME
echo $BIN_DIR
ENGINE_SRC_PATH=/Users/limengyun/work/repos/engine/src



echo "build ios start."
flutter clean
flutter build ios --release --dynamicart --no-codesign --local-engine-src-path=$ENGINE_SRC_PATH --local-engine=ios_release_unopt_dynamicart #--minimum-size
echo "build ios end."

APP_FRAMEWORKS_DIR=$BIN_DIR/build/ios/Release-iphoneos/Runner.app/Frameworks/App.framework
FLUTTER_FRAMEWORKS_DIR=$BIN_DIR/build/ios/Release-iphoneos/Runner.app/Frameworks/Flutter.framework

echo "strip APP_DYLIB_PATH=$APP_FRAMEWORKS_DIR"
echo "strip FLUTTER_DYLIB_PATH=$FLUTTER_FRAMEWORKS_DIR"

xcrun strip -x -S $APP_FRAMEWORKS_DIR/App
xcrun strip -x -S $FLUTTER_FRAMEWORKS_DIR/Flutter
du -sk  $APP_FRAMEWORKS_DIR | awk '{print "APP_FRAMEWORKS_DIR size=" $1 "KB"}'
du -sk  $FLUTTER_FRAMEWORKS_DIR | awk '{print "FLUTTER_FRAMEWORKS_DIR size=" $1 "KB"}'

