---
name: cli-review
description: CLI/API 客户端专项代码审查技能。审查 click CLI 工具、API 客户端、REPL 模式代码的常见 bug 模式。
triggers:
  - cli review
  - cli-review
  - cli审查
  - click
  - api review
  - repl
  - cli bug
---

# CLI 代码审查：CLI/API 客户端专项

审查 cli-anything 风格的 Python CLI 工具（click + requests + REPL）时，按以下清单逐项检查。

## Codex/自动化 review comments 审计方法

GitHub Codex bot 会在每次 push 后持续扫描产生新评论。审计时必须：

1. **一次性拉取所有 review comments**（`/pulls/{n}/comments`），不要按日期筛选
2. **逐条对照当前代码**，确认每一条的状态（已修复/仍需修复/误报）
3. **同时检查 issue comments**（`/issues/{n}/comments`）和 review summary（`/pulls/{n}/reviews`）

**反模式：** 只查 `created_at -like "today"` → 漏掉昨天下午/前几天未处理的评论
**反模式：** 只看 review summary → 遗漏 file-level inline comments

## 审查清单

### 1. API 响应格式 — response shape mismatch

**最常见的 bug 类型。** REST API 返回的往往是 `{key: [...]}` 包裹结构，不是 flat list。

```python
# ❌ 错误：假设 API 返回 flat list
results = client.search_blocks(query)
for r in results:  # 如果 results 是 {"blocks": [...]}，遍历的是字符串 key
    r.get("id")

# ✅ 正确：兼容两种格式
data = client.search_blocks(query)
items = data.get("blocks", []) if isinstance(data, dict) else data
for r in items:
    r.get("id")
```

**检查点：**
- [ ] 每个调用 API 的地方，检查 **实际 API 响应格式**（看文档或抓包），不要信类型注解
- [ ] `_post` 返回的是 `body.get("data")`，而 `data` 可能嵌套（`{notebook: {...}}`、`{files: [...]}`、`{tree: [...]}`、`{blocks: [...]}`）
- [ ] 遍历结果前必须做 **归一化处理**：`items = data.get("key", []) if isinstance(data, dict) else data`
- [ ] `doc list` → `data.files`、`doc tree` → `data.files` 或 `data.tree`、`search` → `data.blocks`、`create_notebook` → `data.notebook`

### 2. API 请求 payload key — request key mismatch

客户端发 JSON payload 的 key 名必须严格匹配服务端 `arg["key"]` 的 key。必须对照服务端源码验证。

```python
# ❌ 错误：payload key 与服务端不一致
client.search_tag(tag)      → {"tag": tag}      # 服务端读 arg["k"]
client.search_docs(keyword) → {"keyword": kw}    # 服务端读 arg["k"]
client.find_replace(kw, rp) → {"keyword", "replacement", "notebookID"}  # 服务端读 k/r/ids

# ✅ 正确：对照服务端源码确认 key 名
client.search_tag(tag)      → {"k": tag}         # search.go:187  arg["k"]
client.search_docs(keyword) → {"k": keyword}     # filetree.go:1043 arg["k"]
client.find_replace(kw, rp) → {"k": kw, "r": rp, "ids": ids}  # search.go:128-130
```

**检查点：**
- [ ] **每个 API 方法的 payload key** 必须对照 **服务端源码**（`arg["xxx"].(type)` 语句）验证
- [ ] 不要信 API 文档或类型注解，直接读 Go 源码中的 `arg["key"]` 读取语句
- [ ] 注意 key 大小写：SiYuan 用驼峰（`dataType`, `parentID`, `maxListCount`）而非蛇形
- [ ] `findReplace` 用 `k/r/ids` 而非 `keyword/replacement/notebookID`
- [ ] `searchTag` 用 `k` 而非 `tag`；返回 `{"tags": [...]}` 而非 tag 对象数组
- [ ] `listDocsByPath` 的 `maxListCount` 是驼峰，不是 `max_count`

### 3. 参数语义 — argument semantics

```python
# ❌ 错误：参数名与语义不匹配
client.insert_block("markdown", data, previous_id=parent_id)
# 用户传的是 parent_id，但传到了 previous_id 参数

# ✅ 正确：参数名对得上语义
client.insert_block("markdown", data, parent_id=parent_id)
```

**检查点：**
- [ ] CLI 命令的参数名（`--parent`、`--previous`、`--id`）是否 **准确地传递** 给了对应的 API 参数
- [ ] REPL 模式和 CLI 命令模式的参数传递要一致

### 4. 输入解析 — input tokenization

```python
# ❌ 错误：str.split() 不支持引号包裹的多词参数
parts = cmd.strip().split()
# "block insert parent 'hello world'" → ["block", "insert", "parent", "'hello", "world'"]

# ✅ 正确：用 shlex 解析引号
import shlex
parts = shlex.split(cmd.strip())
# "block insert parent 'hello world'" → ["block", "insert", "parent", "hello world"]
```

**检查点：**
- [ ] REPL/CLI 的输入解析是否使用 `shlex.split()` 而非 `str.split()`

### 5. stdin 管道 — 阻塞与 CJK 编码

```python
# ❌ 错误 1：无管道时永久阻塞
raw = sys.stdin.buffer.read()  # tty 下永远等 EOF

# ❌ 错误 2：Python stdin 在中文 Windows 上走 GBK 编码，CJK 字符损坏
data = sys.stdin.read()  # PowerShell 管道 → GBK → 非 ASCII 损坏

# ❌ 错误 3：不传 --flag 时仍然读 stdin
if not data or data == "-":
    data = _read_stdin()  # --flag 没传也读，创建空文档看起来像卡死

# ✅ 正确：tty 检测 + 原始字节 + 明确的标志位
def _read_stdin():
    if sys.stdin.isatty():
        raise click.UsageError("stdin pipe expected")
    raw = sys.stdin.buffer.read()
    return raw.decode('utf-8-sig')

if data == "-":   # 只有显式 "-" 才读 stdin
    data = _read_stdin()
```

**检查点：**
- [ ] `sys.stdin.buffer.read()` 前是否检查 `sys.stdin.isatty()` 避免阻塞
- [ ] CJK 环境是否用 `sys.stdin.buffer.read()` + `decode('utf-8-sig')`
- [ ] stdin 只在显式 `-` 参数时触发，不传参不应该读管道
- [ ] REPL 和 one-shot CLI 的 stdin 行为是否一致（REPL 无管道上下文，help 文本注明 `use '-' for stdin`）

### 6. 参数验证 — input validation

```python
# ❌ 错误：允许调用 API 时缺少必要参数
def block_insert(data, previous="", parent=""):
    result = client.insert_block(data, parent_id=parent, previous_id=previous)
    # 当 parent="" 且 previous="" 时 API 会失败

# ✅ 正确：前置验证
def block_insert(data, previous="", parent=""):
    if not parent and not previous:
        raise click.UsageError("Either --parent or --previous is required")
    result = client.insert_block(data, parent_id=parent, previous_id=previous)
```

**检查点：**
- [ ] 每个 CLI 命令调用 API 前，检查 **所有必要参数是否已提供**
- [ ] API 支持的所有锚点参数是否都暴露为 CLI option（`insertBlock` 有 parent/previous/next 三个）
- [ ] REPL 路径和 CLI 路径的验证逻辑要一致
- [ ] 使用 `click.UsageError` 给出清晰的用户错误消息

### 7. 异常处理 — exception handling

```python
# ❌ 错误：只捕获一种异常
try:
    resp = session.post(url, timeout=30)
except requests.ConnectionError as e:
    raise ClientError(...) from e

# ✅ 正确：捕获完整异常谱系
try:
    resp = session.post(url, timeout=30)
except requests.ConnectionError as e:
    raise ClientError(...) from e
except requests.Timeout as e:
    raise ClientError(...) from e
except requests.RequestException as e:
    raise ClientError(...) from e
```

**检查点：**
- [ ] 网络请求是否捕获了 **ConnectionError、Timeout、RequestException**
- [ ] 异常消息是否对用户友好，使用 `from e` 保留原始异常链

### 8. HTTP 代理 — 本地服务不走代理

```python
# ❌ 错误：requests 默认走系统代理，localhost 请求被 Clash/V2Ray 拦截 → 404
session = requests.Session()

# ✅ 正确：本地服务禁用代理
session = requests.Session()
session.trust_env = False
```

**检查点：**
- [ ] 所有纯本地服务（`127.0.0.1`）的 requests Session 是否设了 `trust_env = False`

### 9. 配置文件 — BOM 与 env 兜底

```python
# ❌ 错误 1：UTF-8 BOM 导致 JSON 解析失败
data = json.loads(config_file.read_text(encoding="utf-8"))
# SiYuan Windows 上写的 .json 带 BOM (EF BB BF)，json.loads 解析失败 → None

# ❌ 错误 2：配置损坏后不 fallback 环境变量
except (json.JSONDecodeError, OSError):
    data = None
if data is not None:
    return Config(data["host"], ...)  # 直接返回，忽略 env
# → 坏配置无法通过环境变量恢复

# ❌ 错误 3：配置存在时忽略环境变量覆盖
if config_file.is_file():
    return Config(data["host"], data["port"], data["token"])  # 不读 env

# ✅ 正确：BOM 安全 + 三层回退 + env 优先
data = json.loads(config_file.read_text(encoding="utf-8-sig"))
return Config(
    host=os.environ.get("SIYUAN_HOST", data.get("host", "127.0.0.1")),
    port=int(os.environ.get("SIYUAN_PORT", data.get("port", 6806))),
    token=os.environ.get("SIYUAN_TOKEN", data.get("token", "")),
)
```

**检查点：**
- [ ] JSON 配置文件用 `utf-8-sig` 而非 `utf-8`（Windows BOM 兼容）
- [ ] 配置损坏时 fallback 到环境变量而非直接跳到默认值
- [ ] 环境变量始终优先于配置文件值

### 10. API 错误转换为用户友好消息 — global API error handling

```python
# ✅ 正确：自定义 Click Group 统一捕获
class _CatchErrors(click.Group):
    def invoke(self, ctx):
        try:
            return super().invoke(ctx)
        except ClientError as e:
            click.echo(f"Error: {e}", err=True)
            sys.exit(1)

@click.group(cls=_CatchErrors, invoke_without_command=True)
def cli():
    ...
```

**检查点：**
- [ ] one-shot CLI 命令中 API 异常 → `Error: <message>` 而非 traceback
- [ ] REPL 路径是否也捕获了同样的异常

### 11. 状态新鲜度 — state freshness

```python
# ❌ 错误：使用从未更新的缓存状态
info = {"connected": state.connected}  # state.connected 初始化后从未被设为 True

# ✅ 正确：实时检测
connected = client.ping()
info = {"connected": connected}
```

**检查点：**
- [ ] `status` 命令使用实时检测而非缓存状态
- [ ] session state 中是否有字段被初始化但从未被更新

### 12. API 分页/截断限制 — pagination & response caps

有些 API 有内置的返回数量限制，超过时静默截断，需要传特定参数获取完整数据。

```python
# ❌ 错误：不传解除限制的参数
get_tags()    → {"ignoreMaxListHint": True} 缺失
list_docs()   → {"maxListCount": 0} 缺失

# ✅ 正确
client.get_tags()  → {"ignoreMaxListHint": True}
client.list_docs() → {"maxListCount": 0}
```

**检查点：**
- [ ] `getTag` 是否传了 `ignoreMaxListHint: true`
- [ ] `listDocsByPath` 是否传了 `maxListCount: 0`（0 = 无上限）
- [ ] 其他列表 API 是否有类似的分页/截断参数

### 13. 递归/层级数据输出 — hierarchical data display

API 返回层级结构（标签的 `children`、文档树节点的 `children`）时，text 输出只遍历了顶层。

```python
# ❌ 错误：只输出顶层
for t in items:
    print(f"{t['name']}")
# 忽略了 t.get("children", []) 中的嵌套内容

# ✅ 正确：递归展平（不修改原始数据）
def _walk_tree(items, depth=0):
    result = []
    for t in items:
        entry = {**t, "depth": depth}  # 复制，不修改原始数据
        result.append(entry)
        if t.get("children"):
            result.extend(_walk_tree(t["children"], depth + 1))
    return result

for t in _walk_tree(items):
    indent = "  " * t["depth"]
    print(f"{indent}{t['name']}")
```

**检查点：**
- [ ] 数据有 `children` 字段时（标签、文档树），text 输出是否递归遍历
- [ ] 递归时是否用 `{**item, "depth": d}` 复制，不修改原始数据
- [ ] `--json` 和 text 模式的输出完整性是否一致

### 14. 部分状态更新 — partial state update

更新一个字段时，关联字段可能未被同步更新。

```python
# ❌ 错误：只更新了 ID，关联的 name 还是旧的
session.update(current_notebook_id=new_id)
# status 命令显示的还是旧的 notebook name

# ✅ 正确：同时更新关联字段
name = next((nb["name"] for nb in client.list_notebooks() if nb["id"] == new_id), new_id)
session.update(current_notebook_id=new_id, current_notebook_name=name)
```

**检查点：**
- [ ] `notebook_open` 等命令是否同时更新了 ID 和 name
- [ ] session state 变更后是否调用了 `flush()`

### 15. Click Context 对象访问 — context object access

```python
# ❌ 错误：直接访问 ctx 上的属性
@click.pass_context
def repl(ctx):
    ctx.session.flush()  # ctx 是 click.Context，没有 .session

# ✅ 正确：通过 ctx.obj 访问
@click.pass_context
def repl(ctx):
    ctx.obj.session.flush()
```

**检查点：**
- [ ] `@click.pass_context` 函数内，自定义属性通过 `ctx.obj.xxx` 访问
- [ ] `@click.pass_obj` 直接传递 `ctx.obj`，不需要 `ctx.` 前缀

### 16. 模块级全局状态 — module-level mutable globals

```python
# ❌ 错误：模块级可变全局变量 + lazy init
_client = None
def get_client():
    global _client
    if _client is None:
        _client = SiYuanClient(load_config())
    return _client

# ✅ 正确：通过 Click context 管理生命周期
class SiYuanContext:
    def __init__(self, client, session, json_output=False):
        self.client = client
        self.session = session

@click.group(...)
@click.pass_context
def cli(ctx, ...):
    cfg = load_config()
    client = SiYuanClient(cfg)
    session = SessionManager()
    ctx.obj = SiYuanContext(client=client, session=session)
```

**检查点：**
- [ ] 是否有模块级 `_client`/`_config`/`_session` 等可变全局变量
- [ ] 生命周期是否通过 `click.Context.obj` 管理而非 `global` 关键字
- [ ] 测试中是否需要 patch 模块级变量（是 = 设计有问题）

### 17. 死代码 — unused code

**检查点：**
- [ ] 装饰器定义了但从未调用
- [ ] 函数/方法定义了但无引用者
- [ ] import 了但未使用

### 18. 技能/文档示例与 CLI 签名一致 — doc example alignment

```markdown
# ❌ 错误：示例用了位置参数，但 CLI 需要 --md 标志
cli-anything-siyuan doc create nb1 /projects/new "## Title"

# ✅ 正确：示例和 CLI 实际签名一致
cli-anything-siyuan doc create nb1 /projects/new --md "## Title"
```

**检查点：**
- [ ] 所有示例是否与 `@click.option`/`@click.argument` 的实际定义一致
- [ ] 新增 `--md` 等标志后，示例是否同步更新

### 19. 第三方改动混入 — unrelated diff

**检查点：**
- [ ] PR diff 中是否包含与功能无关的模块改动（如 drawio border 参数混入思源 PR）
- [ ] 应 revert 或拆为独立 PR

### 20. 开发模式 CLI 回退路径 — dev fallback module resolution

```python
# ❌ 错误：指向不可执行的模块
module = "cli_anything.siyuan.siyuan_cli"   # 没有 __main__

# ✅ 正确：指向带 __main__.py 的包
module = "cli_anything.siyuan"   # 有 __main__.py 调用 cli()
```

### 21. 序列化格式匹配 — serialization format compatibility

CLI 操作文件格式时，序列化格式必须和消费方完全一致。

### 22. 后端 CLI 工具可用性 — backend CLI dependency

后端 CLI 未安装时给出安装指引 + fallback 逻辑。

### 23. 导出参数完整性 — export option completeness

后端支持的参数应全部暴露为 CLI option。

### 24. 测试覆盖 — test coverage

- [ ] 每个 CLI 命令至少有一个单元测试（mock client）
- [ ] mock 测试覆盖 list 和 dict 两种 API 返回格式
- [ ] 空结果、错误情况有测试
- [ ] `--json` 输出模式单独测试
- [ ] 树形结构（`children` 递归）有测试覆盖
- [ ] 参数验证边界有测试
