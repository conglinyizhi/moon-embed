# moon-embed

将静态文件嵌入 MoonBit 二进制。

## 用法

### 1. 添加依赖

```bash
moon add moonbitlang/x
moon add moonbitlang/async
```

### 2. 生成嵌入文件

```bash
bash scripts/gen.sh ./frontend/dist > src/embedded.mbt
```

生成的文件包含两个顶层数组：

```moonbit
pub let EMBED_PATHS : Array[String] = ["/index.html", "/assets/app.js", ...]
pub let EMBED_DATA : Array[String]  = ["base64...", "base64...", ...]
```

### 3. 在代码中加载

**内存模式**（简单，适合小文件）：

```moonbit
let files = @embed.decode_all(EMBED_PATHS, EMBED_DATA)
let html  = files["/index.html"]
```

**磁盘模式**（解压到 `/tmp/`，适合大文件）：

```moonbit
let dir  = @embed.extract_all(EMBED_PATHS, EMBED_DATA)
let html = @embed.read_file(dir, "/index.html")
```

### 4. HTTP 集成示例

```moonbit
let files = @embed.decode_all(EMBED_PATHS, EMBED_DATA)

// 在 HTTP handler 中
match files.get(path) {
  Some(bytes) => {
    sconn.send_response(200, "OK",
      extra_headers={ "Content-Type": @embed.content_type(path) })
    sconn.write(bytes)
    sconn.end_response()
  }
  None => { /* 404 */ }
}
```

## API

| 函数 | 说明 |
|------|------|
| `decode_all(paths, data)` | base64 解码全部文件，返回 `Map[String, Bytes]` |
| `extract_all(paths, data)` | 解压到临时目录，返回目录路径 |
| `read_file(dir, path)` | 从解压目录中读取文件 |
| `content_type(path)` | 根据扩展名猜测 Content-Type |
