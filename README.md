# BabyCare (Flutter)

BabyCare 是一款面向新生儿家庭的本地离线记录应用，支持喂养、睡眠、排泄、生长、日常动态与统计分析。  
本仓库已完成从 Vue/Capacitor 到 Flutter 的架构迁移，并保持原有业务能力持续可用。

## 项目现状

- 迁移状态：已完成 Flutter 化重构（旧前端代码已移除）
- 技术架构：`feature-first + clean architecture`
- 状态管理：`Riverpod`
- 路由：`go_router`
- 数据存储：`sqflite`（本地数据库）
- Android 包名：`com.babycare.app`（用于承接历史本地数据）

## 核心功能

- 账号与宝宝：
  - 本地注册/登录
  - 兼容历史账号密码校验与数据迁移
  - 宝宝建档、切换、新增
- 喂养记录：
  - 记录母乳/奶粉
  - 统计口径：
    - 奶粉：次数 + 奶量
    - 母乳：次数 + 时长
  - 日 / 周 / 月统计（周、月每日详情与日统计口径一致）
  - 首页、日历页支持删除喂养记录
- 日常动态（Media）：
  - 图片/视频采集与本地持久化
  - 列表展示、预览、删除
- 其他记录：
  - 睡眠记录（计时与手动补录）
  - 排泄记录
  - 生长记录
- 个人中心与扩展：
  - 设置 / 育儿知识 / 提醒设置 / 关于软件
  - 本地数据备份导出与导入恢复（JSON）
  - 日期选择器统一 iOS 风格（Cupertino）

## 目录结构

```text
BabayCare/
  flutter_app/                 # Flutter 主工程
    lib/
      app/                     # 应用入口与路由
      core/                    # 数据库/工具/通用组件
      features/                # 按业务拆分模块
    test/                      # 单元测试
  docs/                        # 架构与迁移文档
```

## 快速启动

```bash
cd flutter_app
./bootstrap_flutter.sh
/Users/edy/tools/flutter/bin/flutter pub get
/Users/edy/tools/flutter/bin/flutter run
```

## 质量校验

```bash
cd flutter_app
/Users/edy/tools/flutter/bin/flutter analyze
/Users/edy/tools/flutter/bin/flutter test
```

## 打包 APK

```bash
cd flutter_app
/Users/edy/tools/flutter/bin/flutter build apk --release --no-pub
```

产物路径：

- `flutter_app/build/app/outputs/flutter-apk/app-release.apk`
- `flutter_app/build/app/outputs/flutter-apk/app-debug.apk`

## 文档

- 迁移计划：[`DEVELOPMENT_PLAN.md`](./DEVELOPMENT_PLAN.md)
- 架构说明：[`docs/FLUTTER_REWRITE_ARCHITECTURE.md`](./docs/FLUTTER_REWRITE_ARCHITECTURE.md)
