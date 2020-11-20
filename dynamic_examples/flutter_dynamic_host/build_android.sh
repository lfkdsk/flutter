/Users/zhaoxuyang/Documents/flutter/bin/flutter clean
/Users/zhaoxuyang/Documents/flutter/bin/flutter build apk --release --dynamicart --local-engine-src-path /Users/zhaoxuyang/Documents/engine/src --local-engine=android_release_unopt_dynamicart --target-platform=android-arm
adb install -r  build/app/outputs/apk/dynamicartRelease/app-dynamicartRelease.apk
