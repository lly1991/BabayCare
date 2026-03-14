# BabyCare Flutter

这是 BabyCare 的 Flutter 主工程，采用：

- `feature-first + clean architecture`
- `Riverpod` 状态管理
- `go_router` 路由
- `sqflite` 本地数据库

当前已落地模块：

- `auth`：本地登录/注册
- `baby`：宝宝建档、读取当前宝宝
- `home`：今日喂养摘要 + 最近记录 + 快捷入口
- `feeding`：添加喂养、按日查询、统计查询
- `calendar`：按日期查看喂养记录
- `stats`：按日/周/月统计（奶粉次数/奶量、母乳次数/时长）
- `daily_moments`（日常动态，原 media）
  - 拍照/相册选图
  - 录制/选择视频
  - SQLite 持久化
  - 列表、预览、删除
- `sleep`：计时睡眠、手动补录、历史记录
- `diaper`：快速记录与删除
- `growth`：生长记录增删
- `profile`：宝宝切换/新增、退出登录
- `settings`：数据备份导出/导入恢复（JSON）
- `knowledge`：育儿知识列表与详情
- `reminders`：提醒新增/查看/删除
- `about`：版本与项目信息页

关键能力补充：

- 历史数据/账号兼容迁移（旧库到 Flutter 库）
- iOS 风格日期选择器（CupertinoDatePicker）
- 首页与日历喂养记录支持删除

## 运行

```bash
./bootstrap_flutter.sh
flutter run
```

## 质量校验

```bash
flutter analyze
flutter test
```

## APK 打包

```bash
flutter build apk --release
```

## 目录说明

```text
lib/
  app/                  # App 与路由
  core/                 # 通用基础设施（DB/异常/工具）
  features/
    auth/
    baby/
    home/
    feeding/
    calendar/
    stats/
    daily_moments/
    sleep/
    diaper/
    growth/
    profile/
    session/
    shared/
```
