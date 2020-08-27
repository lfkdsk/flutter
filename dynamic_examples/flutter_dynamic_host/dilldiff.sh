#!/usr/bin/env bash

if [[ -d "flutter" ]];then
    rm -rf flutter
fi
pwd
git clone git@code.byted.org:tech_client/flutter.git
cd flutter
echo "$BRANCH"
git checkout -b ${BRANCH} origin/${BRANCH}
cd ..
pwd
export PATH=`pwd`/flutter/bin:$PATH
export PUB_HOSTED_URL=http://dart-pub.byted.org
directory=`pwd`

if [[ -d "hello" ]];then
  rm -rf hello
fi

flutter create  hello
cd hello
cd lib
echo "void main(){}"> main.dart
cd ..

flutter clean

flutter build aot --release --dynamicart
cd .dart_tool/flutter_build/
dir=`ls`
cd "${dir}"

if [[ -f "result.json" ]];then
    result_md5=`md5 result.json`
    hello_dir=`pwd`
    cd "${directory}/flutter/bin/internal"
    previous_md5=''
    if [[ -f "result.json" ]];then
      previous_md5=`md5 result.json`
    fi
    echo "${previous_md5}"
    echo "${result_md5}"
    pwd

    if [[ "$result_md5" != "$previous_md5" ]];then
       for line in `cat dynamicart.version`
       do
         array=(${line//./ })
         echo "${array[@]}"
         array_name=${array[@]}

         major_version=${array[0]}
         minor_version=${array[1]}
         min_version=${array[2]}
         next_minor_version=$((10#${minor_version}+1))
         version="${major_version}.${next_minor_version}.${min_version}"
         if [[ -f "dynamicart.version" ]];then
          rm -rf dynamicart.version
         fi
         echo "${version}"
         echo "${version}">>dynamicart.version
         if [[ -f "app.dill" ]];then
         rm -rf app.dill
         fi
         if [[ -f "result.json" ]];then
           rm -rf result.json
         fi
         cp ${hello_dir}/result.json result.json
         cp ${hello_dir}/app.dill app.dill
         git add result.json
         git add app.dill
         git add dynamicart.version
         git commit -m"CI Auto build app.dill"
         git push origin ${BRANCH}:${BRANCH}
       done
    fi
else
    hello_dir=`pwd`
    ${directory}/flutter/bin/cache/dart-sdk/bin/dart ${directory}/flutter/bin/internal/dilldiff.snapshot --old-dill-path=${directory}/flutter/bin/internal/app.dill --new-dill-path=${hello_dir}/app.dill
    res=$?
    echo ${res}
    cd "${directory}/flutter/bin/internal"
    if [[ ${res} != 0 ]];then
       for line in `cat dynamicart.version`
       do
         array=(${line//./ })
         echo "${array[@]}"
         array_name=${array[@]}

         major_version=${array[0]}
         minor_version=${array[1]}
         min_version=${array[2]}

         if [[ ${res} == 1 ]];then
            next_patch_version=$((10#${min_version}+1))
            version="${major_version}.${minor_version}.${next_patch_version}"
         fi

         if [[ ${res} == 2 ]];then
            next_minor_version=$((10#${minor_version}+1))
            version="${major_version}.${next_minor_version}.${min_version}"
         fi

         if [[ ${res} == 3 ]] || [[ ${res} == 4 ]];then
            next_major_version=$((10#${major_version}+1))
            version="${next_major_version}.${minor_version}.${min_version}"
         fi

         if [[ -f "dynamicart.version" ]];then
            rm -rf dynamicart.version
         fi
         echo "${version}"
         echo "${version}">>dynamicart.version

         if [[ -f "app.dill" ]];then
            rm -rf app.dill
         fi

         if [[ -f "result.json" ]];then
            rm -rf result.json
         fi

         cp ${hello_dir}/app.dill app.dill

         git add app.dill
         git add dynamicart.version
         git commit -m"CI Auto build app.dill"
         git push origin ${BRANCH}:${BRANCH}
       done
    fi
fi





