# CLAUDE.md — lingshu/（灵枢 App 模块文档）

> 面包屑：[← 工作区根 CLAUDE.md](../CLAUDE.md) · 模块：`lingshu/`（Flutter 应用）
> 本文档内所有路径均相对 `lingshu/`。

## 项目定位

「灵枢」— 阴阳五行 × 中医 个人/家庭健康管理 App（`pubspec.yaml`：`version: 0.1.36+9905`，SDK `^3.13.3`）。中文界面（`locale: zh_CN`），数据本地加密存储（Drift + SQLCipher），AI 识别走用户自配置的 OpenAI 兼容视觉大模型（默认 `glm-4v-flash`）。品牌钤记「磨沙客 · MOSAIC」。

## 应用入口与路由

- **入口 `lib/main.dart`**：初始化 SharedPreferences → 构建 `ProviderContainer`（override `sharedPreferencesProvider`）→ 预加载静态内容（`contentProvider.load()`）→ 启动时全量重排用药提醒与药箱到期提醒通知（`_rescheduleAll`）→ `runApp(UncontrolledProviderScope(LingShuApp))`。
- **应用壳 `lib/app.dart`**：`MaterialApp.router` + `buildRouter(WidgetRef)`（go_router）。主题 `buildLingShuTheme()`（见 `lib/core/theme.dart`）。
- **会话门禁**：`SessionState { loading, needOnboarding, locked, ready }`（定义在 `lib/providers.dart`）。router redirect 逻辑：未建档 → `/onboarding`；已建档 → 每次启动锁 `/lock`（PIN/生物识别解锁）。
- **底部导航**：`StatefulShellRoute.indexedStack` 五分支（`lib/pages/home_shell.dart`，NavigationBar 五 Tab，五行配色）：

| Tab | 路由 | 页面 | 五行色 |
|---|---|---|---|
| 灵枢 | `/home` | `pages/acupoint/acupoint_page.dart`（3D 铜人） | 水 |
| 档案 | `/records` | `pages/records/records_page.dart` | 土 |
| 健康 | `/metrics` | `pages/metrics/metrics_page.dart` | 木 |
| 急救 | `/firstaid` | `pages/firstaid/firstaid_page.dart` | 火 |
| 我的 | `/profile` | `pages/profile/profile_page.dart` | 金 |

- **二级路由**：`/onboarding`、`/lock`、`/records/import`（拍照导入）、`/records/:id`（档案详情）、`/metrics/:id`（指标趋势图）、`/family` 与 `/family/edit?id=&first=1`（成员档案）、`/medications` 与 `/medications/edit?id=`（用药）、`/settings`、`/backup`（备份恢复）、`/constitution`（体质辨识）、`/box`（家庭药箱）、`/firstaid/:id`（急救场景）、`/ai`（AI 原生入口·体验版，由「我的」页进入）。
- **注意**：中药图鉴三个页面（`pages/herb/`）**不在 go_router 中注册**，由铜人页等处 `Navigator.push` 直跳。

## lib/ 目录职责（共 57 个 .dart 文件）

```
lib/
├── main.dart              入口 + 启动重排通知
├── app.dart               MaterialApp.router + GoRouter 路由表
├── providers.dart         全局 Riverpod providers（见下）
├── core/                  基础设施层
│   ├── theme.dart         五行五色 WuXing + LingShuColors（宣纸/墨/鎏金/朱砂）
│   ├── ui.dart            LSCard / LSSectionTitle 标准组件
│   ├── branding.dart      MosaicBranding 钤记 + appVersion()（package_info_plus）
│   ├── logo.dart          LingShuLogo（维特鲁威人×北斗，图由 ../.setup/compose_logo.py 生成）
│   ├── lunar_date_picker.dart  农历日期选择器（lunar 包）
│   ├── db.dart            Drift 数据库 schema v9（见"数据模型"）
│   ├── db.g.dart          build_runner 生成物（勿手改）
│   └── services/
│       ├── auth_service.dart         PIN 码（crypto SHA+盐存 SharedPreferences）+ 生物识别开关
│       ├── backup_service.dart       zip 导出/导入（archive），ImportPlan 差异预览决策
│       ├── content_loader.dart       ContentRepo：rootBundle 加载 assets/data/*.json（经络/穴位/急救/体质/节气）
│       ├── herb_repo.dart            HerbRepo：879 味中药（assets/data/herbs.json）+ CollectedHerbs 收藏
│       ├── location_service.dart     geolocator/geocoding 定位与附近地点建议
│       ├── notification_service.dart 用药提醒 + 药箱到期（6/3/1 月前+过期后每日）
│       ├── asr_service.dart          语音转写（OpenAI 兼容 /audio/transcriptions）+ 口述血压/心率解析
│       ├── agent_capabilities.dart   AI 管家能力目录（13 项，会话点选列表与路由提示词共用）+「你能做什么」问句本地识别
│       ├── ai_history_store.dart     AI 管家会话历史落盘（ai_history/messages.json + 趋势图 PNG；损坏当无历史绝不清文件；上限 300 条）
│       ├── agent_service.dart        AI 管家：意图路由（15 个动作：归档/查指标/记指标/用药增停查/档案/概览/体质/药箱/急救/中药/穴位/节气/导航）+ 无头归档管线 + 趋势图离屏渲染（Canvas→PNG）
│       ├── ocr_service.dart          视觉大模型 OCR（OpenAI 兼容 /chat/completions），OcrResult/OcrMetric/MetricMergeGroup 指标合并
│       └── weather_service.dart      Open-Meteo 免 Key 天气（节气卡片用）
└── pages/                 页面层（8 子模块 + 3 顶层壳）
    ├── home_shell.dart / lock_page.dart / onboarding_page.dart
    ├── ai/         AI 原生入口（体验版）：ai_home_page（北斗星野会话+语音呼吸球；气泡内嵌能力点选列表与「打开页面」按钮）+ beidou_background（呼吸星野画笔）
    ├── acupoint/   首页铜人：acupoint_page(814 行) + body3d(619 行，纯 Flutter 软件渲染 3D：V3/BodyPart/Mannequin 球+胶囊建模、自定义光照) + body_chart(464 行，2D 挂图)
    ├── records/    档案库：records_page / records_calendar / record_import_page（拍照/文件+AI 识别）/ record_detail_page
    ├── metrics/    指标：metrics_page / metric_chart_page（fl_chart 趋势+参考区间带）
    ├── profile/    我的：profile / family / medications / med_edit / settings / backup / constitution（九种体质问卷）/ hr_measure_sheet（心率测量）
    ├── firstaid/   急救：firstaid_page / firstaid_detail_page（26 场景，SOS 拨 120）
    ├── herb/       中药图鉴：herb_collection_page / herb_detail_page / herb_identify_page（Navigator.push 直跳）
    └── medicine_box/ 药箱：box_page（格位式展示、到期提醒）
```

## 关键 Riverpod Providers（`lib/providers.dart`）

| Provider | 类型 | 用途 |
|---|---|---|
| `sharedPreferencesProvider` | Provider（main 中 override） | 全局偏好 |
| `dbProvider` | Provider\<AppDatabase\> | 加密数据库单例 |
| `authProvider` | Provider\<AuthService\> | PIN/生物识别/当前成员 |
| `sessionProvider` | StateNotifierProvider\<SessionNotifier, SessionState\> | 启动门禁状态机 |
| `currentProfileIdProvider` / `currentProfileProvider` | StateProvider / StreamProvider | 当前家庭成员切换 |
| `recordsProvider` / `metricsProvider` / `medicationsProvider` | StreamProvider | 按成员 watch 的列表 |
| `contentProvider` | Provider\<ContentRepo\> | 静态中医内容 |
| `aiConfigProvider` | FutureProvider\<OcrService\> | 读 prefs `ai.base_url`/`ai.api_key`/`ai.model` |
| `asrConfigProvider` | FutureProvider\<AsrService\> | 语音识别配置，prefs `asr.*` 留空逐项回退 `ai.*` |
| `collectedHerbsProvider` + `collectedVersionProvider` | Provider + StateProvider | 图鉴收藏（bump version 触发刷新） |
| `allHerbsProvider` | FutureProvider\<List\<Herb\>\> | 879 味全局缓存 |

## 数据模型（`lib/core/db.dart`，Drift schema v9，共 9 表）

| 表 | 说明 |
|---|---|
| `Profiles` | 家庭成员档案（含 `idNumberEnc` 身份证、体质、紧急联系人、`isOwner`） |
| `MedicalRecords` | 医疗档案（类型/医院/科室/GPS 坐标 `lat,lng`/`aiSummary`/`fileHash` MD5 去重） |
| `Metrics` / `MetricValues` | 指标定义（预设+自定义、双值如血压、参考区间、`aiInfo` AI 解读、`followed` ⭐关注）与测量值（`timeLabel` 测量时点、`source` manual/ai） |
| `Medications` / `MedicationLogs` | 药物（`timesOfDay`/`daysOfWeek`/`pausePeriods` 均 JSON 字符串、库存）与服药打卡 |
| `Families`（行类名 `FamilyRow`，避让 riverpod Family）/ `FamilyMembers` | 家庭组与成员关联 |
| `BoxMedicines` | 药箱药品（`expireDate`、`imagePaths` JSON 多图，v9 迁移自 `imagePath`） |

- **加密**：`_open()` 在应用文档目录生成 `.dbkey`（16 进制时间戳），`PRAGMA key` 整库 SQLCipher 加密；Android 后台 isolate 需 `openCipherOnAndroid` 重定向动态库。
- **迁移策略**：`MigrationStrategy.onUpgrade` 逐版本 addColumn/建表；v3 含一次性去重 SQL（`_dedupeMetricData`）；v9 对重复 addColumn 做了 try-catch 防御（历史发布事故，注释有记载）。
- **修改表结构流程**：改 `db.dart` → `schemaVersion` +1 → 补 `onUpgrade` 分支 → `dart run build_runner build --delete-conflicting-outputs` 重新生成 `db.g.dart`。

## 第三方依赖（`pubspec.yaml`，用途提炼）

| 依赖 | 用途 |
|---|---|
| `flutter_riverpod ^2.6.1` | 全局状态管理 |
| `go_router ^16.0.0` | 声明式路由 + 底部导航 Shell |
| `drift ^2.28` + `sqlcipher_flutter_libs ^0.6.5` + `sqlite3 ^2.4` | 加密本地数据库 |
| `fl_chart ^0.71.0` | 指标趋势图 |
| `image_picker` / `file_picker` / `image ^4.3.0` | 拍照/选文件/图片处理 |
| `geolocator ^13` / `geocoding ^3` | 归档时定位与逆地理 |
| `flutter_local_notifications ^18` + `timezone` | 用药/药箱到期本地通知（Android 需 core library desugaring） |
| `local_auth ^2.3.0` | 生物识别解锁 |
| `http ^1.4` | OCR / 天气 API |
| `crypto` / `uuid` | PIN 哈希 / 备份 ID |
| `lunar ^1.7.8` | 农历/节气/干支 |
| `archive ^4.3.0` / `share_plus` / `package_info_plus` | zip 备份 / 分享导出 / 版本号 |
| `shared_preferences` / `path` / `path_provider` / `intl` / `url_launcher` | 常规基础 |
| dev: `drift_dev` + `build_runner` | 代码生成；`flutter_lints ^6` | 规范 |

字体：`SerifSC`（NotoSerifSC Medium 500 / Bold 700，`assets/fonts/`）。

## assets/ 清单组织

| 目录 | 内容 | 规模 |
|---|---|---|
| `assets/data/` | 静态内容 JSON：`acupoints_v2.json`（141 穴，坐标系统：身高 1.72m、脚底 y=0、面向 +Z）、`acupoints_legacy_prose.json`、`meridians.json`、`firstaid.json`（26 场景）、`constitution_quiz.json`、`solar_terms.json`、`presets.json`（预设指标）、`body_views.json`、`herbs.json`（879 味） | 12 文件 |
| `assets/data/acupoints/` | 按部位拆分的穴位 `acupoints_upper/trunk/lower.json` | 3 文件 |
| `assets/herb_images/`（420）/ `herb_images_zy/`（537）/ `herb_plants/`（1166） | 药材照片（HKBU 图像数据库）与原植物照 | 2100+ 张 |
| `assets/fonts/` | NotoSerifSC ×2 | 2 文件 |
| `assets/images/` | `logo_main.png`（Logo，源出 `.setup/compose_logo.py`） | 1 文件 |
| `assets/web/` | `model-viewer.min.js` + `body_f/body_m.glb` + index.html —— **lib/ 中无引用，属早期 glb 方案遗留**（现 3D 为纯 Dart 软件渲染） | 4 文件 |
| `assets/models/` | 空目录（pubspec 仍声明） | 0 文件 |

另：`dist/lingshu.apk`、根下 `灵枢_v0.1.0_release.apk`（98MB）为历史构建产物；`screenshots/` 20 张功能截图。

## 平台层配置

**Android（`android/`，Kotlin DSL）**
- `applicationId` / `namespace`：`com.tcm.lingshu`；compileSdk 36；Java/Kotlin JVM 17；AGP 9.1.0、Kotlin 2.4.0（`settings.gradle.kts`，flutterSdkPath 读自 local.properties）。
- **core library desugaring 已启用**（flutter_local_notifications 必需，`desugar_jdk_libs:2.1.5`）。
- `buildTypes.release` 使用 **debug 签名**（个人分发用，上商店需换正式签名）。
- 版本号由 Flutter 注入：`flutter.versionName=0.1.36`、`versionCode=9905`（`android/local.properties`，机器本地文件）。
- 权限（`app/src/main/AndroidManifest.xml`）：INTERNET、COARSE/FINE_LOCATION、CAMERA、POST_NOTIFICATIONS、SCHEDULE_EXACT_ALARM、SET_ALARM、USE_BIOMETRIC；配置了 `network_security_config`（AI API 域名放行见 `android/app/src/main/res/xml/`）。
- MainActivity：`.MainActivity`（Kotlin，标准模板）。

**iOS（`ios/`）**：标准 Runner 模板（AppDelegate.swift + SceneDelegate），`CFBundleDisplayName = Lingshu`，版本号由 Flutter 变量注入；无自定义原生代码。

## 测试与质量

- `test/widget_test.dart`：冒烟测试（ContentRepo 可实例化）；`test/herb_pack_downloader_test.dart`：配图包下载器；`test/vitals_speech_parser_test.dart`：口述血压/心率解析；`test/agent_chart_test.dart`：AI 管家趋势图离屏渲染；`test/agent_capabilities_test.dart`：能力问句识别（含健康问句不误命中）；`test/agent_actions_test.dart`：AI 管家全部本地动作（内存库直调 runAction，通知传 null 跳过）。改动核心逻辑时建议手动回归（参考 `screenshots/` 里的功能清单）。
- `analysis_options.yaml`：flutter_lints 6，exclude `build/** android/** ios/**`。提交前跑 `flutter analyze`。
- 调试记录惯例：历史上用 `.setup/`（ar*.json、smoke*.png、append_v*.json）+ flowus_cli 做版本走查留痕，属工作区级习惯而非本工程内流程。

## tool/ 脚本

`tool/` 目录当前为**空**（Flutter 模板遗留）。数据生产脚本不在本工程内，统一放在工作区 `../.setup/`（crawl_hkbu*.py 爬药材图、inject_acupoints.py 注入穴位坐标、subset_fonts.py 子集化字体等，产出物注入 `assets/`）。

## 关键文件路径速查（相对本目录）

| 场景 | 文件 |
|---|---|
| 改路由/加页面 | `lib/app.dart`（路由表）+ `lib/pages/<模块>/` |
| 改全局状态 | `lib/providers.dart` |
| 改数据库 | `lib/core/db.dart`（记得 build_runner + schemaVersion） |
| 改主题配色 | `lib/core/theme.dart`（WuXing / LingShuColors） |
| 改 AI 识别 | `lib/core/services/ocr_service.dart`（默认 baseUrl/model 在此类顶部） |
| 改通知逻辑 | `lib/core/services/notification_service.dart` + `lib/main.dart`（启动重排） |
| 3D 铜人 | `lib/pages/acupoint/body3d.dart`（建模）+ `body_chart.dart`（2D 挂图） |
| 穴位数据 | `assets/data/acupoints_v2.json` 与 `assets/data/acupoints/*.json` |
| 版本号 | `pubspec.yaml`（`version: 0.1.36+9905`，Android 端由 Flutter 注入） |
