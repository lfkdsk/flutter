# 生成flutter_gallery example的bytecode的工程

命令行直接生成app.dill
/Users/limengyun/work/software/flutter/bin/cache/dart-sdk/bin/dart  /Users/limengyun/work/repos/engine/src/flutter/frontend_server/bin/starter.dart --sdk-root /Users/limengyun/work/repos/engine/src/out/ios_release_unopt/flutter_patched_sdk/ --strong --target=flutter --no-link-platform --bytecode --packages /Users/limengyun/work/software/flutter/dynamic_examples/flutter_gallery_bytecode/.packages --output-dill ./app.dill --depfile ./snapshot_blob.bin.d --filesystem-scheme org-dartlang-root package:flutter_gallery_bytecode/main.dart
