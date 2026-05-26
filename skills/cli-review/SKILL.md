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
- [ ] `doc list` → `data.files`、`doc tree` → `data.tree`、`search` → `data.blocks`、`create_notebook` → `data.notebook`

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

### 7. 测试覆盖 — test coverage

**检查点：**
- [ ] 每个 CLI 命令至少有一个单元测试（mock client）
- [ ] mock 测试要覆盖 **list 和 dict 两种 API 返回格式**
- [ ] 空结果、错误情况也要有测试
- [ ] `--json` 输出模式要单独测试
