# BabyCare 修复记录 (CHANGELOG)

---

## v1.2.0 (2026-03-07)

### 🐛 Bug 修复

#### 1. 全面屏适配 & 返回按钮改进
- **问题**: 导航栏紧贴屏幕顶部，在刘海屏/打孔屏手机上被状态栏遮挡，返回按钮不易点击
- **原因**: `index.html` 缺少 `viewport-fit=cover`，CSS 未使用 `safe-area-inset-top`
- **修复**:
  - `index.html`: 添加 `viewport-fit=cover` 和 `user-scalable=no`
  - `main.css`: 导航栏添加 `padding-top: env(safe-area-inset-top)`，占位符高度同步增加
  - 返回按钮最小高度增至 44px (Apple HIG 推荐最小触摸尺寸)，图标增至 24px
- **涉及文件**: `index.html`, `src/assets/main.css`

#### 2. 侧滑返回
- **问题**: App 内无法通过侧滑手势返回上一页
- **修复**: 新增 `useSwipeBack` composable，监听左边缘滑动手势（30px 阈值），滑动距离 >80px 触发 `router.back()`
- **涉及文件**: `src/composables/useSwipeBack.ts`（新增）, `src/App.vue`

#### 3. PDF 导出中文乱码
- **问题**: `generateMonthlyReport` 使用 jsPDF 的 `pdf.text()` 直接渲染文字，默认字体不支持 CJK，中文内容显示为空白
- **修复**: 重写 `generateMonthlyReport`，改用创建临时 HTML DOM → `html2canvas` 截图 → 转 PDF 的方式，完美支持中日韩文字
- **涉及文件**: `src/services/pdfService.ts`

---

## v1.1.0 (2026-03-07)

### 🐛 Bug 修复

#### 1. 页面返回功能失效
- **问题**: 所有子页面的返回按钮点击后无法返回上一层
- **原因**: 路由使用 `createWebHistory`，Capacitor 打包后从本地文件系统加载，HTML5 History API 无法正确解析路径
- **修复**: 切换为 `createWebHashHistory`，使用 `#/path` 格式路由
- **涉及文件**: `src/router/index.ts`

#### 2. 导航栏按钮过小
- **问题**: 返回箭头和右侧操作按钮在手机上不易点击
- **修复**: 通过 Vant CSS 变量全局增大导航栏高度 (54px)、箭头大小、触摸区域
- **涉及文件**: `src/assets/main.css`

#### 3. 拍照上传失败
- **问题**: 使用相机拍照后无法保存，报路径读取错误
- **原因**: `CameraResultType.Uri` 返回的路径在 Android 上经 Filesystem.readFile 读取时可能失败
- **修复**: 改用 `CameraResultType.Base64` 直接获取 Base64 数据并写入文件，避免路径解析问题
- **涉及文件**: `src/services/mediaService.ts`

---

## v1.0.0 (2026-03-06)

### ✨ 初始版本
- 完整的喂养记录、睡眠记录、排泄记录、生长曲线功能
- 日历视图、统计图表、PDF 报告导出
- 宝宝动态 (照片/视频) 媒体库
- 育儿百科知识库
- 提醒功能 (本地通知)
- 中英文双语国际化
- 深色模式支持
- 数据备份与恢复
