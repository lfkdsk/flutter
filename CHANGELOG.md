# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

### [1.12.13-12](https://code.byted.org/tech_client/flutter/compare/bd1.12.13-11...bd1.12.13-12) (2020-07-20)


### Bug Fixes

* Fix checkInputConnectionProxy NPE (BD#2008) ([f52f94b](https://code.byted.org/tech_client/flutter/commit/f52f94b))
* Fix create platform_views crash, when activity finishing. (BD#2009) ([f52f94b](https://code.byted.org/tech_client/flutter/commit/f52f94b))
* Fix naitve image decode crash when complete block is called ([f52f94b](https://code.byted.org/tech_client/flutter/commit/f52f94b))
* Made the Rasterizer avoid GPU calls when backgrounded (#18563) ([f52f94b](https://code.byted.org/tech_client/flutter/commit/f52f94b))
* Fix: Poor video scaling quality #53080 (#18814) ([44b6ad5](https://code.byted.org/tech_client/flutter/commit/44b6ad5))
* Fix: change image size, while disable mips (BD#2006) ([44b6ad5](https://code.byted.org/tech_client/flutter/commit/44b6ad5))
* Fix artifacts not download. ([7c37117](https://code.byted.org/tech_client/flutter/commit/7c37117))
* **flutter_tools:** [DO NOT MERGE] Don't import plugins that don't support android ([f0b786a](https://code.byted.org/tech_client/flutter/commit/f0b786a))
* **flutter_tools:** add transformers change ([da61ace](https://code.byted.org/tech_client/flutter/commit/da61ace))
* Roll Engine to a682f2407feb58ccfe919d19918a0c7e94c64c10 (BD[#1004](https://jira.bytedance.com/browse/1004)) ([44b6ad5](https://code.byted.org/tech_client/flutter/commit/44b6ad5)), closes [BD#2005](https://jira.bytedance.com/browse/2005) [BD#2006](https://jira.bytedance.com/browse/2006) [#53080](https://jira.bytedance.com/browse/53080) [#18814](https://jira.bytedance.com/browse/18814)
* **flutter_tools:** fix aot build trans path ([2e78fe4](https://code.byted.org/tech_client/flutter/commit/2e78fe4))


### Features

* **trans_support:** not check dart sha ([93f0bfa](https://code.byted.org/tech_client/flutter/commit/93f0bfa))

### [1.12.13-11](https://code.byted.org/tech_client/flutter/compare/bd1.12.13-10...bd1.12.13-11) (2020-06-22)

### Bug Fixes
* Fix: define timeline event func as null in release mode (BD#2004) ([bf65af2](https://code.byted.org/tech_client/flutter/commit/bf65af2))

### Features
* ImageLoaderRegistry support ShimRegistrar.java ([bf65af2](https://code.byted.org/tech_client/flutter/commit/bf65af2))
* Support preload DartVM and FontMgr ([bf65af2](https://code.byted.org/tech_client/flutter/commit/bf65af2))

### [1.12.13-10](https://code.byted.org/tech_client/flutter/compare/bd1.12.13-9...bd1.12.13-10) (2020-06-18)


### Bug Fixes

* fix RawKeyboard._synchronizeModifiers npe ([f9cbb9c](https://code.byted.org/tech_client/flutter/commit/f9cbb9c))

### [1.12.13-9](https://code.byted.org/tech_client/flutter/compare/bd1.12.13-8...bd1.12.13-9) (2020-06-17)


### Bug Fixes

* Correct first frame build event word error (BD[#1001](https://jira.bytedance.com/browse/1001)) ([7203c55](https://code.byted.org/tech_client/flutter/commit/7203c55))
* Optimize bd_image thread model  ([6f4b81f](https://code.byted.org/tech_client/flutter/commit/6f4b81f)


### Features

### [1.12.13-8](https://code.byted.org/tech_client/flutter/compare/bd1.12.13-7...bd1.12.13-8) (2020-06-09)


### Bug Fixes

* fix sliver list assert error ([d814dc3](https://code.byted.org/tech_client/flutter/commit/d814dc3))
* native image callback error ([06d1bc4](https://code.byted.org/tech_client/flutter/commit/06d1bc4))


### Features

* Update transformer hooks in CHANGELOG.md ([6c693cf](https://code.byted.org/tech_client/flutter/commit/6c693cf))

### [1.12.13-7](https://code.byted.org/tech_client/flutter/compare/bd1.12.13-6...bd1.12.13-7) (2020-06-07)


### Bug Fixes

* cherry-pick native image ([d32c488](https://code.byted.org/tech_client/flutter/commit/d32c488))
* roll engine to 8c7eb4dba48aa1ec582119a9b180afe8aa715c83:fix call thread ([ea123b3](https://code.byted.org/tech_client/flutter/commit/ea123b3))


### Features

* Add warning log in image_cache ([817ea95](https://code.byted.org/tech_client/flutter/commit/817ea95))
* print image w & h info in ImageCache ([0856848](https://code.byted.org/tech_client/flutter/commit/0856848))
* Add Flutter Transformer Hooks ([65039a17](https://code.byted.org/tech_client/flutter/commit/65039a17)，[transformer-template](https://code.byted.org/tech_client/transformers-template))

### [1.12.13-6](https://code.byted.org/tech_client/flutter/compare/bd1.12.13-4...bd1.12.13-6) (2020-05-27)


### Bug Fixes

* Reland "Do not rebuild Routes when a new opaque Route is pushed on top" ([#49376](https://jira.bytedance.com/browse/49376)) ([b9ac304](https://code.byted.org/tech_client/flutter/commit/b9ac304))
* roll engine to 64ff10125d68aebafbcf0662743b9c58c5342122,enable soft_rendering ([c5350d8](https://code.byted.org/tech_client/flutter/commit/c5350d8))
* 修复脚本报错 ([8150f1b](https://code.byted.org/tech_client/flutter/commit/8150f1b))


### Features

* roll engine to f9d455ff8673f0c55d75dbca87ef178395eda1a7 ([e16ad29](https://code.byted.org/tech_client/flutter/commit/e16ad29))

### [1.12.13-5](https://code.byted.org/tech_client/flutter/compare/bd1.12.13-4...bd1.12.13-5) (2020-05-19)


### Bug Fixes

* Reland "Do not rebuild Routes when a new opaque Route is pushed on top" ([#49376](https://jira.bytedance.com/browse/49376)) ([b9ac304](https://code.byted.org/tech_client/flutter/commit/b9ac304))
* enable soft_rendering ([c5350d8](https://code.byted.org/tech_client/flutter/commit/c5350d8))
* 修复脚本报错 ([8150f1b](https://code.byted.org/tech_client/flutter/commit/8150f1b))
* Cleanup the IO thread GrContext ([e16ad29](https://code.byted.org/tech_client/flutter/commit/e16ad29))


### Features

* Add switch in boost to disable mipmaps to save 1/4 GPU memory, used by image ([e16ad29](https://code.byted.org/tech_client/flutter/commit/e16ad29))
* 添加后台渲染能力 ([e16ad29](https://code.byted.org/tech_client/flutter/commit/e16ad29))

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
