function UploadAppFrameworkDsymLog() {
  echo "UploadAppFrameworkDsymLog: $@"
}

function UploadAppFrameworkDsym() {
	if [ ! -n "$2" ] ;then
    	UploadAppFrameworkDsymLog "Please input your app id"
    	exit -1
	fi

	local build_mode="$(echo "${FLUTTER_BUILD_MODE:-${CONFIGURATION}}" | tr "[:upper:]" "[:lower:]")"
  	local artifact_variant="unknown"
  	case "$build_mode" in
    	*release*) build_mode="release"; artifact_variant="ios-release";;
    	*profile*) build_mode="profile"; artifact_variant="ios-profile";;
    	*debug*) build_mode="debug"; artifact_variant="ios";;
    	*)build_mode="debug";UploadAppFrameworkDsymLog "Please config build_mode";;
  	esac

  	if [[ "${build_mode}" == "debug" ]]; then
  		UploadAppFrameworkDsymLog "Debug mode doesn't need upload"
  		return
  	fi

	local aid=$2

	local project_path="${SOURCE_ROOT}/.."
  	if [[ -n "$FLUTTER_APPLICATION_PATH" ]]; then
    	project_path="${FLUTTER_APPLICATION_PATH}"
  	fi
	pushd "${project_path}"

	local build_dir=${FLUTTER_BUILD_DIR:-build}
	local dSYMPath=$(pwd)/${build_dir}/dSYMs.noindex

	if [[ -d $dSYMPath ]]
	then
		cd $dSYMPath
		local dSYMInfoPlistPath="${FLUTTER_ROOT}/packages/flutter_tools/bin/Info.plist"
		cp ${dSYMInfoPlistPath} App.framework.dSYM/Contents/Info.plist

		if [ -e App.framework.dSYM.zip ] 
		then
			rm -rf App.framework.dSYM.zip
		fi

		zip -rq App.framework.dSYM.zip App.framework.dSYM
	
		UploadAppFrameworkDsymLog "Start upload dSYM to HMD server"
		STATUS=$(curl "http://symbolicate.byted.org/slardar_ios_upload" -F "file=@App.framework.dSYM.zip" -F "aid=${aid}" -H "Content-Type: multipart/form-data" -w %{http_code} -v)
		UploadAppFrameworkDsymLog "HMD server response: ${STATUS}"

		cd -
	else
		UploadAppFrameworkDsymLog 'App framework dsym path is empty'
	fi
	popd
}

if [[ $# == 0 ]] 
then
	echo "Bytedance_backend ERROR: Command is empty"
else
  case $1 in
    "uploadAppFrameworkDsym")
      UploadAppFrameworkDsym $@;;
    *)
	echo "Bytedance_backend ERROR: Unknown Command"
  esac
fi
