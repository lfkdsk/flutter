# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

### [1.20.1-3](https://code.byted.org/tech_client/flutter/compare/bd1.20.1-2...bd1.20.1-3) (2020-09-20)


### Bug Fixes

* fix build aar failed issue (BD [#56](https://jira.bytedance.com/browse/56)) ([a57ce05](https://code.byted.org/tech_client/flutter/commit/a57ce05))


### Features

* **android:** support projects dependency third-party library directly (BD [#69](https://jira.bytedance.com/browse/69)) ([4146931](https://code.byted.org/tech_client/flutter/commit/4146931))
* add new native image interface (BD [#68](https://jira.bytedance.com/browse/68)) ([1e572aa](https://code.byted.org/tech_client/flutter/commit/1e572aa))
* update codes from flutter 1.20.1 to 1.20.4

### [1.12.13-4](https://code.byted.org/tech_client/flutter/compare/bd1.12.13-3...bd1.12.13-4) (2020-04-21)


### Bug Fixes

* 修复用户杀进程时icu umutex崩溃问题 ([9f26a51](https://code.byted.org/tech_client/flutter/commit/9f26a51))
* revert PR #34474,防止release模式下不显示异常信息 ([72949cb](https://code.byted.org/tech_client/flutter/commit/72949cb))


### Features

* flutter build/run 新增了 --bundler 参数来执行 bundle exec pod install ([32613f0](https://code.byted.org/tech_client/flutter/commit/32613f0))

### [1.12.13-3](https://code.byted.org/tech_client/flutter/compare/bd1.12.13-2...bd1.12.13-3) (2020-03-27)


### Bug Fixes

* 同步154引擎稳定性相关改动 ([7a433d7](https://code.byted.org/tech_client/flutter/commit/7a433d7))

### [1.12.13-2](https://code.byted.org/tech_client/flutter/compare/bd1.12.13-1...bd1.12.13-2) (2020-03-27)


### Bug Fixes

* **android:** roll engine to a5378b27ff3deec9ac98e0892785d21086f5a7fb:去除jar包目录中的cid ([10279ad](https://code.byted.org/tech_client/flutter/commit/10279ad))


### Features

* lite and lite-global only support for release mode ([fab5c83](https://code.byted.org/tech_client/flutter/commit/fab5c83))

### [1.5.4-8](https://code.byted.org/tech_client/flutter/compare/bd1.5.4-7...bd1.5.4-8) (2020-01-20)


### Bug Fixes

* **ios:** fix build ios command error with track-widget-creation ([8bd25ef](https://code.byted.org/tech_client/flutter/commit/8bd25ef))

### [1.5.4-7](https://code.byted.org/tech_client/flutter/compare/bd1.5.4-6...bd1.5.4-7) (2020-01-07)


### Features

* 文字支持异步布局以及iOS线程QoS优化 ([e518696](https://code.byted.org/tech_client/flutter/commit/e518696))

### [1.5.4-6](https://code.byted.org/tech_client/flutter/compare/bd1.5.4-2...bd1.5.4-6) (2020-01-05)


### Bug Fixes

* fix fps draw_lock lock failed ([670be4b](https://code.byted.org/tech_client/flutter/commit/670be4b))

### [1.5.4-5](https://code.byted.org/tech_client/flutter/compare/bd1.5.4-4...bd1.5.4-5) (2019-12-24)


### Bug Fixes

* 低内存时偶现空指针 ([d1ec83f](https://code.byted.org/tech_client/flutter/commit/d1ec83f))
* 在 TestWindow 添加 onNotifyIdle 接口 ([08264c3](https://code.byted.org/tech_client/flutter/commit/08264c3))
* fix replace string exception ([ae2b560](https://code.byted.org/tech_client/flutter/commit/ae2b560))
* fix report bug ([1f185c4](https://code.byted.org/tech_client/flutter/commit/1f185c4))
* fix report bug ([3197478](https://code.byted.org/tech_client/flutter/commit/3197478))
* flutter drive failed. ([ec41e74](https://code.byted.org/tech_client/flutter/commit/ec41e74))
* flutter sdk version and engine product version are inconsistent ([36ecda5](https://code.byted.org/tech_client/flutter/commit/36ecda5))


### Features

* add benchmark scrips ([f4e39ae](https://code.byted.org/tech_client/flutter/commit/f4e39ae))
* Make it easier to pass local engine flags when running devicelab tests ([1c2c325](https://code.byted.org/tech_client/flutter/commit/1c2c325))

### [1.5.4-4](https://code.byted.org/tech_client/flutter/compare/bd1.5.4-3...bd1.5.4-4) (2019-11-27)


### Bug Fixes

* 修复iOS后台渲染图片调用OpenGL导致的崩溃 ([c259490](https://code.byted.org/tech_client/flutter/commit/c259490)), closes [#FLUTTER-247](https://jira.bytedance.com/browse/FLUTTER-247)


### Features

* support report build info ([b7d2d13](https://code.byted.org/tech_client/flutter/commit/b7d2d13))

### [1.5.4-3](https://code.byted.org/tech_client/flutter/compare/bd1.5.4-2...bd1.5.4-3) (2019-11-22)


### Features

* 内置压缩策略优化，新增内存解压兜底，统一解压相关error domain和error code ([cb0a562](https://code.byted.org/tech_client/flutter/commit/cb0a562)), closes [#FLUTTER-305](https://jira.bytedance.com/browse/FLUTTER-305)

### [1.5.4-2](https://code.byted.org/tech_client/flutter/compare/bd1.5.4-1...bd1.5.4-2) (2019-11-12)


### Features

* 压缩模式新增接口 ([d7173f3](https://code.byted.org/tech_client/flutter/commit/d7173f3))

### 1.5.4-1 (2019-11-06)


### Bug Fixes

* 修复压缩模式偶现的卡死和野指针问题 ([c6daf74](https://code.byted.org/tech_client/flutter/commit/c6daf74)), closes [#FLUTTER-300](https://jira.bytedance.com/browse/FLUTTER-300) [#FLUTTER-301](https://jira.bytedance.com/browse/FLUTTER-301)


### Features

* 低内存时进行VM和图片缓存清理 ([1a879b1](https://code.byted.org/tech_client/flutter/commit/1a879b1)), closes [#FLUTTER-220](https://jira.bytedance.com/browse/FLUTTER-220)
