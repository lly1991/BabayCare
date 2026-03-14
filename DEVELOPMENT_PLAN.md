# BabyCare Flutter 开发计划

最后更新：2026-03-14

## 迁移结论

- 已完成从旧 Vue/Capacitor 到 Flutter 架构迁移。
- 旧前端与旧 Android 宿主代码已从仓库移除。
- 当前代码基线以 `flutter_app/` 为唯一业务实现。

## 当前架构

- `feature-first + clean architecture`
- `flutter_riverpod` 状态管理
- `go_router` 路由管理
- `sqflite` 本地数据持久化

## 已完成功能

- 认证与会话：登录/注册、会话恢复、路由守卫
- 宝宝管理：建档、切换、读取当前宝宝
- 喂养记录：新增、按日查询、最近记录
- 统计模块：
  - 按日统计：奶粉次数/奶量、母乳次数/时长
  - 按周统计：汇总 + 每日日详情（同按日口径）
  - 按月统计：汇总 + 每日日详情（同按日口径）
- 日常动态（原 media）：
  - 图片/视频采集
  - SQLite 落库持久化
  - 列表读取、预览、删除（含本地文件清理）
- 睡眠、排泄、生长：基础记录流程与历史查看
- 首页聚合与日历入口联动

## 测试与验证（2026-03-14）

- 静态检查：`flutter analyze` 通过
- 自动化测试：`flutter test` 通过
- 新增关键测试覆盖：
  - 喂养日/周/月统计口径校验
  - 日常动态落库、读取排序、删除联动文件清理

## 打包结果（2026-03-14）

- Debug APK：`flutter_app/build/app/outputs/flutter-apk/app-debug.apk`
- Release APK：执行 `flutter build apk --release` 后产出  
  `flutter_app/build/app/outputs/flutter-apk/app-release.apk`

## 后续可选迭代

- 扩展功能回归：提醒、知识库、备份导入导出、PDF 报告
- 引入集成测试（integration_test）覆盖核心用户流程
