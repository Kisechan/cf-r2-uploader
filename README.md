# CFR2Uploader

一个只支持 Cloudflare R2 的 macOS 文件上传工具，提供两个入口：

- macOS Menu Bar App
- CLI：`cfr2uploader`

项目使用一套共享的 `CFR2Core`，同时服务 GUI 和命令行。上传成功后可返回公开 URL 或 Markdown 链接，并支持保存上传历史与 R2 API 日志。

## 当前能力

- 只支持 Cloudflare R2
- 支持上传任意文件，单文件限制 50 MB
- Menu Bar 上传
- 从剪贴板上传图片
- CLI 上传
- 上传历史
- R2/S3 API 交互日志
- 配置文件存非敏感信息
- Keychain 存储 Access Key / Secret Key
- 默认复制 URL，也可切到 Markdown

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

## 环境要求

- macOS 14+
- Xcode 26.x 或兼容版本
- Swift 6 toolchain
- 一个可写入的 Cloudflare R2 bucket
- 一个已经绑定到该 bucket 的公开访问自定义域名

## Cloudflare R2 前置准备

在 Cloudflare 侧先准备：

1. 创建 R2 bucket
2. 给 bucket 绑定公开访问自定义域名
3. 创建一组 R2 S3 API Access Key
4. 记录以下信息

- `Account ID`
- `Bucket`
- `Public Base URL`
- `Access Key ID`
- `Secret Access Key`

本项目走 R2 的 S3 兼容接口，上传端点等价于：

```text
https://<ACCOUNT_ID>.r2.cloudflarestorage.com
```

## 运行与构建

### 运行测试

```bash
swift test
```

### 打开 Xcode

```bash
open cf-r2-uploader.xcodeproj
```

然后运行 `cf-r2-uploader` scheme。

### 命令行直接运行

```bash
swift run cfr2uploader /absolute/path/to/file
```

### 构建 CLI 可执行文件

Typora 更适合直接调用编译后的二进制，而不是每次通过 `swift run` 启动。

```bash
swift build -c release
```

构建完成后，可执行文件默认位于：

```text
.build/release/cfr2uploader
```

## 配置说明

### 配置文件路径

默认配置文件路径：

```text
~/Library/Application Support/CFR2Uploader/config.json
```

### 配置文件格式

```json
{
  "defaultProfile": "default",
  "profiles": {
    "default": {
      "accountID": "your-account-id",
      "bucket": "files",
      "cacheControl": "public, max-age=31536000, immutable",
      "defaultOutput": "url",
      "keyPrefix": "uploads",
      "publicBaseURL": "https://files.example.com"
    }
  },
  "version": 1
}
```

字段说明：

- `accountID`：Cloudflare Account ID
- `bucket`：R2 bucket 名称
- `publicBaseURL`：文件公开访问域名，例如 `https://files.example.com`
- `keyPrefix`：对象 key 前缀，默认 `uploads`
- `defaultOutput`：默认输出格式，支持 `url` 和 `markdown`
- `cacheControl`：上传时写入对象的 `Cache-Control`

### Keychain 凭据

敏感信息不写入 JSON。以下字段保存在 Keychain：

- `Access Key ID`
- `Secret Access Key`

Keychain service 名称：

```text
kisechan.CFR2Uploader.credentials
```

首次读取或当前调试签名发生变化时，macOS 可能弹出钥匙串授权提示，这是正常行为。

## Settings 界面

首次启动后：

1. 点击 Menubar 图标
2. 打开“设置”
3. 填写 R2 配置和凭据
4. 点击“保存”

保存后：

- 配置写入 `~/Library/Application Support/CFR2Uploader/config.json`
- 凭据写入 macOS Keychain

设置页支持：

- `保存`
- `重新加载`
- `取消`：关闭当前设置窗口

## Menu Bar 使用

菜单栏界面支持：

- 选择本地文件上传
- 从剪贴板上传图片
- 查看最近上传历史
- 查看最近 API 日志
- 打开日志文件

上传成功或失败都会显示界面状态和系统通知。

说明：

- 文件选择上传支持任意文件
- 剪贴板上传当前仍只处理图片数据
- 单文件大小限制 50 MB

## CLI 使用

### 上传文件

```bash
swift run cfr2uploader /absolute/path/to/file
```

也支持一次上传多个文件：

```bash
swift run cfr2uploader /path/to/a.png /path/to/b.png
```

支持参数：

```bash
swift run cfr2uploader <file> \
  --config /path/to/config.json \
  --profile default \
  --format url \
  --copy
```

参数说明：

- `<file>`：本地文件路径，也可以连续传多个
- `--config`：指定配置文件路径
- `--profile`：指定 profile 名称
- `--format`：输出格式，支持 `url` 和 `markdown`
- `--copy`：成功后把结果复制到剪贴板

说明：

- 传入多个文件时，CLI 会逐个上传
- 标准输出会按一行一个结果返回，这样可以直接兼容 Typora 的自定义上传器

## Typora 接入

根据 Typora 官方文档的 “Custom” 方式，Typora 会把待上传图片路径自动追加到你填写的命令后面，并从命令标准输出的最后 N 行读取图片 URL。这个项目现在可以直接兼容这种调用方式。

### 1. 先准备好 CLI

推荐先构建 release 版本：

```bash
swift build -c release
```

CLI 路径通常是：

```text
./.build/release/cfr2uploader
```

### 2. 确保配置已可用

Typora 调用 CLI 前，需要本项目已经能独立完成上传。你可以任选一种方式准备配置：

- 先启动 Menu Bar App，在设置页保存 R2 配置和凭据
- 或手工准备 `~/Library/Application Support/CFR2Uploader/config.json`，并确保 Keychain 中已有对应凭据

建议先在终端验证一次：

```bash
./.build/release/cfr2uploader /absolute/path/to/test.png
```

### 3. 在 Typora 中填写上传命令

打开 Typora：

1. 进入“偏好设置” -> “图像”
2. “插入图片时...” 选择“上传图片”
3. “上传服务”选择“自定义命令”
4. 在“命令”中填写 CLI 命令

推荐填写：

```bash
"./.build/release/cfr2uploader" --format url
```

如果你要显式指定 profile：

```bash
"./.build/release/cfr2uploader" --profile default --format url
```

如果你把配置文件放在默认路径之外：

```bash
"./.build/release/cfr2uploader" --config "/absolute/path/to/config.json" --profile default --format url
```

注意：

- 不要在命令末尾自己填写图片路径，Typora 会自动追加
- 建议使用 `--format url`，这样 Typora 会拿到纯图片地址，再自行写回 Markdown
- 如果可执行文件路径里含空格，务必像上面这样加引号

### 4. 验证与使用

- 点击 Typora 的“验证图片上传选项”
- 验证通过后，粘贴或插入本地图片即可触发上传
- Typora 会执行类似下面的命令

```bash
"./.build/release/cfr2uploader" --format url "/path/to/image-1.png" "/path/to/image-2.png"
```

CLI 会输出：

```text
https://files.example.com/uploads/2026/05/23/image-1-abcd1234.png
https://files.example.com/uploads/2026/05/23/image-2-efgh5678.png
```

Typora 会读取这些 URL，并替换文档中的本地图片地址。

### 读取 API 日志

```bash
swift run cfr2uploader logs --limit 20
```

如果还没有产生上传日志，会返回日志文件路径。

## 日志与历史

### 上传历史

历史记录用于 Menu Bar 最近上传展示。

### API 日志

R2 API 日志路径：

```text
~/Library/Application Support/CFR2Uploader/logs/r2-api.log
```

日志会记录：

- 请求方法
- 请求 URL
- 对象 key
- Content-Type
- 文件大小
- 脱敏后的请求头
- 状态码
- 响应头
- 响应体预览
- 请求耗时
- 成功或失败结果

`Authorization` 会被脱敏，不会明文写入日志。

## 对象命名规则

默认 object key 规则：

```text
<keyPrefix>/yyyy/MM/dd/<sanitized-name>-<shortid>.<ext>
```

示例：

```text
uploads/2026/04/16/report-abc12345.pdf
```

特点：

- 有日期目录，便于管理
- 保留原始扩展名
- 文件名会做安全化处理
- 附带短随机后缀，降低冲突概率

## 上传限制

- 支持任意文件类型
- 单文件大小上限 50 MB
- 默认 `Content-Type` 会按文件类型推断
- 无法识别时回退为 `application/octet-stream`

## 常用命令

```bash
swift test
swift run cfr2uploader /path/to/file
swift run cfr2uploader logs --limit 10
xcodebuild -project cf-r2-uploader.xcodeproj -scheme cf-r2-uploader CODE_SIGNING_ALLOWED=NO build
```

## 实现说明

- 上传通过 `URLSession + AWS SigV4` 直连 R2 S3 兼容接口
- 当前不做 multipart upload
- 当前不做后台队列和断点续传
- 当前不做多后端抽象

## 后续建议

- 增加拖拽上传
- 增加批量上传
- 增加文件命名策略选项
- 增加日志筛选和导出
- 增加剪贴板监听上传
