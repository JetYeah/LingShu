<div align="center">

# 灵枢 · LingShu

**身有灵枢，健康有度**

把全家的健康，装进一个**离线、加密、长得像中医典籍**的 App。

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Platform](https://img.shields.io/badge/平台-Android%20arm64-3DDC84?logo=android&logoColor=white)
![Release](https://img.shields.io/badge/最新-v0.1.36-E8743B?logo=github)
![License](https://img.shields.io/badge/License-MIT-yellow)

<img src="lingshu/screenshots/03_挂图_正面视图.png" width="30%" alt="经络穴位挂图"/> <img src="lingshu/screenshots/19_家庭小药箱_药柜.png" width="30%" alt="家庭小药箱"/> <img src="lingshu/screenshots/13_血压趋势图.png" width="30%" alt="血压趋势图"/>

取意《黄帝内经·灵枢》——专论经络穴位之篇，"枢"亦喻健康数据之枢纽。

</div>

---

## ✨ 为什么是灵枢

- 🏮 **五行美学，不是又一个白底蓝按钮的健康 App** —— 宣纸米白底 × 木火土金水五色体系，思源宋体，太极、云纹、篆刻、木质药柜，每一屏都像摊开一册中医典籍
- 🔒 **数据不出手机** —— SQLCipher 全库加密 + PIN 锁屏，无账号、无云端、无追踪；AI 识别自己配 Key、自己开关
- 🤖 **AI 只帮忙，不添乱** —— 拍照识别化验单与药盒、指标自动归类、一句话从药箱找药；识别不了就手动填，永远有退路
- 👨‍👩‍👧 **一人一档，全家共用** —— 家庭成员自由切换，档案、用药、药箱按人归置

## 🧭 功能一览

### 🗺️ 经络穴位挂图 · 一眼定位

361 经穴高清挂图，按经络筛选高亮循行；搜索穴位即刻在图上**闪烁定位**，其余自动灰掉。穴名带拼音声调，详情页附《灵枢》原文。

| | |
| :---: | :---: |
| <img src="lingshu/screenshots/04_挂图_肺经筛选.png" width="280" alt="经络筛选高亮"/> | <img src="lingshu/screenshots/06_穴位详情_内关.png" width="280" alt="穴位详情"/> |
| 按经络筛选，循行线高亮 | 穴位详情：拼音 · 归经 · 主治 · 《灵枢》原文 |

### 📁 健康档案库 · 拍照即入库

拍照/相册导入报告单，AI 视觉大模型自动提取医院、日期与**指标数值**，确认后入库；按「人 → 年 → 月」时间线归档，自动定位记录附近医院。

| | |
| :---: | :---: |
| <img src="lingshu/screenshots/10_档案详情_拍照入库.png" width="280" alt="档案详情"/> | <img src="lingshu/screenshots/11_档案库_时间线分组.png" width="280" alt="档案时间线"/> |
| AI 识别归档：摘要与原件同屏 | 时间线分组，一屏纵览检查史 |

### 📈 指标追踪 · 趋势看得见

预设血压/血糖/血脂/体温等指标，支持自定义；参考区间带与异常点高亮，19 类指标自动归类（凝血、电解质、基础体征……），点 ✦ 让 AI 把「其他」归位。

| | |
| :---: | :---: |
| <img src="lingshu/screenshots/13_血压趋势图.png" width="280" alt="血压趋势"/> | <img src="lingshu/screenshots/12_健康指标列表.png" width="280" alt="指标列表"/> |
| 参考区间带 + 异常点高亮 | ✦ AI 归类后的指标分组速览 |

### 🗄️ 家庭小药箱 · 会提醒，还会找药

从家庭成员选人组「小家庭」，一家庭一药箱；**木格药柜**一格一药，临期自动变色，拉开柜门看原始照片。到期前 6/3/1 个月自动提醒，过期每天催一次。

**✦ AI 找药**（v0.1.36 新增）：一句话说需求——「有没有治感冒的药」——AI 在你家药箱里挑出相关药品；只上传药品名与用法用量的文字，不上传照片。

| | |
| :---: | :---: |
| <img src="lingshu/screenshots/19_家庭小药箱_药柜.png" width="280" alt="药柜"/> | <img src="lingshu/screenshots/21_小药箱_AI找药结果.png" width="280" alt="AI 找药结果"/> |
| 木格药柜，临期变色 | ✦ 一句话，AI 帮你翻药柜 |

### 🚑 急救指南 · 离线速查

以 IFRC《国际急救指南》为蓝本的场景卡：CPR+AED、海姆立克、中风 FAST、过敏性休克……步骤化图文全程离线，紧急时刻不看广告、不等加载。

| | |
| :---: | :---: |
| <img src="lingshu/screenshots/14_急救指南列表.png" width="280" alt="急救列表"/> | <img src="lingshu/screenshots/15_急救详情_CPR.png" width="280" alt="CPR 步骤"/> |
| 20+ 场景速查 | 步骤化图文，注明来源 |

### 💊 用药提醒 · 🌗 体质与节气

每日 N 次/间隔/每周几、餐前餐后，准点提醒打卡；中医九种体质标准问卷 + 节气子午流注养生卡。

| | |
| :---: | :---: |
| <img src="lingshu/screenshots/16_用药提醒_打卡.png" width="280" alt="用药打卡"/> | <img src="lingshu/screenshots/18_体质辨识_介绍页.png" width="280" alt="体质辨识"/> |
| 依从性打卡记录 | 九种体质辨识问卷 |

## ⬇️ 下载

| 渠道 | 说明 |
| --- | --- |
| [GitHub Releases](https://github.com/JetYeah/LingShu/releases/latest) | `lingshu_vX.Y.Z_release_arm64.apk`，arm64 专版（2018 年后的手机均可安装），覆盖安装数据全保留 |

> 首次使用：创建主人档案 →（可选）配置 AI 识别的 base_url 与 Key（默认兼容 GLM-4V 的 OpenAI 协议接口）。

## 🔒 隐私立场

- 健康数据**全部本地存储**，SQLCipher 加密，PIN/生物识别锁屏
- AI 识别需自行配置接口，**默认关闭**；找药仅上传药品名文字清单
- 无账号体系、无云端同步、无埋点追踪

## 🛠️ 技术栈与本地构建

Flutter · Riverpod · go_router · Drift(SQLite + SQLCipher) · flutter_local_notifications · fl_chart · GLM-4V（OpenAI 兼容视觉接口）

```bash
cd lingshu
flutter pub get
flutter run              # 调试
flutter build apk --release --split-per-abi   # release（arm64 包用于发布）
```

## ⚠️ 免责声明

本应用内容（含穴位、体质、养生建议）仅供健康记录与参考，**不构成医疗建议**；急症请拨打 120 并遵医嘱。

## 📄 License

[MIT](LICENSE) © 2026 JetYeah
