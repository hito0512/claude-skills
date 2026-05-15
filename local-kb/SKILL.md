---
name: local-kb
description: 本地文件知识库管理工具（kb CLI）。管理 Excel/PDF/Word/MD/TXT 等文档，搭建个人知识库。支持全文搜索、MCP 服务、多库联邦。Excel 输出表格格式。索引文件存放于 E:\workspace\project\.lore，源文件可分布在任意路径。
---

# Local Knowledge Base (kb)

基于 `kb` CLI（原 lore，已加入系统 PATH）的本地文档知识库管理。

**索引目录**：`E:\workspace\project`（`.lore\` 子目录存放索引数据）
**源文件位置**：可分布在系统任意路径，在配置中指定即可

## 触发条件

用户提到以下关键词时触发：
- 本地文档 / 知识库 / kb / lore
- xls / xlsx / excel / 表格
- 搜索某个文件 / 文档内容
- 搭建个人数据库 / 知识库
- 查看 / 分析本地文件

## 回答规范（强制要求）

1. **忠于原文**：输出内容必须严格依据原始文档，禁止随意更改、添加、编造数据
2. **未找到即止**：如果文档中没有相关内容，直接回答"库中未找到相关信息"，**禁止猜测、联想、编造**，禁止建议"你是不是指XXX"
3. **引用路径**：所有回答末尾必须标注原始文件路径，格式为：

```
文件：E:\SVN\文档\目标检测评估.xls
```

方便用户验证、直接操作或打开原文件。

## 平台命令格式

### Windows

```powershell
cd E:\workspace\project; kb <子命令>
```

> 若在 Git Bash 中执行，注意 `cd` 后使用 `&&` 而非 `;`，路径用正斜杠：
> ```bash
> cd /e/workspace/project && kb docs
> ```

### Linux

```bash
cd /path/to/project && kb <子命令>
```

（kb 在 Linux 上需自行编译安装）

## 核心工作流（必须严格按此执行）

当用户要求"查看/搜索/分析"某个文档或内容时：

### 步骤 1：列出文档

```powershell
cd E:\workspace\project; kb docs
```

先用 `kb docs` 列出所有已索引文档，查看文件名和格式。
**不要跳过这步**，否则你不知道文件名叫什么。

### 步骤 2：读取文档

```powershell
cd E:\workspace\project; kb read "目标检测评估.xls"
```

根据步骤 1 得到的文件名，用 `kb read` 读取全文。
**不要用 `kb search` 搜中文**，Tantivy 对中文分词支持差，会返回空结果。
`kb read` 直接按名读取，最可靠。

### 步骤 3：格式化输出（强制要求）

- **Excel 文件必须整理为 Markdown 表格输出**，保留行列结构，禁止用文字描述表格内容
- 所有回答末尾必须标注**原始文件路径**：

```
文件：E:\SVN\文档\目标检测评估.xls
```

---

## 安装与配置

### 初始化知识库

```powershell
cd E:\workspace\project; kb init
```

### 配置文档来源

编辑 `E:\workspace\project\.lore\lore.yaml`，使用**绝对路径**指向源文件目录：

```yaml
name: "project"

base_dir: ..

sources:
  - path: E:\SVN\文档
    glob: "**/*.xls"
  - path: E:\SVN\文档
    glob: "**/*.xlsx"
  - path: E:\SVN\文档
    glob: "**/*.pdf"
  - path: E:\SVN\文档
    glob: "**/*.docx"
  - path: E:\SVN\文档
    glob: "**/*.md"
  - path: E:\SVN\文档
    glob: "**/*.txt"
```

> 源文件可以分布在任意位置，只需在 `sources` 中配置对应路径即可。
> 索引数据统一存放在 `E:\workspace\project\.lore\store`。

### 构建索引

```powershell
cd E:\workspace\project; kb ingest
```

后续新增或修改文档后，重复 `kb ingest` 增量更新。

## 核心命令

| 命令 | 用途 | 示例 |
|------|------|------|
| `kb init` | 初始化知识库 | `kb init` |
| `kb ingest` | 构建/更新索引 | `kb ingest` |
| `kb search <query>` | 全文搜索（仅限英文/数字） | `kb search "yolov5s"` |
| `kb docs` | 列出所有文档（含路径） | `kb docs --format xlsx` |
| `kb read <file>` | 读取文档全文（中文首选） | `kb read "目标检测评估.xls"` |
| `kb topics` | 查看主题分类 | `kb topics` |
| `kb info` | 知识库统计 | `kb info` |
| `kb serve` | 启动 MCP 服务器 | `kb serve` |
| `kb watch` | 监听文件变化 | `kb watch` |

## Excel 输出格式（强制要求）

Excel 文件（xls/xlsx）**必须**以 Markdown 表格形式输出，不得用纯文字描述表格数据。

```powershell
cd E:\workspace\project; kb read "销售数据.xls"
```

输出示例（保留行列结构，表头加粗对齐）：

| 产品 | Q1 | Q2 | Q3 |
|------|:--:|:--:|:--:|
| A | 100 | 120 | 150 |
| B | 200 | 180 | 210 |

## 搜索注意事项

### 中文搜索的限制

`kb` 底层使用 Tantivy 全文搜索引擎，其对中文的分词支持较差。
因此：

| 场景 | 正确做法 | 错误做法 |
|------|---------|---------|
| 想找"检测模型评估"的中文内容 | `kb docs` 列出文件 → `kb read "目标检测评估.xls"` | `kb search "检测模型评估"` → 返回空 |
| 想找具体指标（yolov5s, 0.984） | `kb search "yolov5s"` | — |
| 想只看 Excel 文件 | `kb docs --format xlsx` | — |
| 想看某个路径下的文件 | `kb docs --source "SVN"` | — |

### 文件路径筛选

```powershell
# 按路径关键词筛选
kb docs --source "SVN"

# 按文件格式
kb docs --format xlsx
kb docs --format docx
```

## 多知识库联邦

`kb` 支持同时加载多个知识库配置：

```powershell
kb -c E:\workspace\project\.lore\lore.yaml -c D:\other\.lore\lore.yaml search "关键词"
```

## 已知限制

- 中文搜索依赖 Tantivy 分词器，对中文支持有限，必须用 `kb read` 直接读取
- 超大文档（>100MB）解析较慢
