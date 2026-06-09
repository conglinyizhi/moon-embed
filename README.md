# moon-embed

将静态文件嵌入 MoonBit 二进制。

## 一分钟上手

```bash
# [推荐]生成嵌入文件（默认输出到 src/embedded.mbt）
moon run gen -- ./frontend/dist

# 或指定输出路径
moon run gen -- ./frontend/dist -o my-embed.mbt
```

### 在代码里使用

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

| 模式 | 函数                            | 适用场景         |
| ---- | ------------------------------- | ---------------- |
| 内存 | `decode_all()`                  | 小文件、性能敏感 |
| 磁盘 | `extract_all()` + `read_file()` | 大文件、省内存   |

```moonbit
// 内存模式
let files = @embed.decode_all(EMBED_PATHS, EMBED_DATA)

// 磁盘模式
let dir = @embed.extract_all(EMBED_PATHS, EMBED_DATA)
let html = @embed.read_file(dir, "/index.html")
```

---

## 这是什么

把前端构建产物（或任意静态文件）直接编译进 MoonBit 二进制。类似 Go 的 `//go:embed`。

### 常见误解

> "那编译产物不还是两个文件吗？一个 .exe 还得带着一个 embedded.mbt？"

**不是。** `embedded.mbt` 在 `moon build` 阶段就被编译进二进制了，不是运行时加载的。

```
make build
  → pnpm build
  → moon run gen -- ./frontend/dist   ← 生成 src/embedded.mbt
  → moon build                        ← 编译进 .exe
  → 一个 .exe 文件                       ← 这就是全部
```

这个 `.exe` 拿到任何机器直接跑，不需要带着 `embedded.mbt`。

### 和纯 Bytes 字面量方案的区别

社区已有的 [tonyfettes/moon-embed](https://mooncakes.io/docs/tonyfettes/moon-embed@0.0.1) 走的是另一条路：每个文件生成一个单独的 `let` / `const` 绑定，文本用 `#|` 多行字符串，二进制用 `Bytes` 十六进制字面量。

|            | 纯 Bytes 字面量               | 本方案（base64 + 运行时解码）                 |
| ---------- | ----------------------------- | --------------------------------------------- |
| 源码可读性 | 小文件好，大文件几千行 `0xFF` | 统一 base64 字符串                            |
| 编译速度   | 大文件 Bytes 字面量拖慢编译器 | base64 字符串编译快                           |
| 运行时性能 | 零解码                        | 启动时一次 decode                             |
| 目录支持   | 手动，每个文件跑一次          | 一次扫描整个目录                              |
| 运行时库   | 无                            | `decode_all` / `content_type` / `extract_all` |

大文件（JS/CSS）用 Bytes 字面量会导致生成的 `.mbt` 文件膨胀、编译变慢。本方案用 base64 更适合**前端静态文件批量嵌入**的场景。

---

## 用法

### 作为库

```bash
moon add moonbitlang/x
moon add moonbitlang/async
moon add your-name/moon-embed
```

```moonbit
let files = @embed.decode_all(EMBED_PATHS, EMBED_DATA)
let html  = files["/index.html"]
```

### 生成嵌入文件

```bash
moon run gen -- ./frontend/dist
```

输出默认到 `src/embedded.mbt`，可自定义：

```bash
moon run gen -- ./frontend/dist -o path/to/embedded.mbt
```

## API

| 函数                       | 说明                                           |
| -------------------------- | ---------------------------------------------- |
| `decode_all(paths, data)`  | base64 解码全部文件，返回 `Map[String, Bytes]` |
| `extract_all(paths, data)` | 解压到临时目录，返回目录路径                   |
| `read_file(dir, path)`     | 从解压目录读取文件                             |
| `content_type(path)`       | 根据扩展名猜测 Content-Type                    |
| `ensure_embedded(paths)`   | 检查嵌入数据是否为空                           |

## 发布到 mooncakes

```bash
moon login        # 登录 mooncakes 账号
moon publish      # 发布（包名为 your-name/moon-embed）
```

包名以你的 mooncakes 用户名开头，不会和任何人冲突。
