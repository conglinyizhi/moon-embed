# moon-embed

将静态文件嵌入 MoonBit 二进制。

## 一分钟上手

```bash
# 生成嵌入文件（默认输出到 src/embedded.mbt）
moon run gen -- ./frontend/dist

# 或指定输出路径
moon run gen -- ./frontend/dist -o my-embed.mbt

# 在代码里使用
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
| 内存 | `decode_all()` | 小文件、性能敏感 |
| 磁盘 | `extract_all()` + `read_file()` | 大文件、省内存 |

```moonbit
// 内存模式
let files = @embed.decode_all(EMBED_PATHS, EMBED_DATA)

// 磁盘模式
let dir = @embed.extract_all(EMBED_PATHS, EMBED_DATA)
let html = @embed.read_file(dir, "/index.html")
```

---

## 这是什么

把前端构建产物直接编译进 MoonBit 二进制。类似 Go 的 `//go:embed`。

### 为什么需要它

- **单二进制部署**：一个文件包含全部页面，不需要 Nginx
- **零运行时依赖**：解码后直接提供 `Bytes`
- **跨平台生成**：生成器本身是 MoonBit 程序，Windows / macOS / Linux 都能跑

---

## 实现原理

```moonbit
构建时:
  moon run gen -- ./dist
  ↓
  src/embedded.mbt 包含两个 pub 数组
  (路径列表 + base64 编码的文件内容)

运行时:
  decode_all  → Map[String, Bytes]  全部解码到内存
  extract_all → /tmp/xxx/           解压到临时目录
  content_type → "text/html"        猜测 MIME
```

## API

| 函数 | 说明 |
|------|------|
| `decode_all(paths, data)` | base64 解码全部文件，返回 `Map[String, Bytes]` |
| `extract_all(paths, data)` | 解压到临时目录，返回目录路径 |
| `read_file(dir, path)` | 从解压目录读取文件 |
| `content_type(path)` | 根据扩展名猜测 Content-Type |
| `ensure_embedded(paths)` | 检查嵌入数据是否为空 |
