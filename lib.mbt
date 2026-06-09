// moon-embed: 将前端静态文件嵌入 MoonBit 二进制
//
// 用法：
//   1. scripts/gen.sh ./dist > embedded.mbt  （构建时）
//   2. 在 main.mbt 中引用 embedded.mbt 的数据
//   3. 调用 @embed.decode_all() 或 @embed.extract_all() 加载
//
// 两种模式：
//   - decode_all: 内存模式，所有文件解码到 Map[String, Bytes]
//   - extract_all: 磁盘模式，文件解压到 /tmp/，返回目录路径

/// 将 base64 编码的嵌入数据解码为内存 Map
///
/// ```
/// let files = @embed.decode_all(MY_PATHS, MY_DATA)
/// let html = files["/index.html"]
/// ```
pub fn decode_all(paths : Array[String], data : Array[String]) -> Map[String, Bytes] {
  let m : Map[String, Bytes] = {}
  for i = 0; i < paths.length(); i = i + 1 {
    match (try { @base64.decode(data[i]) } catch { _ => continue }) {
      bytes => m[paths[i]] = bytes
    }
  }
  m
}

/// 将嵌入文件解压到临时目录，返回目录路径
///
/// ```
/// let dir = @embed.extract_all(MY_PATHS, MY_DATA)
/// let html = @embed.read_file(dir, "/index.html")
/// ```
pub async fn extract_all(paths : Array[String], data : Array[String]) -> String {
  let dir = @fs.tmpdir(prefix="moon-embed-")
  for i = 0; i < paths.length(); i = i + 1 {
    let bytes = match (try { @base64.decode(data[i]) } catch { _ => continue }) {
      b => b
    }
    let full_path = dir + paths[i]
    // 确保父目录存在
    let parent = dirname(full_path)
    if !@fs.exists(parent) {
      @fs.mkdir(parent, recursive=true)
    }
    @fs.write_file(full_path, bytes, create_mode=@fs.CreateOrTruncate)
  }
  dir
}

/// 从解压目录中读取文件
pub async fn read_file(dir : String, path : String) -> Bytes? {
  let full = dir + path
  if !@fs.exists(full) { return None }
  let raw = try { @fs.read_file(full) } catch { _ => return None }
  Some(raw.binary())
}

/// 根据文件路径猜测 Content-Type
pub fn content_type(path : String) -> String {
  let len = path.length()
  if len >= 5 {
    let end = path[len - 5:]
    if end == ".html" { return "text/html; charset=utf-8" }
    if end == ".json" { return "application/json" }
  }
  if len >= 4 {
    let end = path[len - 4:]
    if end == ".css"  { return "text/css; charset=utf-8" }
    if end == ".svg"  { return "image/svg+xml" }
    if end == ".png"  { return "image/png" }
    if end == ".ico"  { return "image/x-icon" }
    if end == ".txt"  { return "text/plain; charset=utf-8" }
    if end == ".wasm" { return "application/wasm" }
  }
  if len >= 3 {
    let end = path[len - 3:]
    if end == ".js"   { return "application/javascript; charset=utf-8" }
    if end == ".gz"   { return "application/gzip" }
  }
  if len >= 2 {
    let end = path[len - 2:]
    if end == ".ts" || end == ".mjs" { return "application/javascript; charset=utf-8" }
  }
  "application/octet-stream"
}

/// 获取路径的父目录
fn dirname(p : String) -> String {
  match p.rev_find("/") {
    Some(i) => p[:i].to_owned()
    None => "."
  }
}
