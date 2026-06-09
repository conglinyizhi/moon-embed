# moon-embed

## 一分钟上手

```bash
# 1. 加依赖
moon add moonbitlang/x
moon add moonbitlang/async
moon add your-name/moon-embed

# 2. 生成嵌入文件（每次前端构建后执行）
bash scripts/gen.sh ./frontend/dist > src/embedded.mbt

# 3. 在代码里使用
```
```moonbit
let files = @embed.decode_all(EMBED_PATHS, EMBED_DATA)

// HTTP 处理
match files.get(request.path) {
  Some(bytes) => {
    sconn.send_response(200, "OK",
      extra_headers={ "Content-Type": @embed.content_type(request.path) })
    sconn.write(bytes)
    sconn.end_response()
  }
  None => { /* 404 */ }
}
```

### 两种模式

| 模式 | 函数 | 适用场景 |
|------|------|---------|
| 内存 | `decode_all()` | 小文件、性能敏感、简单 |
| 磁盘 | `extract_all()` + `read_file()` | 大文件、省内存、留痕 |

```moonbit
// 内存模式：启动时全部解码到 Map
let files = @embed.decode_all(EMBED_PATHS, EMBED_DATA)

// 磁盘模式：解压到 /tmp/moon-embed-xxx/
let dir = @embed.extract_all(EMBED_PATHS, EMBED_DATA)
let html = @embed.read_file(dir, "/index.html")
```

---

## 这是什么

把前端构建产物（或任意静态文件）**直接编译进 MoonBit 二进制**的库。类似 Go 的 `//go:embed`。（注意：MoonBit 本身没有 embed 特性，这是通过构建时生成源码实现的。）

### 为什么需要它

- **单二进制部署**：一个 `.exe` 文件包含全部页面，不需要 Nginx、不需要 `pnpm dev`
- **零运行时依赖**：解码后直接提供 `Bytes`，HTTP 服务自己决定怎么返回
- **无供应商锁定**：生成的数据是纯 `.mbt` 源码，库只负责解码和工具函数

---

## 实现原理

```
构建时：
  scripts/gen.sh          embedded.mbt
  ./frontend/dist/  ─────────────────→  pub let EMBED_PATHS : Array[String]
                                         pub let EMBED_DATA : Array[String]  ← base64

运行时：
  @embed.decode_all(paths, data)    Map[String, Bytes]
  @embed.extract_all(paths, data)   /tmp/moon-embed-xxx/
  @embed.content_type(path)         "text/html; charset=utf-8"
```

- 文本文件以 `#|` 多行字符串嵌入 → 直接作为 MoonBit 源码编译
- 二进制文件以 `Bytes` 十六进制字面量嵌入
- 文件名用 `.mbt` 后缀，MoonBit 自动编译

## API

| 函数 | 说明 |
|------|------|
| `decode_all(paths, data)` | base64 解码全部文件，返回 `Map[String, Bytes]` |
| `extract_all(paths, data)` | 解压到临时目录，返回目录路径 |
| `read_file(dir, path)` | 从解压目录中读取文件 |
| `content_type(path)` | 根据扩展名猜测 Content-Type |
| `ensure_embedded(paths)` | 检查是否为空，为空则 panic |
