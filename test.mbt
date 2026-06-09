// moon-embed 测试

let test_paths : Array[String] = ["/index.html", "/app.js"]
let test_data : Array[String] = [
  "SGVsbG8gTW9vbkJpdA==",
  "Y29uc29sZS5sb2coJ2hpJyk=",
]

test "decode_all 数量正确" {
  let files = decode_all(test_paths, test_data)
  @debug.assert_eq(files.keys().length(), 2)
}

test "decode_all HTML 内容" {
  let files = decode_all(test_paths, test_data)
  match files.get("/index.html") {
    Some(bytes) => @debug.assert_eq(bytes, b"Hello MoonBit")
    None => fail("missing /index.html")
  }
}

test "decode_all JS 内容" {
  let files = decode_all(test_paths, test_data)
  match files.get("/app.js") {
    Some(bytes) => @debug.assert_eq(bytes, b"console.log('hi')")
    None => fail("missing /app.js")
  }
}

test "decode_all 不存在的路径" {
  let files = decode_all(test_paths, test_data)
  match files.get("/nonexistent") {
    Some(_) => fail("should be None")
    None => ()
  }
}

test "decode_all 空数组" {
  let files = decode_all([], [])
  @debug.assert_eq(files.keys().length(), 0)
}

test "content_type 常见类型" {
  @debug.assert_eq(content_type("/index.html"), "text/html; charset=utf-8")
  @debug.assert_eq(content_type("/style.css"), "text/css; charset=utf-8")
  @debug.assert_eq(content_type("/app.js"), "application/javascript; charset=utf-8")
  @debug.assert_eq(content_type("/icon.svg"), "image/svg+xml")
  @debug.assert_eq(content_type("/logo.png"), "image/png")
  @debug.assert_eq(content_type("/favicon.ico"), "image/x-icon")
  @debug.assert_eq(content_type("/readme.txt"), "text/plain; charset=utf-8")
  @debug.assert_eq(content_type("/module.wasm"), "application/wasm")
  @debug.assert_eq(content_type("/data.json"), "application/json")
}

test "content_type 未知扩展名" {
  @debug.assert_eq(content_type("/file.xyz"), "application/octet-stream")
  @debug.assert_eq(content_type("/noext"), "application/octet-stream")
  @debug.assert_eq(content_type(""), "application/octet-stream")
}

test "content_type 大小写敏感" {
  @debug.assert_eq(content_type("/index.HTML"), "application/octet-stream")
}

test "ensure_embedded 非空" {
  match ensure_embedded(test_paths) {
    Ok(_) => ()
    Err(msg) => fail(msg)
  }
}

test "ensure_embedded 空数组" {
  match ensure_embedded([]) {
    Ok(_) => fail("should be Err")
    Err(msg) => @debug.assert_eq(msg.length() > 0, true)
  }
}

test "dirname 基础路径" {
  @debug.assert_eq(dirname("/foo/bar/baz.txt"), "/foo/bar")
  @debug.assert_eq(dirname("/foo.txt"), "")
  @debug.assert_eq(dirname("relative/path/file.js"), "relative/path")
}

test "dirname 根目录文件" {
  @debug.assert_eq(dirname("/index.html"), "")
  @debug.assert_eq(dirname("/a/b/c/d.txt"), "/a/b/c")
}
