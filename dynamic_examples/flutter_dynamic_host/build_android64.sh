/Users/zhaoxuyang/Documents/flutter_tt/bin/flutter clean
/Users/zhaoxuyang/Documents/flutter_tt/bin/flutter build apk --release --dynamicart --local-engine-src-path /Users/zhaoxuyang/Documents/engine-v1.5.4/src --local-engine=android_release_unopt_arm64_dynamicart --target-platform=android-arm64
adb install -r  build/app/outputs/apk/dynamicartRelease/app-dynamicartRelease.apk
