# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

### [1.12.13-dynamicart-46](https://code.byted.org/tech_client/flutter/compare/bd1.12.13-4...bd1.12.13-dynamicart-46) (2020-11-20)


### Bug Fixes

* 外部注入list帮助FpsKey判断 ([ad19870](https://code.byted.org/tech_client/flutter/commit/ad19870))
* 修复脚本报错 ([8150f1b](https://code.byted.org/tech_client/flutter/commit/8150f1b))
* 修复用户杀进程时icu umutex崩溃问题 ([80a5687](https://code.byted.org/tech_client/flutter/commit/80a5687))
* app dill runner error ([c8e3bcb](https://code.byted.org/tech_client/flutter/commit/c8e3bcb))
* Correct first frame build event word error (BD[#1001](https://jira.bytedance.com/browse/1001)) ([c961aad](https://code.byted.org/tech_client/flutter/commit/c961aad))
* disable check dart http in dynamicart mode ([4d2be70](https://code.byted.org/tech_client/flutter/commit/4d2be70))
* exit when build bundle failed ([ebc42fe](https://code.byted.org/tech_client/flutter/commit/ebc42fe))
* fix android native image callback error ([b1509a5](https://code.byted.org/tech_client/flutter/commit/b1509a5))
* Fix get dynmicart tag error ([b386ace](https://code.byted.org/tech_client/flutter/commit/b386ace))
* move skip frame to  _handleBeginFrame func ([811aaf4](https://code.byted.org/tech_client/flutter/commit/811aaf4))
* Reland "Do not rebuild Routes when a new opaque Route is pushed on top" ([#49376](https://jira.bytedance.com/browse/49376)) ([b9ac304](https://code.byted.org/tech_client/flutter/commit/b9ac304))
* Roll engine 770f65f4a3f8587fa81916b2b33afb480780bf09 to 1ec5eba1fd74b21f72dd154143bf7360eddf6726 ([6ffbda2](https://code.byted.org/tech_client/flutter/commit/6ffbda2))
* Roll engine to 3f72ba81cd7e631e4ec5f18466abbcc2b3fe4c18 ([9a6fe0b](https://code.byted.org/tech_client/flutter/commit/9a6fe0b))
* Roll engine to 43455845d4a843d685320c9057a664b8167d3452 ([cacbd7a](https://code.byted.org/tech_client/flutter/commit/cacbd7a))
* roll engine to 56f76c648fdf5642156540b5a15d6b79aad49e4c ([7b643f4](https://code.byted.org/tech_client/flutter/commit/7b643f4))
* roll engine to 64ff10125d68aebafbcf0662743b9c58c5342122,enable soft_rendering ([c5350d8](https://code.byted.org/tech_client/flutter/commit/c5350d8))
* Roll engine to 770f65f4a3f8587fa81916b2b33afb480780bf09 ([72db0d4](https://code.byted.org/tech_client/flutter/commit/72db0d4))
* roll engine to b96cf8fd10763d43bc5a1e2d2df07715b458aec6 ([fc4b920](https://code.byted.org/tech_client/flutter/commit/fc4b920))
* roll engine to bce929641df947a0dd29aa668b67766ecf445deb ([95e6ba9](https://code.byted.org/tech_client/flutter/commit/95e6ba9))
* roll engine to bf589de635c72f560debf203283b9e5ac6ec66f5 ([4a32db5](https://code.byted.org/tech_client/flutter/commit/4a32db5)), closes [BD#2009](https://jira.bytedance.com/browse/2009) [BD#2008](https://jira.bytedance.com/browse/2008)
* roll engine to c2f08d0045ffc070cc9adc341e3c530dda207fc8 ([b3d65a7](https://code.byted.org/tech_client/flutter/commit/b3d65a7)), closes [BD#2010](https://jira.bytedance.com/browse/2010)
* Roll engine to dc222c175b39b35c2d8216833a663b32e7ddadaf ([e929dfe](https://code.byted.org/tech_client/flutter/commit/e929dfe))
* Roll engine to efdc623c2f4e7d86cad3e92b7ceb18354d1fc787 ([6366d97](https://code.byted.org/tech_client/flutter/commit/6366d97))
* Roll engine to f5a518478e1b59a3f0f2334aa57e487c61f0f0a0 ([14c8932](https://code.byted.org/tech_client/flutter/commit/14c8932))
* Thread stack leak ([50b6817](https://code.byted.org/tech_client/flutter/commit/50b6817))
* Thread stack leak ([204b152](https://code.byted.org/tech_client/flutter/commit/204b152))
* Update video quality, Roll engine to 7cb083af782483e7610e70dc24323a5e038feb83 ([58c9d59](https://code.byted.org/tech_client/flutter/commit/58c9d59))


### Features

* 保证调试模式下也能监听到异常 ([201b451](https://code.byted.org/tech_client/flutter/commit/201b451))
* 增加push动态包逻辑 ([439b1a3](https://code.byted.org/tech_client/flutter/commit/439b1a3))
* Add drawframe cost time callback ([6053c90](https://code.byted.org/tech_client/flutter/commit/6053c90))
* add new native image interface ([42196a6](https://code.byted.org/tech_client/flutter/commit/42196a6))
* Add switch in boost to disable mipmaps to save 1/4 GPU memory, used by image ([7c5d729](https://code.byted.org/tech_client/flutter/commit/7c5d729))
* close dynamic hook. ([474950e](https://code.byted.org/tech_client/flutter/commit/474950e))
* compute memory size of images referenced by Dart ([b04ca1b](https://code.byted.org/tech_client/flutter/commit/b04ca1b))
* fix typo ([c82634b](https://code.byted.org/tech_client/flutter/commit/c82634b))
* Increase thread priority before engine initialization ([6de71ba](https://code.byted.org/tech_client/flutter/commit/6de71ba))
* Plugin Android支持subproject ([f3b6326](https://code.byted.org/tech_client/flutter/commit/f3b6326))
* roll engine to 02557cef7485519d33aae462879a32c11ffe02fd ([331cb94](https://code.byted.org/tech_client/flutter/commit/331cb94))
* Roll engine to 123a148d5f5b4b385a559883119f5fc3b9c117b8 ([adefeae](https://code.byted.org/tech_client/flutter/commit/adefeae))
* Roll engine to 34e6bb3c5aef6635946104e4099b6b78cc59a445 ([f47c7cc](https://code.byted.org/tech_client/flutter/commit/f47c7cc))
* roll engine to 68386f5999721d771e68d942a354e7d24c333235:dynamic debug ([e296f3a](https://code.byted.org/tech_client/flutter/commit/e296f3a))
* Roll engine to 72f66e0891a10b20b9fce20f8929081d303e62d4 ([8d5da01](https://code.byted.org/tech_client/flutter/commit/8d5da01))
* Roll engine to d2d9225c18868d5e5bdc0fa5f705dfee0bee9554 ([99a5f59](https://code.byted.org/tech_client/flutter/commit/99a5f59))
* Roll engine to daed78bc2af9994a2422dba7e9320711658004ba ([771bb6b](https://code.byted.org/tech_client/flutter/commit/771bb6b))
* Skip frame when window size is 0 ([c1c4626](https://code.byted.org/tech_client/flutter/commit/c1c4626))
* support always Skip Frame When Size IsZero ([c19427b](https://code.byted.org/tech_client/flutter/commit/c19427b))
* support getting DartVM heap usage information from performance.dart ([2eb0e79](https://code.byted.org/tech_client/flutter/commit/2eb0e79))
* support lite-share-skia mode for dynamicart ([e399bbc](https://code.byted.org/tech_client/flutter/commit/e399bbc))
* support native gif decode & yuv420 ([a9ac2b0](https://code.byted.org/tech_client/flutter/commit/a9ac2b0))
* udpate insert tfa. ([5f55f2a](https://code.byted.org/tech_client/flutter/commit/5f55f2a))
* update dynamic hook support. ([237b7b6](https://code.byted.org/tech_client/flutter/commit/237b7b6))
* upload files after build apk for mix_project debug ([06bf3b1](https://code.byted.org/tech_client/flutter/commit/06bf3b1))

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
