---
name: github-kb
description: 本地 GitHub 仓库知识库，同时支持 HuggingFace、ModelScope 搜索查询。在用户提到 github/repo/仓库/模型/pretrained/权重，或搜索 huggingface/modelscope 上的模型时触发。优先在本地目录查找已有仓库，支持：gh 搜索 GitHub issues/PRs/repos、HuggingFace API 搜索模型、ModelScope API 搜索模型，curl 回退。
---

# GitHub KB + Model Hub Search

维护 `E:\workspace\github` 目录下的仓库清单，同时提供 HuggingFace 和 ModelScope 的模型搜索能力。

CLAUDE.md 文件见 `@E:\workspace\github\CLAUDE.md`

## 触发条件

用户提到以下关键词时触发：
- github / GitHub / repo / repository / 仓库
- 本地已有的具体项目名
- "下载一个 repo"、"看看某个仓库"
- huggingface / hf / 模型 / pretrained / 权重
- modelscope / 魔搭

## 核心流程

### 1. 查找本地仓库

用户提到某个仓库时，先检查本地 `E:\workspace\github\` 中是否已存在：

```powershell
$repoDir = "E:\workspace\github"
Get-ChildItem $repoDir -Directory | Select-Object Name
```

如果本地存在，直接在该目录下工作，分析代码回答问题。

### 2. 下载新仓库

当用户说"下载一个 repo"时：

```powershell
cd E:\workspace\github
git clone <repo-url>
```

下载完后运行 `scripts\update_claude.ps1` 更新 CLAUDE.md。

### 3. 更新 CLAUDE.md

每次添加/删除仓库后，运行 `scripts\update_claude.ps1` 重新扫描目录并更新摘要。

### 4. 搜索 HuggingFace

搜索 HuggingFace 上的模型：

```powershell
# 通过 API 搜索模型
Invoke-RestMethod "https://huggingface.co/api/models?search=<query>&sort=downloads&direction=-1&limit=10"

# 通过 API 搜索数据集
Invoke-RestMethod "https://huggingface.co/api/datasets?search=<query>&sort=downloads&direction=-1&limit=10"

# 获取模型详细信息
Invoke-RestMethod "https://huggingface.co/api/models/<org>/<model-name>"

# 列出模型文件
Invoke-RestMethod "https://huggingface.co/api/models/<org>/<model-name>" | % { $_.siblings.rfilename }

# 通过 Web 页面查看更多信息
curl.exe -s "https://huggingface.co/<org>/<model-name>/raw/main/README.md"
```

处理 HuggingFace 结果时，关注：
- `modelId` - 完整模型名称（org/name）
- `pipeline_tag` - 任务类型（text-generation, any-to-any, etc.）
- `downloads` - 下载量
- `likes` - 收藏数
- `config.model_type` - 架构类型
- `tags` - 标签信息（custom_code 表示需要 trust_remote_code）

### 5. 搜索 ModelScope

搜索 ModelScope（魔搭）上的模型：

```powershell
# 搜索模型
Invoke-RestMethod "https://www.modelscope.cn/api/v1/dso/list?name=<query>&PageSize=10"

# 或通过 modelscope SDK
pip install modelscope
from modelscope.hub.sdk import Hub
```

### 6. 搜索 GitHub（当本地没有时）

优先用 `gh` 命令搜索 GitHub：

```powershell
# 搜索仓库
gh search repos "<query>"

# 搜索 issue / PR
gh search issues "<query>" --repo <owner>/<repo>
gh search prs "<query>" --repo <owner>/<repo>

# 查看 issue / PR 详情
gh issue view <number> -R <owner>/<repo>
gh pr view <number> -R <owner>/<repo>

# 查看仓库信息
gh repo view <owner>/<repo>
```

如果 `gh` 命令不可用或未登录，用 `curl` 代替：

```powershell
# 搜索仓库 (GitHub API)
curl.exe -s "https://api.github.com/search/repositories?q=<query>"

# 搜索 issue
curl.exe -s "https://api.github.com/search/issues?q=repo:<owner>/<repo>+<query>"

# 查看仓库详情
curl.exe -s "https://api.github.com/repos/<owner>/<repo>"
```

### 7. 仓库/模型不存在时的处理

当用户提到的仓库本地不存在时：
1. 本地查找 → 如果本地有，直接分析
2. GitHub 搜索 → `gh search repos` 或 `gh api`
3. HuggingFace 搜索 → HF API 查询模型信息
4. ModelScope 搜索 → 魔搭 API 查询
5. 告知用户结果，询问是否要下载

## 资源

### scripts/update_claude.ps1

扫描 `E:\workspace\github` 目录，为每个仓库生成一句话摘要，写入 CLAUDE.md。

## 注意事项

- 尽量使用 `gh` 命令，没有则用 `Invoke-RestMethod` (PowerShell) 或 `curl.exe`
- 注意 API 速率限制
- HuggingFace API 未认证时限制较宽松
- ModelScope API 无需认证，但可能因网络问题受限
