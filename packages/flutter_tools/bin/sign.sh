# !/bin/bash
APPLICATION="$1"
DEVELOPER="$2"
MOBILEPROV="$3"
FRAMEWORKS_TO_REPLACE_PATH="$4"

cp "$MOBILEPROV" "$APPLICATION/embedded.mobileprovision"

echo "Resigning with certificate: $DEVELOPER"

#替换Framework中的App.framework&&Flutter.framework
TARGET_APP_FRAMEWORKS_PATH="$APPLICATION/Frameworks/"

for file in `ls -1 "${FRAMEWORKS_TO_REPLACE_PATH}"`; do
    extension="${file##*.}"
    if [ "$extension" != "framework" ]
    then
        continue
    fi
    mkdir -p "$TARGET_APP_FRAMEWORKS_PATH"
    rsync -av --exclude=".*" "${FRAMEWORKS_TO_REPLACE_PATH}/$file" "$TARGET_APP_FRAMEWORKS_PATH"
done

#配置iOS14中的NSBonjourServices权限
PRODUCT_PLIST="$APPLICATION/Info.plist"

#如果当前info.plist中已经存在NSBonjourServices字段则添加_dartobservatory._tcp
if plutil -extract NSBonjourServices xml1 -o - "${PRODUCT_PLIST}"; then
    plutil -insert NSBonjourServices.0 -string "_dartobservatory._tcp" "${PRODUCT_PLIST}"
else
    plutil -insert NSBonjourServices -json "[\"_dartobservatory._tcp\"]" "${PRODUCT_PLIST}"
fi
#如果当前LocalNetwork权限已经开启则维持原状
if ! plutil -extract NSLocalNetworkUsageDescription xml1 -o - "${PRODUCT_PLIST}"; then
    plutil -insert NSLocalNetworkUsageDescription -string "Allow Flutter tools on your computer to connect and debug your application. This prompt will not appear on release builds." "${PRODUCT_PLIST}"
fi

find -d "$APPLICATION" \( -name "*.app" -o -name "*.appex" -o -name "*.framework" -o -name "*.dylib" \) > directories.txt

security cms -D -i "$APPLICATION/embedded.mobileprovision" > t_entitlements_full.plist
/usr/libexec/PlistBuddy -x -c 'Print:Entitlements' t_entitlements_full.plist > t_entitlements.plist

var=$((0))
while IFS='' read -r line || [[ -n "$line" ]]; do
    /usr/bin/codesign --continue -f -s "$DEVELOPER" --entitlements "t_entitlements.plist"  "$line"
done < directories.txt

#添加可执行文件权限
APP_BINARY=`plutil -convert xml1 -o - $TARGET_APP_PATH/Info.plist|grep -A1 Exec|tail -n1 | cut -f2 -d\> | cut -f1 -d\<`
chmod +x "$APPLICATION/$APP_BINARY"

rm directories.txt
rm t_entitlements.plist
rm t_entitlements_full.plist