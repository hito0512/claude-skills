---
name: siyuan
description: SiYuan（思源笔记，简称 sy）CLI 工具，通过 cli-anything-siyuan 操作笔记本、文档、内容块，支持 SQL 查询和全文搜索，生成任务卡片 JSON 供 DynamicTodo 导入。在用户提到 siyuan、思源、笔记、sy、任务卡片、制作卡片、查询笔记内容、操作知识库时触发。
---

# SiYuan CLI (cli-anything-siyuan)

基于 [cli-anything](https://github.com/HKUDS/CLI-Anything) 方法论构建的思源笔记 CLI 工具。
通过思源的 HTTP API（`http://127.0.0.1:6806`）连接运行中的内核，无需 GUI 即可操作知识库。

**CLI 位置**：`E:\workspace\github\siyuan\agent-harness`
**数据目录**：`~/SiYuan/data`（默认为用户目录下的 SiYuan/data）

## 核心原则

### ⚠️ 绝对禁止自动删除任何文件

- 任何删除/移除操作（`remove`、`delete`）**必须**经用户明确确认后才可执行
- 禁止在未告知用户的情况下自动执行破坏性操作
- 删除操作需添加 `--dangerous` 标记以显式确认

### 📝 输出必须用文档标题，禁止裸 ID

- 任何输出中涉及文档/笔记本的地方，必须解析出标题（name/title）显示
- 禁止直接输出 `20260329150429-iezfnoy` 这类 ID，用户看不懂
- 显示格式：`【标题】（ID）` 或直接 `环境配置 / 【0-Agent】 / 【插件】 / 【MCP】` 这种人类可读路径

## 触发条件

- siyuan / 思源 / 笔记 / sy / 知识库
- 查询笔记内容 / 搜索笔记
- 操作笔记本 / 文档 / 块
- 导出 Markdown
- 查看待办 / 任务列表
- **生成任务卡片 / 导出任务卡片 / 制作卡片** — 将文档中的清单/笔记转为 DynamicTodo 可导入的 JSON

## 安装

已通过 `pip install -e` 安装，CLI 命令 `cli-anything-siyuan` 可用。

如需重新安装：
```bash
cd E:\workspace\github\siyuan\agent-harness
pip install -e ".[repl]"
```

## 配置

连接配置（`~/.siyuan-cli.json`）：
```json
{
  "host": "127.0.0.1",
  "port": 6806,
  "token": "从思源设置-关于中获取"
}
```

或环境变量：`SIYUAN_HOST`、`SIYUAN_PORT`、`SIYUAN_TOKEN`

## 解析 ID 为文档标题的方法

### 方法 1：通过 SQL 查询（思源需运行中）
```bash
cli-anything-siyuan sql "SELECT id, content FROM blocks WHERE id='<文档ID>'"
# 或在 blocks 表中查标题
cli-anything-siyuan sql "SELECT * FROM blocks WHERE id LIKE '%前缀%'"
```

### 方法 2：直接读取 .sy 文件（推荐，最快）
```bash
# 查找文件位置
find ~/SiYuan/data -name "*<ID>*.sy"

# 读取 title 字段
# .sy 文件是 JSON 格式，Properties.title 就是文档标题
```

### 方法 3：查笔记本名称
```bash
# 笔记本目录下的 .siyuan/conf.json 中有 name 字段
cat "~/SiYuan/data\<notebook-id>\.siyuan\conf.json"
```

## 命令参考

### 笔记本管理
| 命令 | 说明 |
|------|------|
| `cli-anything-siyuan notebook list` | 列出所有笔记本（显示名称） |
| `cli-anything-siyuan notebook create <name>` | 创建笔记本 |
| `cli-anything-siyuan notebook rename <id> <name>` | 重命名 |
| `cli-anything-siyuan notebook remove <id>` | 删除（需 `--dangerous` 确认） |
| `cli-anything-siyuan notebook open <id>` | 打开笔记本 |

### 文档管理
| 命令 | 说明 |
|------|------|
| `cli-anything-siyuan doc create <notebook-id> <path> [--md content]` | 创建文档 |
| `cli-anything-siyuan doc list <notebook-id> [path]` | 列出文档（显示标题） |
| `cli-anything-siyuan doc tree <notebook-id>` | 文档树（显示标题） |
| `cli-anything-siyuan doc get <doc-id>` | 获取文档路径和标题 |
| `cli-anything-siyuan doc rename <id> <title>` | 重命名（需 `--dangerous` 确认） |
| `cli-anything-siyuan doc remove <id>` | 删除（需 `--dangerous` 确认） |

### 内容块操作
| 命令 | 说明 |
|------|------|
| `cli-anything-siyuan block get <block-id>` | 查看块源码 |
| `cli-anything-siyuan block children <block-id>` | 查看子块 |
| `cli-anything-siyuan block insert <data>` | 插入块 |
| `cli-anything-siyuan block update <id> <data>` | 更新块 |
| `cli-anything-siyuan block delete <id>` | 删除块（需 `--dangerous` 确认） |

### 搜索与查询
| 命令 | 说明 |
|------|------|
| `cli-anything-siyuan search <query>` | 全文搜索（结果显示标题 + 内容片段） |
| `cli-anything-siyuan sql <stmt>` | SQL 查询 |
| `cli-anything-siyuan export md <doc-id>` | 导出 Markdown |
| `cli-anything-siyuan tag list` | 标签列表 |

### 系统
| 命令 | 说明 |
|------|------|
| `cli-anything-siyuan version` | 查看版本 |
| `cli-anything-siyuan status` | 连接状态 |

### JSON 输出
所有命令加 `--json` 输出机器可读格式。

### REPL 模式
```bash
cli-anything-siyuan
# 进入交互模式：siyuan ❯
```

## 思源数据目录结构

```
~/SiYuan/data\
├── <notebook-id>/
│   ├── .siyuan/conf.json   # {"name": "笔记本名称"}
│   ├── <doc-id>.sy         # {"Properties":{"title":"文档标题"}}
│   └── <doc-id>/           # 子文档目录
│       └── <sub-doc>.sy
└── assets/
```

`.sy` 文件 JSON 格式关键字段：
- `Properties.title` — 文档标题
- `Properties.type` — 类型（`doc` 文档）
- `Children` — 块树

## 任务卡片管理

将文档中的清单/笔记转为 DynamicTodo 可导入的 JSON 文件。

### 流程

1. 用 `export md` 导出文档 markdown
2. 解析清单项，按 `references/dynamic-todo-task-card.md` 的 JSON 格式生成
3. 保存为 JSON 文件，告知用户路径
4. **用户自己在 DynamicTodo 挂件中 ⚙️ → 导入数据**

### 与挂件的关系

- 插件只管理代码，**不包含任何用户数据**
- 任务数据通过 JSON 文件导出，用户手动导入到指定挂件
- 禁止直接通过 API 写入块属性

参考 `references/dynamic-todo-task-card.md` 查看完整的 JSON 字段说明。

## 常见操作示例

```bash
# 1. 查看所有笔记本（显示名称，不是 ID）
cli-anything-siyuan notebook list

# 2. 查看某个笔记本的文档树
cli-anything-siyuan doc tree <notebook-id>

# 3. 搜索笔记内容
cli-anything-siyuan search "关键词"

# 4. 用 SQL 搜索
cli-anything-siyuan sql "SELECT * FROM blocks WHERE content LIKE '%待办%'"

# 5. 导出文档（显示标题路径）
cli-anything-siyuan export md <doc-id>

# 6. JSON 格式输出
cli-anything-siyuan --json search "meeting"
```

## 注意事项

- 思源必须在运行状态，CLI 通过 HTTP API 连接
- API Token 在思源「设置 - 关于」中查看
- 默认端口 6806
- **禁止自动执行删除操作** — 必须用户确认 + `--dangerous` 标记
- **所有输出必须显示标题/名称**，禁止裸 ID
- 发布的模式下禁止 SQL 查询接口
- 通过 `find ~/SiYuan/data -name "*<ID>*.sy"` 可通过 ID 反查文件位置
- 通过读取 `.sy` 文件的 `Properties.title` 可获取文档标题
