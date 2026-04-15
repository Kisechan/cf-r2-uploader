# CFR2Uploader

一个支持 Cloudflare R2 的 macOS 图片上传工具，提供两种入口：

- macOS Menu Bar App
- CLI：`cfr2uploader`

项目目标是用一套共享核心逻辑，同时支持图形界面和命令行上传，并在上传成功后返回公开访问 URL 或 Markdown 图片链接。

## 功能概览

- 支持 Cloudflare R2
- 只处理图片上传
- 共享 `CFR2Core` 上传内核
- Menu Bar 上传入口
- CLI 上传入口
- 配置文件存储非敏感信息
- Keychain 存储 `Access Key ID` / `Secret Access Key`
- 上传历史记录
- 默认公开地址使用自定义域名

## 技术栈

- Swift
- SwiftUI
- MenuBarExtra
- Swift Package Manager
- `swift-argument-parser`
- macOS Keychain

## 项目结构

```text
.
├── Package.swift
├── Sources
│   ├── CFR2Core
│   └── cfr2uploader
├── Tests
│   └── CFR2CoreTests
├── cf-r2-uploader
│   ├── App
│   ├── MenuBar
│   ├── Settings
│   └── Support
└── cf-r2-uploader.xcodeproj
```

核心职责：

- `Sources/CFR2Core`
  - R2 配置模型
  - Keychain 凭据读写
  - R2 上传实现
  - MIME 类型校验
  - Object key 生成
  - 公开 URL 拼装
  - 上传历史
- `Sources/cfr2uploader`
  - CLI 参数解析
  - 终端输出
  - 可选复制到剪贴板
- `cf-r2-uploader`
  - Menu Bar App
  - 设置页
  - 文件选择与上传状态展示

## 环境要求

- macOS 14+
- Xcode 26.2 或兼容版本
- Swift 6 toolchain
- 一个可写入的 Cloudflare R2 bucket
- 一个已经绑定到该 bucket 的公开访问自定义域名

## Cloudflare R2 前置准备

在使用本项目之前，需要先完成以下 Cloudflare 侧配置：

1. 创建一个 R2 bucket。
2. 为这个 bucket 绑定公开访问的自定义域名。
3. 创建一组 R2 S3 API Access Key。
4. 记录以下信息：
   - `Account ID`
   - `Bucket`
   - `Public Base URL`
   - `Access Key ID`
   - `Secret Access Key`

本项目上传时走的是 R2 的 S3 兼容接口，签名区域固定为 `auto`，上传端点等价于：

```text
https://<ACCOUNT_ID>.r2.cloudflarestorage.com
```

## 快速开始

### 1. 克隆并进入项目

```bash
git clone <your-repo-url>
cd cf-r2-uploader
```

### 2. 运行测试

```bash
swift test
```

### 3. 打开 Xcode

```bash
open cf-r2-uploader.xcodeproj
```

然后直接运行 `cf-r2-uploader` scheme。

### 4. 首次配置

启动 App 后：

1. 打开菜单栏图标。
2. 进入“设置”。
3. 填写 R2 配置和凭据。
4. 点击“保存”。

保存后：

- 配置文件会写入 `~/Library/Application Support/CFR2Uploader/config.json`
- 凭据会写入 macOS Keychain

## 配置说明

### 配置文件路径

默认配置文件路径：

```text
~/Library/Application Support/CFR2Uploader/config.json
```

当前实现支持单 profile 为主，但数据结构已经保留 `profiles` 和 `defaultProfile`。

### 配置文件格式

示例：

```json
{
  "defaultProfile": "default",
  "profiles": {
    "default": {
      "accountID": "your-account-id",
      "bucket": "images",
      "cacheControl": "public, max-age=31536000, immutable",
      "defaultOutput": "url",
      "keyPrefix": "uploads",
      "publicBaseURL": "https://img.example.com"
    }
  },
  "version": 1
}
```

字段说明：

- `accountID`
  - Cloudflare Account ID
- `bucket`
  - R2 bucket 名称
- `publicBaseURL`
  - 图片公开访问域名，例如 `https://img.example.com`
- `keyPrefix`
  - 对象 key 前缀，默认 `uploads`
- `defaultOutput`
  - 默认输出格式，支持 `url` 和 `markdown`
- `cacheControl`
  - 上传时写入对象的 `Cache-Control`

### Keychain 凭据

敏感信息不写入 JSON。以下字段保存在 Keychain：

- `Access Key ID`
- `Secret Access Key`

Keychain service 名称：

```text
kisechan.CFR2Uploader.credentials
```

## CLI 使用

### 构建并运行

直接运行：

```bash
swift run cfr2uploader /absolute/path/to/image.png
```

CLI 支持参数：

```bash
swift run cfr2uploader <file> \
  --config /path/to/config.json \
  --profile default \
  --format url \
  --copy
```

### CLI 参数说明

- `<file>`
  - 本地图片路径
- `--config`
  - 指定配置文件路径
- `--profile`
  - 指定 profile 名称
- `--format`
  - 输出格式：`url` 或 `markdown`
- `--copy`
  - 成功后把结果复制到剪贴板

### CLI 输出示例

输出 URL：

```bash
swift run cfr2uploader ./demo.png --format url
```

示例输出：

```text
https://img.example.com/uploads/2026/04/15/demo-abc12345.png
```

输出 Markdown：

```bash
swift run cfr2uploader ./demo.png --format markdown
```

示例输出：

```markdown
![uploads/2026/04/15/demo-abc12345.png](https://img.example.com/uploads/2026/04/15/demo-abc12345.png)
```

## App 使用

### 启动方式

在 Xcode 中运行 `cf-r2-uploader` target。

### 菜单栏工作流

1. 点击菜单栏图标。
2. 点击“选择图片并上传”。
3. 选择本地图片。
4. 上传成功后：
   - 结果会复制到剪贴板
   - 最近上传会显示在菜单中
   - 可点击历史项直接打开 URL

### 默认行为

- 只允许选择图片文件
- 默认复制结果到剪贴板
- 默认输出格式取决于配置中的 `defaultOutput`

## 环境变量回退

CLI 和 Core 目前保留了一个环境变量回退路径，方便无配置文件时快速 smoke test。

当默认配置文件不存在时，可以直接设置：

```bash
export CFR2_ACCOUNT_ID="your-account-id"
export CFR2_BUCKET="images"
export CFR2_PUBLIC_BASE_URL="https://img.example.com"
export CFR2_ACCESS_KEY_ID="your-access-key-id"
export CFR2_SECRET_ACCESS_KEY="your-secret-access-key"
```

可选项：

```bash
export CFR2_KEY_PREFIX="uploads"
export CFR2_DEFAULT_OUTPUT="url"
export CFR2_CACHE_CONTROL="public, max-age=31536000, immutable"
```

然后运行：

```bash
swift run cfr2uploader ./demo.png
```

这个回退逻辑主要是为了开发调试；正式使用仍建议通过设置页写入配置和 Keychain。

## 运行与构建

### SwiftPM 测试

```bash
swift test
```

### 运行 CLI

```bash
swift run cfr2uploader ./demo.png
```

### 构建 macOS App

```bash
xcodebuild \
  -project cf-r2-uploader.xcodeproj \
  -scheme cf-r2-uploader \
  CODE_SIGNING_ALLOWED=NO \
  build
```

如果只是本地开发，直接用 Xcode 运行即可。

## 测试覆盖

当前测试主要覆盖：

- `KeyBuilder`
  - 对象 key 的日期目录、文件名清洗和随机后缀规则
- `PublicURLBuilder`
  - 公开 URL 拼装
- `ConfigStore`
  - 配置文件读写
- `UploadService`
  - 图片上传编排
  - 非图片文件拒绝

## 对象命名规则

当前默认 key 规则：

```text
<keyPrefix>/<yyyy>/<MM>/<dd>/<sanitized-name>-<random8>.<ext>
```

示例：

```text
uploads/2026/04/15/my-image-abc12345.png
```

这样做的目的：

- key 可读
- 日期归档方便排查
- 同名文件冲突概率低
- 适合长期缓存

## 上传实现说明

上传链路固定为：

1. 校验文件存在且为图片
2. 计算 MIME type
3. 生成 object key
4. 使用 R2 S3 兼容接口执行 `PUT Object`
5. 拼装公开 URL
6. 写入历史并返回 URL / Markdown

底层实现使用：

- `URLSession`
- AWS SigV4 请求签名

这样做的原因是保持依赖轻量，并让 CLI / App / 测试构建更稳定。

## 开发建议

如果你要继续扩展这个项目，建议优先沿着下面顺序推进：

1. 完善真实 R2 联调和错误提示
2. 增加批量上传
3. 增加拖拽上传
4. 增加文件名策略选择
5. 增加更细的上传状态和进度

不建议在当前阶段做的事情：

- 多图床插件架构
- 复杂后台同步系统
- 过早引入数据库
- 为了抽象而抽象的 provider 层

## 许可证

[MIT](./LICENSE)。
