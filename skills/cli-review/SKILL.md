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

**通用原则：审查时必须查看所有可用的反馈来源 — file-level review comments、issue-level comments、PR 页面上的全部信息。遗漏任何来源都可能导致问题未被发现。**

## 审查清单

### 1. API 响应格式 — response shape mismatch

**这是最常见的 bug 类型。** REST API 返回的往往是 `{key: [...]}` 包裹结构，不是 flat list。

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
- [ ] `doc list` → `data.files`、`doc tree` → `data.files`、`search` → `data.blocks`、`create_notebook` → `data.notebook`

### 2. 参数语义 — argument semantics

```python
# ❌ 错误：参数名与语义不匹配
client.insert_block("markdown", data, previous_id=parent_id)
# 用户传的是 parent_id，但传到了 previous_id 参数

# ✅ 正确：参数名对得上语义
client.insert_block("markdown", data, parent_id=parent_id)
```

**检查点：**
- [ ] CLI 命令的参数名（`--parent`、`--previous`、`--id`）是否 **准确地传递** 给了对应的 API 参数
- [ ] 不要假设参数名相同就语义相同，确认 API 文档对每个参数的定义
- [ ] REPL 模式和 CLI 命令模式的参数传递要一致

### 3. 输入解析 — input tokenization

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
- [ ] 支持引号包裹的内容（markdown、带空格的标题）

### 4. 参数验证 — input validation

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
- [ ] 可选参数全部为空时是否会静默传递无效值到 API
- [ ] API 支持的所有参数是否都暴露为 CLI option（例如 `insertBlock` 有 parent/previous/next 三个锚点，CLI 不能只提供前两个）
- [ ] REPL 路径和 CLI 路径的验证逻辑要一致，REPL 不能绕开验证
- [ ] 使用 `click.UsageError` 给出清晰的用户错误消息

### 5. 异常处理 — exception handling

```python
# ❌ 错误：只捕获一种异常
try:
    resp = session.post(url, timeout=30)
except requests.ConnectionError as e:
    raise ClientError(...) from e
# timeout、SSL error 等会裸抛

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
- [ ] 网络请求是否捕获了 **timeout、SSL、连接中断** 等异常
- [ ] 异常消息是否 **对用户友好**（"无法连接到服务，请确认服务是否运行" 而非 Python traceback）
- [ ] 使用 `from e` 保留原始异常链

### 6. 状态新鲜度 — state freshness

```python
# ❌ 错误：使用从未更新的缓存状态
info = {"connected": state.connected}  # state.connected 初始化后从未被设为 True

# ✅ 正确：实时检测
connected = client.ping()
info = {"connected": connected}
```

**检查点：**
- [ ] `status` 类命令是否使用 **实时检测** 而非缓存状态
- [ ] session state 中是否有字段被初始化但 **从未被更新**

### 7. API 分页/截断限制 — pagination & response caps

有些 API 有内置的返回数量限制（如 SiYuan 的 `Conf.FileTree.MaxListCount`），超过时静默截断结果，需要传特定参数来获取完整数据。

```python
# ❌ 错误：没有传解除限制的参数
def get_tags():
    return _post("/api/tag/getTag", {})
# 标签超过 MaxListCount 时静默缺失

# ✅ 正确：传解除限制的参数
def get_tags():
    return _post("/api/tag/getTag", {"ignoreMaxListHint": True})
```

**检查点：**
- [ ] 每个列表类 API 是否有 **分页参数**（limit/offset）或 **截断标志**（ignoreMaxListHint 等）
- [ ] API 文档中是否有 `MaxListCount`、`pageSize`、`maxEntries` 等限制说明
- [ ] 默认值是否满足真实使用场景，不满足时是否需要传额外参数

### 8. Click Context 对象访问 — context object access

`@click.pass_context` 传递的是 `click.Context`，自定义 context 类必须通过 `ctx.obj` 访问。

```python
# ❌ 错误：直接访问 ctx 上的属性
@click.pass_context
def repl(ctx):
    ctx.session.flush()  # ctx 是 click.Context，没有 .session 属性

# ✅ 正确：通过 ctx.obj 访问
@click.pass_context
def repl(ctx):
    ctx.obj.session.flush()  # ctx.obj 是 SiYuanContext，有 .session 属性
```

**检查点：**
- [ ] `@click.pass_context` 的函数内，所有自定义属性访问是否通过 `ctx.obj.xxx`
- [ ] `@click.pass_obj` 直接传递 `ctx.obj`，不需要 `ctx.` 前缀

### 9. 配置加载回退 — config fallback chain

配置加载应有完整的回退链：显式路径 → 环境变量 → 默认值。配置文件损坏时不能直接跳到默认值，应回退到环境变量。

```python
# ❌ 错误：配置文件损坏时跳过环境变量
if config_file.exists():
    try:
        data = json.loads(...)
    except JSONDecodeError:
        data = {}  # 直接给空 dict，跳过了环境变量
    return Config(host=data.get("host", "127.0.0.1"), ...)

# ✅ 正确：损坏时回退到环境变量
if config_file.exists():
    try:
        data = json.loads(...)
    except JSONDecodeError:
        data = None  # 标记为损坏

    if data is not None:
        return Config(host=data.get("host", ...), ...)

# 环境变量回退
return Config(
    host=os.environ.get("SIYUAN_HOST", "127.0.0.1"),
    ...
)
```

**检查点：**
- [ ] 配置文件加载的逻辑是否 **有三层回退**：config file → env vars → defaults
- [ ] 配置文件存在但 **内容损坏时** 是否正确地 fall through 到 env var 层，而不是直接跳到默认值

### 10. API 错误转换为用户友好消息 — global API error handling

API 客户端抛出的异常（如 `SiYuanClientError`）应统一转换为 `Error: <message>` 而非裸 Python traceback。通过自定义 Click Group 实现全局捕获。

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
- [ ] REPL 路径是否也捕获了同样的异常（通常通过 `try/except` 在 REPL loop 中）
- [ ] 两种模式（one-shot 和 REPL）的异常处理行为一致

### 11. 部分状态更新 — partial state update

更新一个字段时，关联字段可能未被同步更新，导致 UI/状态显示 stale 数据。

```python
# ❌ 错误：只更新了 ID，关联的 name 还是旧的
session.update(current_notebook_id=new_id)
session.flush()
# status 命令显示的还是旧的 notebook name

# ✅ 正确：同时更新关联字段
for nb in client.list_notebooks():
    if nb["id"] == new_id:
        name = nb["name"]
        break
session.update(current_notebook_id=new_id, current_notebook_name=name)
session.flush()
```

**检查点：**
- [ ] 每次 `session.update()` 或状态变更时，所有 **关联的展示字段** 是否同步更新
- [ ] 是否存在一个字段变了但另一个依赖它的字段还是旧值的情况
- [ ] `status` 命令、REPL 提示符等依赖 session state 的展示是否可能显示过期数据

### 12. 递归/层级数据输出 — hierarchical data display

API 返回层级结构（如标签的 `children`、文档树）时，text 输出只遍历了顶层，遗漏嵌套内容。

```python
# ❌ 错误：只输出顶层
for t in tags:
    print(f"{t['name']} ({t['count']})")
# 忽略了 t.get("children", []) 中的嵌套标签

# ✅ 正确：递归遍历
def print_tags(tags, indent=0):
    for t in tags:
        print(f"{'  '*indent}{t['name']} ({t['count']})")
        if t.get("children"):
            print_tags(t["children"], indent + 1)
```

**检查点：**
- [ ] 数据有 `children`、`subItems`、`entries` 等嵌套字段时，text 输出是否递归遍历
- [ ] `--json` 模式和 text 模式的输出完整性是否一致（json 包含嵌套数据，text 不能只显示顶层）
- [ ] 缩进格式是否清晰（每层 2 空格，不超出终端宽度）

### 13. 开发模式 CLI 回退路径 — dev fallback module resolution

测试框架中通过 `python -m <module>` 回退到开发模式时，必须指向带 `__main__.py` 的可执行包，不能指向不可直接运行的模块。

```python
# ❌ 错误：指向不可执行的模块
name = "cli-anything-siyuan"
module = name.replace("cli-anything-", "cli_anything.") + "." + name.split("-")[-1] + "_cli"
# → "cli_anything.siyuan.siyuan_cli" (没有 if __name__ == "__main__")

# ✅ 正确：指向带 __main__.py 的包
module = name.replace("cli-anything-", "cli_anything.")
# → "cli_anything.siyuan" (有 __main__.py 调用 cli())
```

**检查点：**
- [ ] `_resolve_cli` 的 `python -m` 回退路径是否指向 **包路径** 而非模块路径
- [ ] 目标包是否有 `__main__.py` 且正确调用入口函数
- [ ] 所有 CLI 工具的测试文件（`test_full_e2e.py`）是否都有相同的回退逻辑

### 14. 技能/文档示例与 CLI 签名一致 — doc example alignment

SKILL.md 或 README 中的示例必须和 CLI 实际定义的参数签名保持一致，否则 AI agent 会生成错误命令。

```markdown
# ❌ 错误：示例用了位置参数，但 CLI 需要 --md 标志
cli-anything-siyuan doc create nb1 /projects/new "## Title\n\nContent"

# ✅ 正确：示例和 CLI 实际签名一致
cli-anything-siyuan doc create nb1 /projects/new --md "## Title\n\nContent"
```

**检查点：**
- [ ] 所有技能/文档示例是否与 `@click.option`/`@click.argument` 的实际定义一致
- [ ] 示例中的参数是 `--flag` 形式还是位置参数，检查 CLI 实际接受哪种
- [ ] AI agent 可能按示例模式生成命令，错误的示例会导致错误的行为

### 15. 序列化格式匹配 — serialization format compatibility

当 CLI 操作文件格式（.prg、.drawio、.md 等）时，序列化格式必须和消费方（GUI 应用、其他工具）完全一致，否则文件无法被正确打开。

```python
# ❌ 错误：使用内部简化的序列化格式，与 GUI 不兼容
write_prg(path, {"stage": [
    {"_": "TextNode", "uuid": "...", "location": [x, y], "type": "core:text_node"}
]})
# GUI 期望 collisionBox + associationList + Color/Vector 对象格式

# ✅ 正确：在写文件时转换为消费方期望的格式
def write_prg(path, data):
    stage = _convert_to_gui_format(data["stage"])  # 转换格式
    # ... 写入转换后的数据
```

**检查点：**
- [ ] CLI 操作的文件格式是否与对应的 **桌面/Web 应用** 完全兼容
- [ ] 差异不能被忽略——即使 msgpack 包结构一样，内部字段 schema 不同也会导致打不开
- [ ] 如存在格式差异，应在读写时做 **双向转换**（内部格式 ↔ 序列化格式）
- [ ] 添加 **thumbnail.png** 等 GUI 期望的辅助文件
- [ ] 添加对应的 e2e 测试（CLI 生成文件 → GUI 打开验证）

### 16. 后端 CLI 工具可用性 — backend CLI dependency

CLI 工具依赖外部 CLI 后端（如 draw.io desktop 的 `draw.io --export`）时，需确保能找到后端并给出清晰提示。

```python
# ❌ 错误：假设后端在 PATH 中
subprocess.run(["draw.io", "--export", ...])

# ✅ 正确：查找 + 清晰错误
def find_drawio():
    candidates = ["draw.io", "drawio", "draw.io.exe"]
    for name in candidates:
        path = shutil.which(name)
        if path:
            return path
    raise RuntimeError("draw.io 未安装。安装：winget install JGraph.Draw")
```

**检查点：**
- [ ] 后端 CLI 是否在 PATH 中，或通过 `shutil.which()` 查找
- [ ] 后端未安装时是否给出 **安装指引**（平台对应命令）
- [ ] 有 **fallback 逻辑**（后端不可用时保存文件 + 提示手动处理）

### 17. 导出参数完整性 — export option completeness

CLI 包装后端导出功能时，后端支持的参数（scale、border、crop、transparent 等）应全部暴露。

```python
# ❌ 错误：后端支持 border 但 CLI 未暴露
def render(output_path, fmt="png", scale=None, crop=False):
    # backend: draw.io --export in.drawio -o out.png --border 20
    # CLI 没有 --border 选项，用户无法控制边框宽度
    pass

# ✅ 正确：暴露所有后端支持的参数
def render(output_path, fmt="png", scale=None, crop=False, border=0):
    pass
```

**检查点：**
- [ ] CLI 的 export 命令是否暴露了后端的 **全部有用参数**
- [ ] 检查 `drawio_backend.py` 等实际后端代码，确认参数有没有遗漏
- [ ] 参数默认值是否合理（如 scale=3 超清、border=20 边框）

### 18. 测试覆盖 — test coverage

**检查点：**
- [ ] 每个 CLI 命令至少有一个单元测试（mock client）
- [ ] mock 测试要覆盖 **list 和 dict 两种 API 返回格式**
- [ ] 空结果、错误情况也要有测试
- [ ] `--json` 输出模式要单独测试
- [ ] 参数验证边界（缺少必填参数、空值传递）要有测试