#!/bin/bash
# Copyright 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

RunCommand() {
  if [[ -n "$VERBOSE_SCRIPT_LOGGING" ]]; then
    echo "♦ $*"
  fi
  "$@"
  return $?
}

# When provided with a pipe by the host Flutter build process, output to the
# pipe goes to stdout of the Flutter build process directly.
StreamOutput() {
  if [[ -n "$SCRIPT_OUTPUT_STREAM_FILE" ]]; then
    echo "$1" > $SCRIPT_OUTPUT_STREAM_FILE
  fi
}

EchoError() {
  echo "$@" 1>&2
}

AssertExists() {
  if [[ ! -e "$1" ]]; then
    if [[ -h "$1" ]]; then
      EchoError "The path $1 is a symlink to a path that does not exist"
    else
      EchoError "The path $1 does not exist"
    fi
    exit -1
  fi
  return 0
}

BuildApp() {
  RunCommand env
  local project_path="${SOURCE_ROOT}/.."
  if [[ -n "$FLUTTER_APPLICATION_PATH" ]]; then
    project_path="${FLUTTER_APPLICATION_PATH}"
  fi

  # BD ADD: START
  local dynamicart_flag="NO"
  if [[ -n "$DYNAMICART" ]]; then
    dynamicart_flag="${DYNAMICART}"
  fi

  local minimum_size_flag="NO"
  if [[ -n "$MINIMUM_SIZE" ]]; then
    minimum_size_flag="${MINIMUM_SIZE}"
  fi

  local dynamic_aot_plugins=""
  if [[ -n "$DYNAMIC_AOT_PLUGINS" ]]; then
      dynamic_aot_plugins="${DYNAMIC_AOT_PLUGINS}"
  fi
  # END

  local target_path="lib/main.dart"
  if [[ -n "$FLUTTER_TARGET" ]]; then
    target_path="${FLUTTER_TARGET}"
  fi

  local derived_dir="${SOURCE_ROOT}/Flutter"
  if [[ -e "${project_path}/.ios" ]]; then
    derived_dir="${project_path}/.ios/Flutter"
  fi

  # Default value of assets_path is flutter_assets
  local assets_path="flutter_assets"
  # The value of assets_path can set by add FLTAssetsPath to AppFrameworkInfo.plist
  FLTAssetsPath=$(/usr/libexec/PlistBuddy -c "Print :FLTAssetsPath" "${derived_dir}/AppFrameworkInfo.plist" 2>/dev/null)
  if [[ -n "$FLTAssetsPath" ]]; then
    assets_path="${FLTAssetsPath}"
  fi

  # BD ADD:
  # ios lite 版本标记
  local lite_flag=""
  local lite_suffix=""
  if [[  -n "$LITE" ]]; then
      lite_flag="--lite"
      lite_suffix="-lite"
  fi
  if [[  -n "$LITE_GLOBAL" ]]; then
      lite_flag="--lite-global"
      lite_suffix="-liteg"
  fi
  if [[  -n "$LITE_SHARE_SKIA" ]]; then
      lite_flag="--lite-share-skia"
      lite_suffix="-lites"
  fi
  # END

  # Use FLUTTER_BUILD_MODE if it's set, otherwise use the Xcode build configuration name
  # This means that if someone wants to use an Xcode build config other than Debug/Profile/Release,
  # they _must_ set FLUTTER_BUILD_MODE so we know what type of artifact to build.
  local build_mode="$(echo "${FLUTTER_BUILD_MODE:-${CONFIGURATION}}" | tr "[:upper:]" "[:lower:]")"
  local artifact_variant="unknown"
  # BD ADD: START
  if [  "$lite_suffix" == "-lites" -a  "$build_mode" != "release" ]; then
     echo "Current share skia only support for release"
     lite_suffix="-lite"
  fi
  # END
  case "$build_mode" in
    # BD MOD: START
    # *release*) build_mode="release"; artifact_variant="ios-release";;
    # *profile*) build_mode="profile"; artifact_variant="ios-profile";;
    # *debug*) build_mode="debug"; artifact_variant="ios";;
    *release*) build_mode="release"; artifact_variant="ios-release"${lite_suffix};;
    *profile*) build_mode="profile"; artifact_variant="ios-profile";;
    *debug*) build_mode="debug"; artifact_variant="ios";;
    # END
    *)
      EchoError "========================================================================"
      EchoError "ERROR: Unknown FLUTTER_BUILD_MODE: ${build_mode}."
      EchoError "Valid values are 'Debug', 'Profile', or 'Release' (case insensitive)."
      EchoError "This is controlled by the FLUTTER_BUILD_MODE environment variable."
      EchoError "If that is not set, the CONFIGURATION environment variable is used."
      EchoError ""
      EchoError "You can fix this by either adding an appropriately named build"
      EchoError "configuration, or adding an appropriate value for FLUTTER_BUILD_MODE to the"
      EchoError ".xcconfig file for the current build configuration (${CONFIGURATION})."
      EchoError "========================================================================"
      exit -1;;
  esac

  # Archive builds (ACTION=install) should always run in release mode.
  if [[ "$ACTION" == "install" && "$build_mode" != "release" ]]; then
    EchoError "========================================================================"
    EchoError "ERROR: Flutter archive builds must be run in Release mode."
    EchoError ""
    EchoError "To correct, ensure FLUTTER_BUILD_MODE is set to release or run:"
    EchoError "flutter build ios --release"
    EchoError ""
    EchoError "then re-run Archive from Xcode."
    EchoError "========================================================================"
    exit -1
  fi

  # ios拆包方案标示
  local compress_size_flag=""
  if [[  -n "$COMPRESS_SIZE" ]] && [[ "$build_mode" == "release" ]]; then
      compress_size_flag="--compress-size"
  fi

  local framework_path="${FLUTTER_ROOT}/bin/cache/artifacts/engine/${artifact_variant}"

 if [[ "${dynamicart_flag}" == "YES" ]] && ([[ "$build_mode" == "release" ]] || [[ "$build_mode" == "profile" ]]);
 then
 framework_path="${FLUTTER_ROOT}/bin/cache/artifacts/engine/ios-dynamicart-${build_mode}${lite_suffix}"
 else
 framework_path="${FLUTTER_ROOT}/bin/cache/artifacts/engine/${artifact_variant}"
 fi

 if [[ ! -n "$LOCAL_ENGINE" ]];then
   AssertExists "${framework_path}"
 fi

  AssertExists "${project_path}"

  RunCommand mkdir -p -- "$derived_dir"
  AssertExists "$derived_dir"

  RunCommand rm -rf -- "${derived_dir}/App.framework"

  local flutter_engine_flag=""
  local local_engine_flag=""
  local flutter_framework="${framework_path}/Flutter.framework"
  local flutter_podspec="${framework_path}/Flutter.podspec"

  if [[ -n "$FLUTTER_ENGINE" ]]; then
    flutter_engine_flag="--local-engine-src-path=${FLUTTER_ENGINE}"
  fi

  if [[ -n "$LOCAL_ENGINE" ]]; then
    if [[ $(echo "$LOCAL_ENGINE" | tr "[:upper:]" "[:lower:]") != *"$build_mode"* ]]; then
      EchoError "========================================================================"
      EchoError "ERROR: Requested build with Flutter local engine at '${LOCAL_ENGINE}'"
      EchoError "This engine is not compatible with FLUTTER_BUILD_MODE: '${build_mode}'."
      EchoError "You can fix this by updating the LOCAL_ENGINE environment variable, or"
      EchoError "by running:"
      EchoError "  flutter build ios --local-engine=ios_${build_mode}"
      EchoError "or"
      EchoError "  flutter build ios --local-engine=ios_${build_mode}_unopt"
      EchoError "========================================================================"
      exit -1
    fi
    local_engine_flag="--local-engine=${LOCAL_ENGINE}"
    flutter_framework="${FLUTTER_ENGINE}/out/${LOCAL_ENGINE}/Flutter.framework"
    flutter_podspec="${FLUTTER_ENGINE}/out/${LOCAL_ENGINE}/Flutter.podspec"
  fi

  local bitcode_flag=""
  if [[ $ENABLE_BITCODE == "YES" ]]; then
    bitcode_flag="--bitcode"
  fi

  if [[ -e "${project_path}/.ios" ]]; then
    RunCommand rm -rf -- "${derived_dir}/engine"
    mkdir "${derived_dir}/engine"
    RunCommand cp -r -- "${flutter_podspec}" "${derived_dir}/engine"
    RunCommand cp -r -- "${flutter_framework}" "${derived_dir}/engine"
    if [[ "$minimum_size_flag" == "YES" ]]; then
       RunCommand rm -f -- "${derived_dir}/engine/Flutter.framework/icudtl.dat"
    fi
  else
    RunCommand rm -rf -- "${derived_dir}/Flutter.framework"
    RunCommand cp -- "${flutter_podspec}" "${derived_dir}"
    RunCommand cp -r -- "${flutter_framework}" "${derived_dir}"
    if [[ "$minimum_size_flag" == "YES" ]]; then
      RunCommand rm -f -- "${derived_dir}/Flutter.framework/icudtl.dat"
    fi
  fi

  RunCommand pushd "${project_path}" > /dev/null

  AssertExists "${target_path}"

  local verbose_flag=""
  if [[ -n "$VERBOSE_SCRIPT_LOGGING" ]]; then
    verbose_flag="--verbose"
  fi

  local build_dir="${FLUTTER_BUILD_DIR:-build}"

  local track_widget_creation_flag=""
  if [[ -n "$TRACK_WIDGET_CREATION" ]]; then
    track_widget_creation_flag="--track-widget-creation"
  fi

  local dynamic_aot_plugins_command=""
  if [[ "$dynamic_aot_plugins" != "" ]]; then
     dynamic_aot_plugins_command="--dynamic-aot-plugins=${dynamic_aot_plugins}"
  fi
  local dynamicart_command=""
  if [[ "$dynamicart_flag" == "YES" ]]; then
     dynamicart_command="--dynamicart"
  fi


  if [[ "${build_mode}" != "debug" ]]; then
    StreamOutput " ├─Building Dart code..."
    # Transform ARCHS to comma-separated list of target architectures.
    local archs="${ARCHS// /,}"
    if [[ $archs =~ .*i386.* || $archs =~ .*x86_64.* ]]; then
      EchoError "========================================================================"
      EchoError "ERROR: Flutter does not support running in profile or release mode on"
      EchoError "the Simulator (this build was: '$build_mode')."
      EchoError "You can ensure Flutter runs in Debug mode with your host app in release"
      EchoError "mode by setting FLUTTER_BUILD_MODE=debug in the .xcconfig associated"
      EchoError "with the ${CONFIGURATION} build configuration."
      EchoError "========================================================================"
      exit -1
    fi
    StreamOutput " ├─Building Dart code..."
    local minimum_size_command=""
    if [[ "$minimum_size_flag" == "YES" ]] && ([[ "$build_mode" == "release" ]] || [[ "$dynamicart_flag" == "YES" ]]); then
      minimum_size_command="--minimum-size"
    fi
    EchoError "========================================================================${dynamic_aot_plugins_command}"

    RunCommand "${FLUTTER_ROOT}/bin/flutter" --suppress-analytics           \
      ${verbose_flag}                                                       \
      build aot                                                             \
      --output-dir="${build_dir}/aot"                                       \
      --target-platform=ios                                                 \
      --target="${target_path}"                                             \
      --${build_mode}                                                       \
      --ios-arch="${archs}"                                                 \
      ${flutter_engine_flag}                                                \
      ${local_engine_flag}                                                  \
      ${bitcode_flag}                                                       \
      ${dynamicart_command}                                                 \
      ${dynamic_aot_plugins_command}                                        \
      ${minimum_size_command}                                               \
      ${compress_size_flag}                                                 \
      ${lite_flag}

    if [[ $? -ne 0 ]]; then
      EchoError "Failed to build ${project_path}."
      exit -1
    fi
    StreamOutput "done"

    local app_framework="${build_dir}/aot/App.framework"

    RunCommand cp -r -- "${app_framework}" "${derived_dir}"

    if [[ "${build_mode}" == "release" ]]; then
      StreamOutput " ├─Generating dSYM file..."
      # Xcode calls `symbols` during app store upload, which uses Spotlight to
      # find dSYM files for embedded frameworks. When it finds the dSYM file for
      # `App.framework` it throws an error, which aborts the app store upload.
      # To avoid this, we place the dSYM files in a folder ending with ".noindex",
      # which hides it from Spotlight, https://github.com/flutter/flutter/issues/22560.
      RunCommand mkdir -p -- "${build_dir}/dSYMs.noindex"
      RunCommand xcrun dsymutil -o "${build_dir}/dSYMs.noindex/App.framework.dSYM" "${app_framework}/App"
      if [[ $? -ne 0 ]]; then
        EchoError "Failed to generate debug symbols (dSYM) file for ${app_framework}/App."
        exit -1
      fi
      StreamOutput "done"

      StreamOutput " ├─Stripping debug symbols..."
      RunCommand xcrun strip -x -S "${derived_dir}/App.framework/App"
      if [[ $? -ne 0 ]]; then
        EchoError "Failed to strip ${derived_dir}/App.framework/App."
        exit -1
      fi
      StreamOutput "done"
    fi

  else
    RunCommand mkdir -p -- "${derived_dir}/App.framework"

    # Build stub for all requested architectures.
    local arch_flags=""
    read -r -a archs <<< "$ARCHS"
    for arch in "${archs[@]}"; do
      arch_flags="${arch_flags}-arch $arch "
    done

    RunCommand eval "$(echo "static const int Moo = 88;" | xcrun clang -x c \
        ${arch_flags} \
        -fembed-bitcode-marker \
        -dynamiclib \
        -Xlinker -rpath -Xlinker '@executable_path/Frameworks' \
        -Xlinker -rpath -Xlinker '@loader_path/Frameworks' \
        -install_name '@rpath/App.framework/App' \
        -o "${derived_dir}/App.framework/App" -)"
  fi

  local plistPath="${project_path}/ios/Flutter/AppFrameworkInfo.plist"
  if [[ -e "${project_path}/.ios" ]]; then
    plistPath="${project_path}/.ios/Flutter/AppFrameworkInfo.plist"
  fi

  RunCommand cp -- "$plistPath" "${derived_dir}/App.framework/Info.plist"

  local precompilation_flag=""
  if [[ "$CURRENT_ARCH" != "x86_64" ]] && [[ "$build_mode" != "debug" ]]; then
    precompilation_flag="--precompiled"
  fi

  local app_framework_dir="${derived_dir}/App.framework"
  local asset_dir="${app_framework_dir}/${assets_path}"

  StreamOutput " ├─Assembling Flutter resources..."
  RunCommand "${FLUTTER_ROOT}/bin/flutter" --suppress-analytics             \
    ${verbose_flag}                                                         \
    build bundle                                                            \
    --target-platform=ios                                                   \
    --target="${target_path}"                                               \
    --${build_mode}                                                         \
    --depfile="${build_dir}/snapshot_blob.bin.d"                            \
    --asset-dir="${asset_dir}"               \
    ${precompilation_flag}                                                  \
    ${flutter_engine_flag}                                                  \
    ${local_engine_flag}                                                    \
    ${track_widget_creation_flag}                                           \
    ${dynamicart_command}                                                   \
    ${minimum_size_command}                                                 \
    ${lite_flag}

  if [[ $? -ne 0 ]]; then
    EchoError "Failed to package ${project_path}."
    exit -1
  fi

  # BD ADD:START
  if [[ "$minimum_size_flag" == "YES" ]] || [[ "$dynamicart_flag" == "YES" ]]; then
    local host_manifest="${derived_dir}/App.framework/flutter_assets/host_manifest.json"
    if [[ -f "$host_manifest" ]]; then
      RunCommand mv -f --  "${host_manifest}" "${derived_dir}/App.framework/host_manifest.json"
    else
      StreamOutput " ├───host_manifest.json not found at ${host_manifest}"
    fi
  fi

  local dart_bin="${FLUTTER_ROOT}/bin/cache/dart-sdk/bin/dart"
  local dart_path="${FLUTTER_ROOT}/packages/flutter_tools/bin/md5_sum.dart"
  if [[ "$minimum_size_flag" == "YES" ]]; then
    local _archs=(${archs//,/ })
    if [[ -d "${build_dir}/patch/" ]]; then
        RunCommand rm -rf -- "${build_dir}/patch/"
    fi
    for arch in ${_archs[@]}; do
      local path="engine_armv7"
      local engine_md5_file_name="engine_v1"
      if [[ "$arch" == "arm64" ]]; then
        path="engine_arm64"
        engine_md5_file_name="engine_v2"
      fi

      RunCommand mkdir -p -- "${build_dir}/patch/"
      RunCommand mkdir -p -- "${build_dir}/patch/${path}/"
      RunCommand cp -Rv -- "${asset_dir}" "${build_dir}/patch/${path}/${assets_path}"
      RunCommand cp -f --  "${build_dir}/aot/${arch}/isolate_snapshot_data" "${build_dir}/patch/${path}/isolate_snapshot_data"
      RunCommand cp -f --  "${build_dir}/aot/${arch}/vm_snapshot_data" "${build_dir}/patch/${path}/vm_snapshot_data"
      RunCommand cp -f --   "${flutter_framework}/icudtl.dat" "${build_dir}/patch/${path}/icudtl.dat"
      local md5_file="${build_dir}/patch/${path}/${engine_md5_file_name}.txt"
      ${dart_bin} ${dart_path} "${build_dir}/patch/${path}/" > "${md5_file}"
      RunCommand cp --  "${md5_file}" "${derived_dir}/App.framework/${engine_md5_file_name}.txt"
      local current_path=`pwd`
      RunCommand cd ${build_dir}/patch/${path}
      zip -q -r ./../${path}.zip ./*
      RunCommand cd ${current_path}
    done
    RunCommand rm -rf -- "${asset_dir}"
  fi

  if [[ "$compress_size_flag" != "" ]]; then
    RunCommand cp -f -- "${flutter_framework}/icudtl.dat" "${app_framework_dir}/icudtl.dat"
    if [[ -e "${project_path}/.ios" ]]; then
      RunCommand rm -rf -- "${derived_dir}/engine/Flutter.framework/icudtl.dat"
    else
      RunCommand rm -rf -- "${derived_dir}/Flutter.framework/icudtl.dat"
    fi
    local current_path=`pwd`
    RunCommand cd ${app_framework_dir}/
    zip -q -r flutter_compress_icudtl.zip icudtl.dat
    zip -q -r flutter_compress_assets.zip ${assets_path}
    RunCommand rm -f icudtl.dat
    local dirPath=`dirname ${assets_path}`
    if [ "${dirPath}" == "." ];then
      RunCommand rm -rf "${assets_path}"
    else
      RunCommand rm -rf "${dirPath}"
    fi
    RunCommand cd ${current_path}
  fi
  # END

  StreamOutput "done"
  StreamOutput " └─Compiling, linking and signing..."

  RunCommand popd > /dev/null

  echo "Project ${project_path} built and packaged successfully."
  return 0
}

# Returns the CFBundleExecutable for the specified framework directory.
GetFrameworkExecutablePath() {
  local framework_dir="$1"

  local plist_path="${framework_dir}/Info.plist"
  local executable="$(defaults read "${plist_path}" CFBundleExecutable)"
  echo "${framework_dir}/${executable}"
}

# Destructively thins the specified executable file to include only the
# specified architectures.
LipoExecutable() {
  local executable="$1"
  shift
  # Split $@ into an array.
  read -r -a archs <<< "$@"

  # Extract architecture-specific framework executables.
  local all_executables=()
  for arch in "${archs[@]}"; do
    local output="${executable}_${arch}"
    local lipo_info="$(lipo -info "${executable}")"
    if [[ "${lipo_info}" == "Non-fat file:"* ]]; then
      if [[ "${lipo_info}" != *"${arch}" ]]; then
        echo "Non-fat binary ${executable} is not ${arch}. Running lipo -info:"
        echo "${lipo_info}"
        exit 1
      fi
    else
      lipo -output "${output}" -extract "${arch}" "${executable}"
      if [[ $? == 0 ]]; then
        all_executables+=("${output}")
      else
        echo "Failed to extract ${arch} for ${executable}. Running lipo -info:"
        lipo -info "${executable}"
        exit 1
      fi
    fi
  done

  # Generate a merged binary from the architecture-specific executables.
  # Skip this step for non-fat executables.
  if [[ ${#all_executables[@]} > 0 ]]; then
    local merged="${executable}_merged"
    lipo -output "${merged}" -create "${all_executables[@]}"

    cp -f -- "${merged}" "${executable}" > /dev/null
    rm -f -- "${merged}" "${all_executables[@]}"
  fi
}

# Destructively thins the specified framework to include only the specified
# architectures.
ThinFramework() {
  local framework_dir="$1"
  shift

  local plist_path="${framework_dir}/Info.plist"
  local executable="$(GetFrameworkExecutablePath "${framework_dir}")"
  LipoExecutable "${executable}" "$@"
}

ThinAppFrameworks() {
  local app_path="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
  local frameworks_dir="${app_path}/Frameworks"

  [[ -d "$frameworks_dir" ]] || return 0
  find "${app_path}" -type d -name "*.framework" | while read framework_dir; do
    ThinFramework "$framework_dir" "$ARCHS"
  done
}

# Adds the App.framework as an embedded binary and the flutter_assets as
# resources.
EmbedFlutterFrameworks() {
  AssertExists "${FLUTTER_APPLICATION_PATH}"

  # Prefer the hidden .ios folder, but fallback to a visible ios folder if .ios
  # doesn't exist.
  local flutter_ios_out_folder="${FLUTTER_APPLICATION_PATH}/.ios/Flutter"
  local flutter_ios_engine_folder="${FLUTTER_APPLICATION_PATH}/.ios/Flutter/engine"
  if [[ ! -d ${flutter_ios_out_folder} ]]; then
    flutter_ios_out_folder="${FLUTTER_APPLICATION_PATH}/ios/Flutter"
    flutter_ios_engine_folder="${FLUTTER_APPLICATION_PATH}/ios/Flutter"
  fi

  AssertExists "${flutter_ios_out_folder}"

  # Embed App.framework from Flutter into the app (after creating the Frameworks directory
  # if it doesn't already exist).
  local xcode_frameworks_dir=${BUILT_PRODUCTS_DIR}"/"${PRODUCT_NAME}".app/Frameworks"
  RunCommand mkdir -p -- "${xcode_frameworks_dir}"
  RunCommand cp -Rv -- "${flutter_ios_out_folder}/App.framework" "${xcode_frameworks_dir}"

  # Embed the actual Flutter.framework that the Flutter app expects to run against,
  # which could be a local build or an arch/type specific build.
  # Remove it first since Xcode might be trying to hold some of these files - this way we're
  # sure to get a clean copy.
  RunCommand rm -rf -- "${xcode_frameworks_dir}/Flutter.framework"
  RunCommand cp -Rv -- "${flutter_ios_engine_folder}/Flutter.framework" "${xcode_frameworks_dir}/"

  # Sign the binaries we moved.
  local identity="${EXPANDED_CODE_SIGN_IDENTITY_NAME:-$CODE_SIGN_IDENTITY}"
  if [[ -n "$identity" && "$identity" != "\"\"" ]]; then
    RunCommand codesign --force --verbose --sign "${identity}" -- "${xcode_frameworks_dir}/App.framework/App"
    RunCommand codesign --force --verbose --sign "${identity}" -- "${xcode_frameworks_dir}/Flutter.framework/Flutter"
  fi
}

# Main entry point.

# TODO(cbracken): improve error handling, then enable set -e

if [[ $# == 0 ]]; then
  # Backwards-compatibility: if no args are provided, build.
  BuildApp
else
  case $1 in
    "build")
      BuildApp ;;
    "thin")
      ThinAppFrameworks ;;
    "embed")
      EmbedFlutterFrameworks ;;
  esac
fi
