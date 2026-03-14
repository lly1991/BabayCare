# BabyCare 架构梳理与 Flutter 重构方案

## 1. 现状架构（Vue 3 + Capacitor）

当前项目是一个典型的前端单体应用，结构为：

- `View (src/views/*)`：页面和交互。
- `Store (src/stores/*)`：Pinia 状态层，封装页面可用的状态和动作。
- `Service (src/services/*)`：数据库、设备能力、业务数据读写。
- `SQLite (@capacitor-community/sqlite)`：本地存储。

核心启动链路：

1. `src/main.ts` 创建 Vue + Pinia + Router + i18n。
2. `src/App.vue` 启动后初始化数据库、恢复登录会话、加载宝宝信息并跳转。
3. `src/router/index.ts` 使用 `meta.requiresAuth` 进行守卫。

数据库：

- 单库 `babycare_db`，集中在 `src/services/database.ts` 创建表与迁移。
- 业务表：`users`, `babies`, `feeding_records`, `media_records`, `sleep_records`, `diaper_records`, `growth_records`。

## 2. 当前 Media 模块问题（已定位）

问题点（导致“看起来保存了但功能不可用”）：

- `mediaStore.saveRecord` 之前仅 `unshift` 到内存，不写入数据库，刷新后数据丢失。
- 图片预览 `startPosition` 使用原列表索引，遇到图文混排会错位。

已在当前 Vue 项目做热修复：

- `src/services/mediaService.ts` 暴露 `createRecord` 并落库。
- `src/stores/mediaStore.ts` 的 `saveRecord` 改为真正持久化。
- `src/views/Media/MediaGalleryView.vue` 修复图片预览索引。

## 3. Flutter 重构目标架构

新工程采用 `feature-first + clean architecture`：

- `lib/core/*`：跨模块基础设施（DB、异常、工具）。
- `lib/features/<feature>/domain/*`：实体、仓储接口、用例。
- `lib/features/<feature>/data/*`：本地数据源、DTO、仓储实现。
- `lib/features/<feature>/presentation/*`：页面、状态管理（Riverpod）。
- `lib/app/*`：全局路由与应用入口。

状态管理与路由：

- 状态：`flutter_riverpod`（可测试、依赖注入友好）。
- 路由：`go_router`（后续可平滑接入深链）。

数据层：

- 本地数据库：`sqflite`。
- 文件能力：`image_picker` + `path_provider` + `dart:io`。
- 视频预览：`video_player`。

## 4. 模块迁移映射（旧 -> 新）

- `HomeView + 各 Store 聚合` -> `features/home`（聚合查询用 usecase 组装）。
- `Feeding*` -> `features/feeding`。
- `Sleep*` -> `features/sleep`。
- `Diaper*` -> `features/diaper`。
- `Growth*` -> `features/growth`。
- `StatsView` -> `features/stats`（按日/周/月统计用 query usecase）。
- `MediaGalleryView` -> `features/daily_moments`（本次优先落地）。

## 5. 迁移建议节奏

1. 先用 Flutter 完成 `auth + baby context + daily moments`，打通基础设施。
2. 再迁移喂养/统计核心链路（你的主业务路径）。
3. 最后迁移次要功能（知识库、PDF 导出、备份）。

这样可以边迁移边交付，不需要一次性推倒重来。

## 6. 当前 Flutter 落地状态

已在 `flutter_app/` 完成可运行级实现并作为主工程：

- 认证与会话：登录/注册、路由守卫、宝宝建档守卫。
- 首页：今日摘要、最近喂养记录、快捷入口。
- 喂养：新增记录、按日查询、按日/周/月统计。
- 日历：按日期查看喂养记录。
- 统计：按日/周/月展示（统一奶粉/母乳口径）。
- 日常动态：图片/视频采集、持久化、预览、删除。
- 睡眠/排泄/生长：基础记录流程与历史列表。
- 我的：宝宝切换、新增、退出登录。

说明：

- 2026-03-14 已完成 `flutter analyze` 与 `flutter test`，均通过。
- 2026-03-14 已完成 APK 打包验证（debug 成功，release 可按命令生成）。
- 旧 Vue/Capacitor 代码已从仓库移除，当前仅保留 Flutter 架构。
