# claude-skills

Claude Code 技能合集仓库。

## 技能列表

| 技能 | 目录 | 说明 |
|------|------|------|
| gitkb | `skills/gitkb/` | GitHub 仓库知识库 + HuggingFace/ModelScope 搜索 |
| dockb | `skills/dockb/` | 本地文件知识库管理工具 |
| siyuan | `skills/siyuan/` | 思源笔记 CLI 工具操作知识库 |

## 安装

### Claude Code 插件市场（推荐）

```bash
# 注册仓库为插件市场
/plugin marketplace add hito0512/claude-skills

# 安装 kb-skills 插件（包含 gitkb、dockb、siyuan 三个技能）
/plugin install kb-skills@claude-skills
```

### 手动安装

直接复制到 Claude Code 技能目录：

```bash
cp -r skills/* ~/.claude/skills/
```
